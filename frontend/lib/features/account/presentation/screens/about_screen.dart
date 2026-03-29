import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textMedium),
                      SizedBox(width: 4),
                      Text('Back', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About', style: AppTextStyles.heading1),
                      const Text('Mixed Feed Cracker Application', style: AppTextStyles.body),
                      const SizedBox(height: 20),

                      // App image placeholder
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [AppColors.darkBase, AppColors.midTone],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(Icons.factory_outlined, size: 72,
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            Positioned(
                              bottom: 12, left: 16,
                              child: Text('Industrial Cracking Process Facility',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _aboutCard(
                        icon: Icons.science_outlined,
                        title: 'What is the Mixed Feed Cracker?',
                        body: 'The Mixed Feed Cracker application simulates thermal cracking processes used in '
                            'petrochemical production to evaluate temperature, pressure, flow rates, and emission '
                            'performance under controlled parameters. This advanced simulation tool enables engineers '
                            'to optimize process conditions before implementing changes in real-world operations.',
                      ),

                      const SizedBox(height: 14),

                      _aboutCard(
                        icon: Icons.trending_up_rounded,
                        title: 'What This Application Does',
                        isList: true,
                        listItems: [
                          'Simulate mixed feed streams',
                          'Calculates thermal and pressure outputs',
                          'Evaluates CO₂ emission scope',
                          'Provides performance KPIs',
                          'Generates visualization plots',
                        ],
                      ),

                      const SizedBox(height: 14),

                      _aboutCard(
                        icon: Icons.people_outline,
                        title: 'Who It Is For',
                        body: 'This application is designed for process engineers, industrial researchers, plant '
                            'operators, and energy analysts who need to evaluate and optimize thermal cracking '
                            'processes. It provides critical insights for decision-making in petrochemical '
                            'production environments.',
                      ),

                      const SizedBox(height: 14),

                      // Version card
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text('Version & Technical Info',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _versionRow('App Version', 'v2.1.4'),
                            const SizedBox(height: 8),
                            _versionRow('Build Number', '#2026.02.11'),
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

  Widget _aboutCard({
    required IconData icon,
    required String title,
    String? body,
    bool isList = false,
    List<String>? listItems,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.cyan, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBase,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (body != null)
            Text(body, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6)),
          if (isList && listItems != null)
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
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _versionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkBase)),
      ],
    );
  }
}