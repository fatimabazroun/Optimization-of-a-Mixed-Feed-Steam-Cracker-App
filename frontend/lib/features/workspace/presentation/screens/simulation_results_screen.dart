import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/scenario_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/simulation_service.dart';

class SimulationResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final String temperature;
  final String pressure;
  final String scenarioId;
  final dynamic selectedValue;
  final bool useReservoir;
  final Map<String, dynamic>? reservoirInputs;
  // When opening a saved scenario, pass the raw API response to skip re-running.
  final Map<String, dynamic>? cachedRawData;

  const SimulationResultsScreen({
    super.key,
    required this.scenario,
    required this.temperature,
    required this.pressure,
    required this.scenarioId,
    required this.selectedValue,
    this.useReservoir = false,
    this.reservoirInputs,
    this.cachedRawData,
  });

  @override
  State<SimulationResultsScreen> createState() =>
      _SimulationResultsScreenState();
}

class _SimulationResultsScreenState extends State<SimulationResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;
  int _selectedTab = 0;
  late final List<String> _tabs;

  Map<String, dynamic>? _results;
  Map<String, dynamic>? _rawApiData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = widget.useReservoir
        ? ['Overview', 'Performance', 'Raw KPIs', 'Recommendation']
        : ['Overview', 'Raw KPIs', 'Recommendation'];
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final data = widget.cachedRawData ??
          await SimulationService.runSimulation(
            scenarioId: widget.scenarioId,
            selectedValue: widget.selectedValue,
            useReservoir: widget.useReservoir,
            reservoirInputs: widget.reservoirInputs,
          );
      if (mounted) {
        setState(() {
          _rawApiData = data;
          _results = _mapApiResponse(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapApiResponse(Map<String, dynamic> data) {
    final r = data['results'] as Map<String, dynamic>;
    final perf = data['performance'] as Map<String, dynamic>;

    final ethyleneYield = (r['ethylene_yield_percent'] as num? ?? 0).toDouble();
    final furnaceReduction = (r['furnace_reduction_percent'] as num? ?? 0).toDouble();
    final costSaving = (r['cost_saving_percent'] as num? ?? 0).toDouble();
    final hydrogenPurity = (r['hydrogen_purity_percent'] as num? ?? 0).toDouble();
    final co2Rate = (r['co2_rate'] as num? ?? 0).toDouble();

    // Reservoir results (only present when use_reservoir=true)
    final res = data['reservoir'] as Map<String, dynamic>?;
    final feasibility = res != null ? res['status'] as String : 'N/A';
    final Color feasColor;
    final IconData feasIcon;
    if (feasibility == 'Feasible') {
      feasColor = const Color(0xFF2ECC71);
      feasIcon = Icons.check_circle_outline;
    } else if (feasibility == 'Conditional') {
      feasColor = const Color(0xFFF39C12);
      feasIcon = Icons.warning_amber_outlined;
    } else if (feasibility == 'Infeasible') {
      feasColor = const Color(0xFFE74C3C);
      feasIcon = Icons.cancel_outlined;
    } else {
      feasColor = AppColors.textLight;
      feasIcon = Icons.hourglass_empty_outlined;
    }

    final ise = data['ise'] as Map<String, dynamic>?;
    final iseKpis = data['ise_calculated_kpis'] as Map<String, dynamic>?;

    return {
      'ethyleneYield': ethyleneYield,
      'furnaceReduction': furnaceReduction,
      'costSaving': costSaving,
      'hydrogenPurity': hydrogenPurity,
      'co2Rate': co2Rate,
      'performance': perf,
      'feasibility': feasibility,
      'feasibilityColor': feasColor,
      'feasibilityIcon': feasIcon,
      'feasibilityMessage': res?['feasibility_message'] as String? ?? '',
      'maxInjectionTime':
          (res?['max_safe_injection_time_years'] as num? ?? 0).toDouble(),
      'pressureAtEnd':
          (res?['final_pressure_mpa'] as num? ?? 0).toDouble(),
      'maxSustainableRate':
          (res?['max_sustainable_rate_kg_hr'] as num? ?? 0).toDouble(),
      'plumeRadius':
          (res?['estimated_plume_radius_m'] as num? ?? 0).toDouble(),
      'allowablePressure':
          (res?['allowable_pressure_mpa'] as num? ?? 0).toDouble(),
      'pressureSeries': (res?['pressure_series'] as List<dynamic>? ?? [])
          .map((p) => FlSpot((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList(),
      'plumeSeries': (res?['plume_series'] as List<dynamic>? ?? [])
          .map((p) => FlSpot((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList(),
      'iseRecommendation': ise?['recommendation'] as String? ?? '',
      'ethyleneKgHr': (iseKpis?['ethylene_kg_hr'] as num? ?? 0).toDouble(),
      'hydrogenKgHr': (iseKpis?['hydrogen_kg_hr'] as num? ?? 0).toDouble(),
      'co2eKgHr': (iseKpis?['co2e_kg_hr'] as num? ?? 0).toDouble(),
    };
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = widget.scenario['color'] as Color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            size: 16, color: context.textSecondary),
                        SizedBox(width: 4),
                        Text('Back to Configuration',
                            style: TextStyle(fontSize: 14, color: context.textSecondary)),
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
                        Text('Simulation Results',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.2)),
                        SizedBox(height: 20),

                        // Tabs
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _tabs.asMap().entries.map((e) {
                                final selected = _selectedTab == e.key;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTab = e.key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: selected
                                          ? LinearGradient(
                                              colors: [
                                                accentColor,
                                                AppColors.primaryBlue
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(e.value,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.textLight,
                                        )),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Tab content
                        if (_isLoading)
                          _buildLoadingState(accentColor)
                        else if (_error != null)
                          _buildErrorState(accentColor)
                        else
                          _buildTabContent(accentColor),

                        SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            if (widget.cachedRawData == null) ...[
                              Expanded(
                                  child: _GlowActionButton(
                                      icon: Icons.bookmark_outline,
                                      label: 'Save',
                                      accentColor: accentColor,
                                      onTap: () =>
                                          _showSaveDialog(context, accentColor))),
                              SizedBox(width: 12),
                            ],
                            Expanded(
                                child: _GlowActionButton(
                                    icon: Icons.download_outlined,
                                    label: 'Report',
                                    accentColor: accentColor,
                                    onTap: () => _generateReport(context))),
                            SizedBox(width: 12),
                            Expanded(
                                child: _GlowActionButton(
                                    icon: Icons.refresh_rounded,
                                    label: 'Recalculate',
                                    accentColor: accentColor,
                                    onTap: () => Navigator.pop(context))),
                          ],
                        ),

                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color accentColor) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accentColor, strokeWidth: 2.5),
          SizedBox(height: 20),
          Text('Running simulation…',
              style: TextStyle(fontSize: 14, color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 36),
          SizedBox(height: 12),
          Text('Simulation failed',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: context.textSecondary)),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadResults();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: accentColor, borderRadius: BorderRadius.circular(10)),
              child: Text('Retry',
                  style: TextStyle(
                      color: context.surface, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Color accentColor) {
    final tab = _tabs[_selectedTab];
    if (tab == 'Overview') return _buildOverview();
    if (tab == 'Performance') return _buildPerformance(accentColor);
    if (tab == 'Raw KPIs') return _buildTrends(accentColor);
    return _buildRecommendation(accentColor);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Not Acceptable':
      case 'Risky':
      case 'Infeasible':
        return const Color(0xFFE74C3C);
      case 'Needs Improvement':
      case 'Minor Improvement':
      case 'Moderate Performance':
      case 'Moderate Improvement':
      case 'Conditional':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF2ECC71);
    }
  }

  Widget _buildOverview() {
    final r = _results!;
    final perf = r['performance'] as Map<String, dynamic>;

    Map<String, dynamic> perfFor(String key) =>
        perf[key] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cracking Performance (always first) ──
        Text('Cracking Performance',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary)),
        SizedBox(height: 12),

        _cheMetricCard(
          label: 'Ethylene Yield',
          value: (r['ethyleneYield'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.bubble_chart_outlined,
          color: AppColors.cyan,
          perf: perfFor('ethylene_yield'),
        ),
        SizedBox(height: 10),
        _cheMetricCard(
          label: 'Furnace Reduction',
          value: (r['furnaceReduction'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.local_fire_department_outlined,
          color: AppColors.cyan,
          perf: perfFor('furnace_reduction'),
        ),
        SizedBox(height: 10),
        _cheMetricCard(
          label: 'Cost Saving',
          value: (r['costSaving'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.attach_money_outlined,
          color: AppColors.purple,
          perf: perfFor('cost_saving'),
        ),
        SizedBox(height: 10),
        _cheMetricCard(
          label: 'Hydrogen Purity',
          value: (r['hydrogenPurity'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.science_outlined,
          color: AppColors.midTone,
          perf: perfFor('hydrogen_purity'),
        ),

        // ── CO₂ Storage (only when reservoir was run) ──
        if (widget.useReservoir) ...[
          SizedBox(height: 20),
          _buildFeasibilityCard(r),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _peteMetricCard(
                label: 'Max Safe\nInjection Time',
                value: (r['maxInjectionTime'] as double).toStringAsFixed(1),
                unit: 'years',
                icon: Icons.timer_outlined,
                description:
                    'How long we can inject before reaching the pressure limit.',
                color: AppColors.cyan,
              )),
              SizedBox(width: 12),
              Expanded(
                  child: _peteMetricCard(
                label: 'Pressure at\nProject End',
                value: (r['pressureAtEnd'] as double).toStringAsFixed(1),
                unit: 'MPa',
                icon: Icons.compress_outlined,
                description:
                    'Reservoir pressure at the end of the full project duration.',
                color: AppColors.purple,
              )),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _peteMetricCard(
                label: 'Max Sustainable\nInjection Rate',
                value: (r['maxSustainableRate'] as double).toStringAsFixed(0),
                unit: 'kg/hr',
                icon: Icons.speed_outlined,
                description:
                    'Maximum CO₂ rate the reservoir can handle safely.',
                color: AppColors.midTone,
              )),
              SizedBox(width: 12),
              Expanded(
                  child: _peteMetricCard(
                label: 'Plume\nRadius',
                value: (r['plumeRadius'] as double).toStringAsFixed(0),
                unit: 'm',
                icon: Icons.radar_outlined,
                description:
                    'How large the CO₂ plume becomes by end of project.',
                color: const Color(0xFF2ECC71),
              )),
            ],
          ),
          SizedBox(height: 20),
        ],

      ],
    );
  }

  Widget _buildFeasibilityCard(Map<String, dynamic> r) {
    final feasColor = r['feasibilityColor'] as Color;
    final feasIcon = r['feasibilityIcon'] as IconData;
    final feasLabel = r['feasibility'] as String;
    final feasMsg = r['feasibilityMessage'] as String;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: feasColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: feasColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: feasColor.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: feasColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('CO₂ STORAGE FEASIBILITY',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.textTertiary,
                    letterSpacing: 0.5)),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(feasIcon, color: feasColor, size: 28),
              SizedBox(width: 12),
              Text(feasLabel,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: feasColor)),
            ],
          ),
          if (feasMsg.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(feasMsg,
                style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _cheMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> perf,
  }) {
    final status = perf['status'] as String;
    final explanation = perf['explanation'] as String;
    final statusColor = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary)),
                    const Spacer(),
                    Text('$value $unit',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: color)),
                  ],
                ),
                SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
                SizedBox(height: 6),
                Text(explanation,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _peteMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 17),
              ),
              SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textTertiary,
                          height: 1.4))),
            ],
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 12, color: context.textSecondary)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(description,
              style: TextStyle(
                  fontSize: 10, color: context.textTertiary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildPerformance(Color accentColor) {
    final r = _results;
    final pressureSpots = (r?['pressureSeries'] as List<FlSpot>?) ?? [];
    final plumeSpots    = (r?['plumeSeries']    as List<FlSpot>?) ?? [];
    final pAllow          = (r?['allowablePressure'] as double?) ?? 0.0;
    final reservoirRadius = (widget.reservoirInputs?['radius'] as num? ?? 0).toDouble();

    final projectDuration =
        (widget.reservoirInputs?['project_duration'] as num?)?.toDouble() ?? 100.0;
    // Compute effectiveXMax here so all spots use the same final bound
    final xRaw       = projectDuration * 1.1;
    final xInterval  = _niceInterval(0, xRaw, 7);
    final xMax       = _niceMax(xRaw, xInterval);

    // Pressure Y
    final actualPressMin = pressureSpots.isNotEmpty
        ? pressureSpots.map((s) => s.y).reduce(math.min)
        : pAllow;
    final actualPressMax = pressureSpots.isNotEmpty
        ? pressureSpots.map((s) => s.y).reduce(math.max)
        : pAllow;
    final pressYMin = math.min(actualPressMin, pAllow) - 1.0;
    final pressYMax = math.max(actualPressMax, pAllow) + 1.0;

    // Plume Y
    final actualPlumeMax = plumeSpots.isNotEmpty
        ? plumeSpots.map((s) => s.y).reduce(math.max)
        : 0.0;
    final plumeYMax = math.max(reservoirRadius + 1000, actualPlumeMax + 200);

    // Reference lines span exactly 0 → xMax (same as chart bounds)
    final pAllowSpots = [FlSpot(0, pAllow), FlSpot(xMax, pAllow)];
    final resRadSpots = [FlSpot(0, reservoirRadius), FlSpot(xMax, reservoirRadius)];

    return Column(
      children: [
        _reservoirLineChart(
          title: 'Pressure vs Time',
          series: [
            _ChartSeries(spots: pressureSpots, label: 'Pressure (MPa)',    color: AppColors.primaryBlue,   dashed: false),
            _ChartSeries(spots: pAllowSpots,   label: 'Allowable P (MPa)', color: const Color(0xFFE74C3C), dashed: true),
          ],
          xMax: xMax,
          xInterval: xInterval,
          yMin: pressYMin,
          yMax: pressYMax,
          xLabel: 'Time (years)',
          yLabel: 'Pressure (MPa)',
        ),
        SizedBox(height: 16),
        _reservoirLineChart(
          title: 'Plume Radius vs Time',
          series: [
            _ChartSeries(spots: plumeSpots,  label: 'Plume radius (m)',    color: AppColors.cyan,          dashed: false),
            _ChartSeries(spots: resRadSpots, label: 'Reservoir radius (m)', color: const Color(0xFFE74C3C), dashed: true),
          ],
          xMax: xMax,
          xInterval: xInterval,
          yMin: 0,
          yMax: plumeYMax,
          xLabel: 'Time (years)',
          yLabel: 'Radius (m)',
        ),
      ],
    );
  }

  // ── Nice-number helpers ───────────────────────────────────────────────────
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
  static double _niceMax(double v, double i) => (v / i).ceil()  * i;

  Widget _reservoirLineChart({
    required String title,
    required List<_ChartSeries> series,
    required double xMax,
    required double xInterval,
    required double yMin,
    required double yMax,
    required String xLabel,
    required String yLabel,
  }) {
    // Ensure valid range
    final safeYMin = yMin.isFinite ? yMin : 0.0;
    final safeYMax = (yMax.isFinite && yMax > safeYMin) ? yMax : safeYMin + 1.0;

    final yInterval      = _niceInterval(safeYMin, safeYMax, 7);
    final effectiveYMin  = _niceMin(safeYMin, yInterval);
    final effectiveYMax  = _niceMax(safeYMax, yInterval);
    final effectiveXMax  = xMax;

    String yFmt(double v) =>
        yInterval >= 100 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: context.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          SizedBox(height: 20),
          RepaintBoundary(
            child: SizedBox(
              height: 320,
              child: LineChart(
                LineChartData(
                clipData: const FlClipData.all(),
                minX: 0,
                maxX: effectiveXMax,
                minY: effectiveYMin,
                maxY: effectiveYMax,
                lineBarsData: series.map((s) => LineChartBarData(
                  spots: s.spots.isEmpty
                      ? [FlSpot(0, safeYMin), FlSpot(effectiveXMax, safeYMin)]
                      : s.spots,
                  isCurved: !s.dashed,
                  color: s.spots.isEmpty
                      ? s.color.withValues(alpha: 0)
                      : s.color,
                  barWidth: s.dashed ? 2.5 : 4.0,
                  dotData: const FlDotData(show: false),
                  dashArray: s.dashed ? [6, 4] : null,
                  belowBarData: BarAreaData(show: false),
                )).toList(),
                titlesData: FlTitlesData(
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(xLabel,
                          style: TextStyle(fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    axisNameSize: 28,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      interval: xInterval,
                      getTitlesWidget: (v, meta) {
                        final label = xInterval >= 1
                            ? v.toStringAsFixed(0)
                            : xInterval >= 0.1
                                ? v.toStringAsFixed(1)
                                : v.toStringAsFixed(2);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 10, color: context.textTertiary)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(yLabel,
                          style: TextStyle(fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    axisNameSize: 28,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 62,
                      interval: yInterval,
                      getTitlesWidget: (v, _) => Text(yFmt(v),
                          style: TextStyle(
                              fontSize: 10, color: context.textTertiary),
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
                      color: context.textTertiary.withValues(alpha: 0.18),
                      strokeWidth: 1.0),
                  getDrawingVerticalLine: (_) => FlLine(
                      color: context.textTertiary.withValues(alpha: 0.18),
                      strokeWidth: 1.0),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                      color: context.textTertiary.withValues(alpha: 0.30),
                      width: 1.0),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.darkBase.withValues(alpha: 0.85),
                    getTooltipItems: (touched) => touched.map((s) {
                      final label = series[s.barIndex].label;
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(2)}\n',
                        TextStyle(fontSize: 11, color: context.surface,
                            fontWeight: FontWeight.w600),
                        children: [TextSpan(text: label,
                            style: TextStyle(fontSize: 9,
                                color: Colors.white70))],
                      );
                    }).toList(),
                  ),
                ),
                ),
                duration: Duration.zero,
              ),
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 18, runSpacing: 6,
            children: series.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(size: const Size(22, 10),
                    painter: _LineLegendPainter(color: s.color, dashed: s.dashed)),
                SizedBox(width: 6),
                Text(s.label,
                    style: TextStyle(fontSize: 10, color: context.textTertiary)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(Color accentColor) {
    final r = _results!;
    final iseRec = (r['iseRecommendation'] as String?) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (iseRec.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.lightbulb_outline, color: accentColor, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Optimization Recommendation',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      SizedBox(height: 6),
                      Text(iseRec,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.lightbulb_outline, size: 40, color: AppColors.highlight),
                SizedBox(height: 12),
                Text('No recommendation available',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textSecondary)),
                SizedBox(height: 6),
                Text('Run a simulation to receive optimization guidance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: context.textTertiary)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrends(Color accentColor) {
    final r = _results!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Calculated KPIs',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary)),
        SizedBox(height: 12),
        _kpiCard(
          label: 'Ethylene Production',
          value: ((r['ethyleneKgHr'] as double?) ?? 0.0).toStringAsFixed(1),
          unit: 'kg/hr',
          icon: Icons.bubble_chart_outlined,
          color: accentColor,
          description: 'Mass flow rate of ethylene produced from cracking.',
        ),
        SizedBox(height: 12),
        _kpiCard(
          label: 'Hydrogen Production',
          value: ((r['hydrogenKgHr'] as double?) ?? 0.0).toStringAsFixed(1),
          unit: 'kg/hr',
          icon: Icons.science_outlined,
          color: AppColors.cyan,
          description: 'Mass flow rate of hydrogen recovered from the process.',
        ),
        SizedBox(height: 12),
        _kpiCard(
          label: 'CO₂ Emissions',
          value: ((r['co2eKgHr'] as double?) ?? 0.0).toStringAsFixed(1),
          unit: 'kg/hr',
          icon: Icons.cloud_outlined,
          color: const Color(0xFF2ECC71),
          description: 'CO₂ equivalent emissions from the cracking process.',
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary)),
                SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        fontSize: 10, color: context.textTertiary, height: 1.4)),
              ],
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(unit,
                  style: TextStyle(
                      fontSize: 11, color: context.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(BuildContext context) async {
    if (_results == null) return;
    final accentColor = widget.scenario['color'] as Color;

    // ── Liquid glass loading dialog ───────────────────────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: context.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
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
                    color: accentColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2.5),
                  ),
                ),
                SizedBox(height: 20),
                Text('Generating Report',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                SizedBox(height: 8),
                Text('Building your PDF, this may take\na few seconds…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final now = DateTime.now();
      final ts  = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}'
                  '_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}';

      final url = await ReportService.generateReport(
        scenario: widget.scenario['title'] as String,
        temperature: widget.temperature,
        pressure: widget.pressure,
        scenarioId: widget.scenarioId,
        selectedValue: widget.selectedValue,
        useReservoir: widget.useReservoir,
        results: _results!,
        reservoir: _rawApiData?['reservoir'] as Map<String, dynamic>?,
      );

      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${widget.scenario['title']}_Report_$ts',
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog

      // ── Liquid glass error dialog ─────────────────────────────────────────
      showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.surfaceModal,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.20), width: 1.2),
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
                    child: Icon(Icons.error_outline,
                        color: Colors.red, size: 28),
                  ),
                  SizedBox(height: 20),
                  Text('Report Failed',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  SizedBox(height: 8),
                  Text('Could not generate the PDF report.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: context.textSecondary)),
                  SizedBox(height: 8),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textTertiary,
                          height: 1.4)),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.textPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Dismiss',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showSaveDialog(BuildContext context, Color accentColor) async {
    // ── Duplicate check ───────────────────────────────────────────────────────
    final existing = await ScenarioService.loadScenarios();
    if (!context.mounted) return;

    final isDuplicate = existing.any((s) =>
        s['scenario']?.toString() == widget.scenario['title']?.toString() &&
        s['temperature']?.toString() == widget.temperature &&
        s['pressure']?.toString() == widget.pressure &&
        s['selectedValue']?.toString() == widget.selectedValue?.toString());

    if (isDuplicate) {
      final saveAgain = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.surfaceModal,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: const Color(0xFFF39C12).withValues(alpha: 0.30),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF39C12).withValues(alpha: 0.15),
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
                      color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_added_outlined,
                        color: Color(0xFFF39C12), size: 28),
                  ),
                  SizedBox(height: 20),
                  Text('Already Saved',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  SizedBox(height: 8),
                  Text(
                      'This simulation has already been saved. Do you want to save it again?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.5)),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(_, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.inputBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondary)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(_, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF39C12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Save Again',
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
      if (!context.mounted || saveAgain != true) return;
    }

    // ── Name dialog ───────────────────────────────────────────────────────────
    final now = DateTime.now();
    final nameController = TextEditingController(
      text: '${widget.scenario['title']} – ${now.day} ${_monthName(now.month)} ${now.year}, '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
    );

    if (!context.mounted) return;
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
              color: context.surfaceModal,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.20), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
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
                    color: accentColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark_outline,
                      color: accentColor, size: 26),
                ),
                SizedBox(height: 20),
                Text('Save Scenario',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                SizedBox(height: 8),
                Text('Enter a name to save this simulation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        height: 1.5)),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Scenario Name',
                      style: TextStyle(
                          fontSize: 12, color: context.textTertiary)),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style:
                      TextStyle(fontSize: 14, color: context.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: context.inputBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          Navigator.pop(context);
                          _saveScenario(context, name);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('Save',
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

  String _deriveStatus() {
    if (widget.useReservoir) {
      final feas = _results!['feasibility'] as String;
      if (feas == 'Feasible') return 'Optimal';
      if (feas == 'Conditional') return 'Warning';
      if (feas == 'Infeasible') return 'Critical';
    }
    final perf = _results!['performance'] as Map<String, dynamic>;
    final statuses = perf.values
        .map((v) => ((v as Map<String, dynamic>)['status'] as String? ?? '').toLowerCase())
        .toList();
    if (statuses.any((s) => s.contains('critical') || s.contains('infeasible'))) return 'Critical';
    if (statuses.any((s) => s.contains('moderate') || s.contains('warning') || s.contains('needs'))) return 'Warning';
    return 'Optimal';
  }

  Future<void> _saveScenario(BuildContext context, String name) async {
    final accentColor = widget.scenario['color'] as Color;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: context.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.18), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
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
                    color: accentColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2.5),
                  ),
                ),
                SizedBox(height: 20),
                Text('Saving Scenario',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                SizedBox(height: 8),
                Text('Uploading your results, please wait…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final now = DateTime.now();
      final simId = 'SIM-${now.year}-${now.millisecondsSinceEpoch % 10000}';
      final date =
          '${_monthName(now.month)} ${now.day}, ${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await ScenarioService.addScenario(
        {
          'name':          name,
          'date':          date,
          'simId':         simId,
          'status':        _deriveStatus(),
          'temperature':   widget.temperature,
          'pressure':      widget.pressure,
          'scenario':      widget.scenario['title'],
          'scenarioType':  widget.scenarioId,
          'selectedValue': widget.selectedValue,
          'useReservoir':  widget.useReservoir,
        },
        _rawApiData ?? {},
      );

      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog
      showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.surfaceModal,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
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
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline,
                        color: Color(0xFF2ECC71), size: 28),
                  ),
                  SizedBox(height: 20),
                  Text('Scenario Saved',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  SizedBox(height: 8),
                  Text('Your simulation has been saved successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.5)),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.inputBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Dismiss',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondary)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const MainShell(initialIndex: 0),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                            (route) => false,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: context.textPrimary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('View Saved',
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
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog
      showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.surfaceModal,
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
                    child: Icon(Icons.error_outline, color: Colors.red, size: 28),
                  ),
                  SizedBox(height: 20),
                  Text('Save Failed',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  SizedBox(height: 8),
                  Text('Could not save the scenario.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: context.textSecondary)),
                  SizedBox(height: 8),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: context.textTertiary, height: 1.4)),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.textPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Dismiss',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _GlowActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlowActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GlowActionButton> createState() => _GlowActionButtonState();
}

class _GlowActionButtonState extends State<_GlowActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 600),
    );
    _controller.addListener(() {
      setState(() => _scale = 1.0 - (_controller.value * 0.07));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0).then((_) {
      if (!mounted) return;
      widget.onTap();
      _controller.animateBack(0.0, curve: Curves.elasticOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, AppColors.primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.40),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: context.surface, size: 22),
              SizedBox(height: 4),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chart data model ────────────────────────────────────────────────────────

class _ChartSeries {
  final List<FlSpot> spots;
  final String label;
  final Color color;
  final bool dashed;
  const _ChartSeries({
    required this.spots,
    required this.label,
    required this.color,
    required this.dashed,
  });
}

// ── Legend painter ──────────────────────────────────────────────────────────

class _LineLegendPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  const _LineLegendPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 1.8 : 2.5
      ..style = PaintingStyle.stroke;
    if (dashed) {
      double x = 0;
      bool draw = true;
      while (x < size.width) {
        final end = math.min(x + 5, size.width);
        if (draw) canvas.drawLine(Offset(x, size.height / 2), Offset(end, size.height / 2), paint);
        x += draw ? 5 : 3;
        draw = !draw;
      }
    } else {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LineLegendPainter old) => false;
}

