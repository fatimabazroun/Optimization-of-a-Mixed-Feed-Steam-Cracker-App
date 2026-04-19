import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../features/auth/presentation/screens/splash_screen.dart';
import 'about_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isEditing = false;
  bool _loading = true;
  bool _saving = false;

  String _name = '';
  String _email = '';

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final attrs = await AuthService.fetchUserAttributes();
      if (!mounted) return;
      setState(() {
        _name = attrs['name'] ?? '';
        _email = attrs['email'] ?? '';
        _nameController.text = _name;
        _emailController.text = _email;
        _loading = false;
      });
    } on AuthException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name cannot be empty'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await AuthService.updateName(newName);
      if (!mounted) return;
      setState(() {
        _name = newName;
        _isEditing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AppColors.cyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                const Text('Account', style: AppTextStyles.heading1),
                const SizedBox(height: 6),
                const Text('Manage your profile', style: AppTextStyles.body),
                const SizedBox(height: 24),

                // Profile card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
                          ),
                        )
                      : _isEditing
                          ? _editingView()
                          : _profileView(),
                ),

                const SizedBox(height: 14),

                // About
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const AboutScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBase)),
                              Text('Learn about this application', style: AppTextStyles.body),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Sign out
                const Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                const SizedBox(height: 6),
                const Text("You'll need to sign back in to access your account", style: AppTextStyles.body),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                    label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Center(
                  child: Text('Mixed Feed Cracker v2.1.4',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileView() {
    // Generate initials avatar from name
    final initials = _name.trim().isNotEmpty
        ? _name.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
        : '?';

    return Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.tealGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name.isNotEmpty ? _name : 'No name set',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkBase),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isEditing = true),
          child: const Icon(Icons.edit_outlined, color: AppColors.cyan, size: 20),
        ),
      ],
    );
  }

  Widget _editingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.cyan, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Editing profile', style: TextStyle(fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),

        const Text('Full Name', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        _editField(_nameController, 'Full Name', readOnly: false),

        const SizedBox(height: 14),
        const Text('Email Address', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        _editField(_emailController, 'Email Address', readOnly: true),
        const SizedBox(height: 4),
        const Text(
          'Email cannot be changed here',
          style: TextStyle(fontSize: 11, color: AppColors.textLight),
        ),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveChanges,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                label: Text(
                  _saving ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () {
                  _nameController.text = _name;
                  setState(() => _isEditing = false);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.inputBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _editField(TextEditingController controller, String hint, {required bool readOnly}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? AppColors.textLight : AppColors.darkBase,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? AppColors.inputBg.withOpacity(0.5) : AppColors.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: readOnly ? AppColors.inputBorder : AppColors.cyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: readOnly
            ? const Icon(Icons.lock_outline, size: 16, color: AppColors.textLight)
            : null,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.red.withValues(alpha: 0.20), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Log Out',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBase)),
                const SizedBox(height: 8),
                const Text('Are you sure you want to log out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.5)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMedium)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final nav = Navigator.of(context);
                          nav.pop();
                          await AuthService.signOut();
                          if (!mounted) return;
                          nav.pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const SplashScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('Log Out',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
