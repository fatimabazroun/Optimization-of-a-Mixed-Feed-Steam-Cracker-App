import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '—';
  String _build = '—';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
          _build = '#${info.buildNumber}';
        });
      }
    });
  }

  static const _team = [
    _TeamMember('Fatima Bazroun',     'Software Engineering · App Developer', 'SWE'),
    _TeamMember('Joud Almatrood',     'Chemical Engineering',                  'CHE'),
    _TeamMember('Zainab Alamer',      'Chemical Engineering',                  'CHE'),
    _TeamMember('Safana Aljughaiman', 'Industrial & Systems Engineering',      'ISE'),
    _TeamMember('Munirah Alobaid',    'Industrial & Systems Engineering',      'ISE'),
    _TeamMember('Dona Alsaud',        'Petroleum Engineering',                 'PETE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios, size: 16, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text('Back', style: TextStyle(fontSize: 14, color: context.textSecondary)),
                        ],
                      ),
                    ),
                    Image.asset('assets/images/Transparent_logo.png', width: 40, height: 40, fit: BoxFit.contain),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.2)),
                      Text('Mixed Feed Cracker Application', style: TextStyle(fontSize: 14, color: context.textSecondary)),
                      const SizedBox(height: 20),

                      // Banner with bubbles
                      const _BubbleBanner(),

                      const SizedBox(height: 20),

                      _glassCard(context,
                        tint: const Color(0xFF3D4F9F),
                        icon: Icons.science_outlined,
                        title: 'What is the Mixed Feed Cracker?',
                        body: 'The Mixed Feed Cracker application simulates thermal cracking processes used in '
                            'petrochemical production to evaluate temperature, pressure, flow rates, and emission '
                            'performance under controlled parameters. This advanced simulation tool enables engineers '
                            'to optimize process conditions before implementing changes in real-world operations.',
                      ),

                      const SizedBox(height: 14),

                      _glassCard(context,
                        tint: const Color(0xFF3DBFC5),
                        icon: Icons.trending_up_rounded,
                        title: 'What This Application Does',
                        listItems: const [
                          'Simulate mixed feed streams',
                          'Calculates thermal and pressure outputs',
                          'Evaluates CO₂ emission scope',
                          'Provides performance KPIs',
                          'Generates visualization plots',
                        ],
                      ),

                      const SizedBox(height: 14),

                      _glassCard(context,
                        tint: const Color(0xFF5B6BAE),
                        icon: Icons.people_outline,
                        title: 'Who It Is For',
                        body: 'This application is designed for process engineers, industrial researchers, plant '
                            'operators, and energy analysts who need to evaluate and optimize thermal cracking '
                            'processes. It provides critical insights for decision-making in petrochemical '
                            'production environments.',
                      ),

                      const SizedBox(height: 14),

                      // University card
                      _rawGlassCard(
                        context,
                        tint: const Color(0xFF3D4F9F),
                        child: Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D4F9F),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('King Fahd University of Petroleum\nand Minerals',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary, height: 1.35)),
                                  const SizedBox(height: 4),
                                  Text('KFUPM · Dhahran, Saudi Arabia',
                                      style: TextStyle(fontSize: 12, color: context.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text('Development Team',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
                      const SizedBox(height: 12),

                      ..._team.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _rawGlassCard(
                          context,
                          tint: _avatarColor(m.dept),
                          child: Row(
                            children: [
                              _avatar(m.initials, m.dept),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                                    const SizedBox(height: 3),
                                    Text(m.role,
                                        style: TextStyle(fontSize: 12, color: context.textSecondary)),
                                  ],
                                ),
                              ),
                              _deptBadge(m.dept, context),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 14),

                      // Version card
                      _rawGlassCard(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                      color: AppColors.cyan.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('Version & Technical Info',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _versionRow(context, 'App Version', _version),
                            const SizedBox(height: 8),
                            _versionRow(context, 'Build Number', _build),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Glass card with icon + title + body/list
  Widget _glassCard(BuildContext context, {
    required IconData icon,
    required String title,
    String? body,
    List<String>? listItems,
    Color? tint,
  }) {
    return _rawGlassCard(
      context,
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.cyan, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary))),
            ],
          ),
          const SizedBox(height: 12),
          if (body != null)
            Text(body, style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.6)),
          if (listItems != null)
            ...listItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
                  ),
                  Expanded(child: Text(item,
                      style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.5))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  // Base glass container
  Widget _rawGlassCard(BuildContext context, {required Widget child, Color? tint}) {
    final isDark = context.isDark;
    final bg = tint != null
        ? tint.withValues(alpha: isDark ? 0.18 : 0.13)
        : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.55));
    final border = tint != null
        ? tint.withValues(alpha: isDark ? 0.25 : 0.30)
        : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.90));
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _avatar(String initials, String dept) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: _avatarColor(dept),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _deptBadge(String dept, BuildContext context) {
    final color = _badgeColor(dept);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(dept,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Color _avatarColor(String dept) {
    switch (dept) {
      case 'CHE':  return const Color(0xFF3DBFC5);
      case 'ISE':  return const Color(0xFF5B6BAE);
      case 'PETE': return const Color(0xFF3DBE78);
      default:     return const Color(0xFF3D4F9F);
    }
  }

  Color _badgeColor(String dept) {
    switch (dept) {
      case 'CHE':  return AppColors.cyan;
      case 'ISE':  return const Color(0xFF7B8FD4);
      case 'PETE': return const Color(0xFF3DBE78);
      default:     return const Color(0xFF7B8FD4);
    }
  }

  Widget _versionRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.textTertiary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
      ],
    );
  }
}

// Banner with floating bubbles
class _BubbleBanner extends StatelessWidget {
  const _BubbleBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D3A7A), Color(0xFF4A6FA5), Color(0xFF3DBFC5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background bubbles
            _bubble(top: -30, left: -20,  size: 110, opacity: 0.18),
            _bubble(top: 20,  right: -30, size: 130, opacity: 0.14),
            _bubble(bottom: -40, left: 60, size: 140, opacity: 0.12),
            _bubble(top: 10,  left: 80,   size: 60,  opacity: 0.20),
            _bubble(bottom: 10, right: 60, size: 50,  opacity: 0.22),
            _bubble(top: 50,  left: -10,  size: 70,  opacity: 0.13),
            // Content bottom-left
            Positioned(
              left: 20, right: 20, bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Industrial Cracking Process Facility',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('CrackX · KFUPM',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final String dept;
  const _TeamMember(this.name, this.role, this.dept);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }
}
