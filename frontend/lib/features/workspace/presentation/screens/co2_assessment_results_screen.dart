import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';

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
    final pressureSpots = _toSpots(result['pressure_series']);
    final plumeSpots = _toSpots(result['plume_series']);
    final allowablePressure =
        (result['allowable_pressure_mpa'] as num?)?.toDouble();
    final reservoirRadius = (result['reservoir_radius_m'] as num?)?.toDouble();

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
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios,
                          size: 16, color: AppColors.textMedium),
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
                            child:
                                Icon(statusIcon, color: statusColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assessment Results',
                                    style: AppTextStyles.heading1),
                                Text('CO₂ geological storage feasibility',
                                    style: AppTextStyles.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Status badge card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.30),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: statusColor.withValues(alpha: 0.18),
                                blurRadius: 32,
                                spreadRadius: 2,
                                offset: const Offset(0, 8)),
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
                              child: Icon(statusIcon,
                                  color: statusColor, size: 34),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor),
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
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkBase,
                              height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Key Metrics
                      const Text(
                        'Key Metrics',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBase),
                      ),
                      const SizedBox(height: 14),

                      _metricsGrid(
                        statusColor: statusColor,
                        metrics: [
                          _Metric(
                              Icons.schedule_outlined,
                              'Max safe injection time',
                              '${maxYears ?? '–'}',
                              'yr'),
                          _Metric(
                              Icons.compress_outlined,
                              'Final reservoir pressure',
                              '${finalPressure ?? '–'}',
                              'MPa'),
                          _Metric(Icons.speed_outlined, 'Max sustainable rate',
                              '${maxRate ?? '–'}', 'kg/hr'),
                          _Metric(
                              Icons.radio_button_unchecked,
                              'Estimated plume radius',
                              '${plumeRadius ?? '–'}',
                              'm'),
                        ],
                      ),

                      if (pressureSpots.isNotEmpty &&
                          plumeSpots.isNotEmpty &&
                          allowablePressure != null &&
                          reservoirRadius != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Storage Trends',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBase),
                        ),
                        const SizedBox(height: 14),
                        _assessmentLineChart(
                          title: 'Pressure vs Time',
                          series: [
                            _ChartSeries(pressureSpots, 'Pressure (MPa)',
                                AppColors.primaryBlue, false),
                            _ChartSeries(
                              [
                                FlSpot(0, allowablePressure),
                                FlSpot(pressureSpots.last.x, allowablePressure)
                              ],
                              'Allowable P (MPa)',
                              _red,
                              true,
                            ),
                          ],
                          yMin: math.min(
                                pressureSpots.map((s) => s.y).reduce(math.min),
                                allowablePressure,
                              ) -
                              1,
                          yMax: math.max(
                                pressureSpots.map((s) => s.y).reduce(math.max),
                                allowablePressure,
                              ) +
                              1,
                          xLabel: 'Time (years)',
                          yLabel: 'Pressure (MPa)',
                        ),
                        const SizedBox(height: 16),
                        _assessmentLineChart(
                          title: 'Plume Radius vs Time',
                          series: [
                            _ChartSeries(plumeSpots, 'Plume radius (m)',
                                AppColors.cyan, false),
                            _ChartSeries(
                              [
                                FlSpot(0, reservoirRadius),
                                FlSpot(plumeSpots.last.x, reservoirRadius)
                              ],
                              'Reservoir radius (m)',
                              _red,
                              true,
                            ),
                          ],
                          yMin: 0,
                          yMax: math.max(
                            reservoirRadius * 1.2,
                            plumeSpots.map((s) => s.y).reduce(math.max) * 1.2 +
                                200,
                          ),
                          xLabel: 'Time (years)',
                          yLabel: 'Radius (m)',
                        ),
                      ],

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
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                  color: _green.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_ios,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Back to Assessment',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
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

  Widget _metricsGrid(
      {required Color statusColor, required List<_Metric> metrics}) {
    return Column(
      children: metrics
          .map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
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
                        child: Text(m.label,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMedium)),
                      ),
                      Text(
                        m.value,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBase),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        m.unit,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  static List<FlSpot> _toSpots(dynamic raw) {
    final points = raw is List ? raw : const [];
    return points
        .whereType<List>()
        .where((p) => p.length >= 2 && p[0] is num && p[1] is num)
        .map((p) => FlSpot((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
  }

  static double _niceInterval(double min, double max, int ticks) {
    final range = (max - min).abs();
    if (range == 0) return 1.0;
    final rough = range / (ticks - 1);
    final mag = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final norm = rough / mag;
    if (norm <= 1.5) return mag;
    if (norm <= 3.0) return 2 * mag;
    if (norm <= 7.0) return 5 * mag;
    return 10 * mag;
  }

  static double _niceMin(double v, double i) => (v / i).floor() * i;
  static double _niceMax(double v, double i) => (v / i).ceil() * i;

  Widget _assessmentLineChart({
    required String title,
    required List<_ChartSeries> series,
    required double yMin,
    required double yMax,
    required String xLabel,
    required String yLabel,
  }) {
    final xMax =
        series.expand((s) => s.spots.map((p) => p.x)).fold<double>(0, math.max);
    final xInterval = _niceInterval(0, xMax, 7);
    final yInterval = _niceInterval(yMin, yMax, 7);
    final effectiveYMin = _niceMin(yMin, yInterval);
    final effectiveYMax = _niceMax(yMax, yInterval);

    String yFmt(double v) =>
        yInterval >= 100 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBase)),
          const SizedBox(height: 18),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: xMax,
                minY: effectiveYMin,
                maxY: effectiveYMax,
                clipData: const FlClipData.all(),
                lineBarsData: series
                    .map(
                      (s) => LineChartBarData(
                        spots: s.spots,
                        isCurved: !s.dashed,
                        color: s.color,
                        barWidth: s.dashed ? 2.5 : 4,
                        dashArray: s.dashed ? [6, 4] : null,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    )
                    .toList(),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(xLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600)),
                    ),
                    axisNameSize: 28,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      interval: xInterval,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          xInterval >= 1
                              ? v.toStringAsFixed(0)
                              : v.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textLight),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(yLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600)),
                    ),
                    axisNameSize: 28,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 62,
                      interval: yInterval,
                      getTitlesWidget: (v, _) => Text(yFmt(v),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textLight),
                          textAlign: TextAlign.right),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval,
                  verticalInterval: xInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.textLight.withValues(alpha: 0.18),
                      strokeWidth: 1),
                  getDrawingVerticalLine: (_) => FlLine(
                      color: AppColors.textLight.withValues(alpha: 0.18),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                      color: AppColors.textLight.withValues(alpha: 0.28),
                      width: 1),
                ),
              ),
              duration: Duration.zero,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: series
                .map((s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(
                            size: const Size(22, 10),
                            painter: _LineLegendPainter(
                                color: s.color, dashed: s.dashed)),
                        const SizedBox(width: 6),
                        Text(s.label,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textLight)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
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

class _ChartSeries {
  final List<FlSpot> spots;
  final String label;
  final Color color;
  final bool dashed;

  const _ChartSeries(this.spots, this.label, this.color, this.dashed);
}

class _LineLegendPainter extends CustomPainter {
  final Color color;
  final bool dashed;

  const _LineLegendPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 2.5 : 4
      ..strokeCap = StrokeCap.round;

    if (dashed) {
      var x = 0.0;
      var draw = true;
      while (x < size.width) {
        final end = math.min(x + 5, size.width);
        if (draw) {
          canvas.drawLine(
              Offset(x, size.height / 2), Offset(end, size.height / 2), paint);
        }
        x += draw ? 5 : 3;
        draw = !draw;
      }
    } else {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LineLegendPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}
