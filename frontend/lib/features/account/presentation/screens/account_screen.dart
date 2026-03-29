import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/screens/splash_screen.dart';
import 'about_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController(text: 'Engineer User');
  final _emailController = TextEditingController(text: 'engineer@crackeriq.com');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
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
                      BoxShadow(color: AppColors.primaryBlue.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: _isEditing ? _editingView() : _profileView(),
                ),

                const SizedBox(height: 14),

                // About — taps to separate page
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
                        BoxShadow(color: AppColors.primaryBlue.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
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
                Center(
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
    return Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.cyan, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_nameController.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_emailController.text,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis),
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
              decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.person_rounded, color: AppColors.cyan, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Editing profile', style: TextStyle(fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Full Name', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        _editField(_nameController, 'Full Name'),
        const SizedBox(height: 14),
        const Text('Email Address', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        _editField(_emailController, 'Email Address'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                label: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                onPressed: () => setState(() => _isEditing = false),
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

  Widget _editField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.darkBase),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cyan, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkBase)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const SplashScreen(),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
              (route) => false,
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}