import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

const _green = Color(0xFF27AE60);
const _greenLight = Color(0xFF2ECC71);
const _orange = Color(0xFFF39C12);
const _red = Color(0xFFE74C3C);

class Co2AssessmentResultsScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const Co2AssessmentResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final status = result['status'] as String? ?? 'Unknown';
    final message = result['feasibility_message'] as String? ?? '';
    final maxYears = result['max_safe_injection_time_years'];
    final finalPressure = result['final_pressure_mpa'];
    final maxRate = result['max_sustainable_rate_kg_hr'];
    final plumeRadius = result['estimated_plume_radius_m'];

    final Color statusColor = switch (status) {
      'Feasible' => _greenLight,
      'Conditional' => _orange,
      _ => _red,
    };

    final IconData statusIcon = switch (status) {
      'Feasible' => Icons.check_circle_outline,
      'Conditional' => Icons.warning_amber_outlined,
      _ => Icons.cancel_outlined,
    };

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
                      Text('Back to Assessment', style: AppTextStyles.body),
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
                      // Title row
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assessment Results', style: AppTextStyles.heading1),
                                Text('CO₂ geological storage feasibility', style: AppTextStyles.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Status badge card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.30), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: statusColor.withValues(alpha: 0.18), blurRadius: 32, spreadRadius: 2, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(statusIcon, color: statusColor, size: 34),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Feasibility message
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(fontSize: 14, color: AppColors.darkBase, height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Key Metrics
                      const Text(
                        'Key Metrics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkBase),
                      ),
                      const SizedBox(height: 14),

                      _metricsGrid(
                        statusColor: statusColor,
                        metrics: [
                          _Metric(Icons.schedule_outlined, 'Max safe injection time', '${maxYears ?? '–'}', 'yr'),
                          _Metric(Icons.compress_outlined, 'Final reservoir pressure', '${finalPressure ?? '–'}', 'MPa'),
                          _Metric(Icons.speed_outlined, 'Max sustainable rate', '${maxRate ?? '–'}', 'kg/hr'),
                          _Metric(Icons.radio_button_unchecked, 'Estimated plume radius', '${plumeRadius ?? '–'}', 'm'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Done button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_green, Color(0xFF1A6B40)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                            boxShadow: [
                              BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Back to Assessment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
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

  Widget _metricsGrid({required Color statusColor, required List<_Metric> metrics}) {
    return Column(
      children: metrics.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(m.label, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
              ),
              Text(
                m.value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkBase),
              ),
              const SizedBox(width: 4),
              Text(
                m.unit,
                style: TextStyle(fontSize: 12, color: AppColors.textLight.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _Metric {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  const _Metric(this.icon, this.label, this.value, this.unit);
}
