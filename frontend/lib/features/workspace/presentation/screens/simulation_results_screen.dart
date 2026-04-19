import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
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

    final ethyleneYield = (r['ethylene_yield_percent'] as num).toDouble();
    final furnaceReduction = (r['furnace_reduction_percent'] as num).toDouble();
    final costSaving = (r['cost_saving_percent'] as num).toDouble();
    final hydrogenPurity = (r['hydrogen_purity_percent'] as num).toDouble();
    final co2Rate = (r['co2_rate'] as num).toDouble();

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
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            size: 16, color: AppColors.textMedium),
                        SizedBox(width: 4),
                        Text('Back to Configuration',
                            style: AppTextStyles.body),
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
                        const Text('Simulation Results',
                            style: AppTextStyles.heading1),
                        const SizedBox(height: 20),

                        // Tabs
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
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

                        const SizedBox(height: 20),

                        // Tab content
                        if (_isLoading)
                          _buildLoadingState(accentColor)
                        else if (_error != null)
                          _buildErrorState(accentColor)
                        else
                          _buildTabContent(accentColor),

                        const SizedBox(height: 24),

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
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                                child: _GlowActionButton(
                                    icon: Icons.download_outlined,
                                    label: 'Report',
                                    accentColor: accentColor,
                                    onTap: () => _generateReport(context))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _GlowActionButton(
                                    icon: Icons.refresh_rounded,
                                    label: 'Recalculate',
                                    accentColor: accentColor,
                                    onTap: () => Navigator.pop(context))),
                          ],
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
          const SizedBox(height: 20),
          const Text('Running simulation…',
              style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 12),
          const Text('Simulation failed',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBase)),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMedium)),
          const SizedBox(height: 16),
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
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
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
        const Text('Cracking Performance',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBase)),
        const SizedBox(height: 12),

        _cheMetricCard(
          label: 'Ethylene Yield',
          value: (r['ethyleneYield'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.bubble_chart_outlined,
          color: AppColors.cyan,
          perf: perfFor('ethylene_yield'),
        ),
        const SizedBox(height: 10),
        _cheMetricCard(
          label: 'Furnace Reduction',
          value: (r['furnaceReduction'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.local_fire_department_outlined,
          color: Colors.orange,
          perf: perfFor('furnace_reduction'),
        ),
        const SizedBox(height: 10),
        _cheMetricCard(
          label: 'Cost Saving',
          value: (r['costSaving'] as double).toStringAsFixed(1),
          unit: '%',
          icon: Icons.attach_money_outlined,
          color: AppColors.purple,
          perf: perfFor('cost_saving'),
        ),
        const SizedBox(height: 10),
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
          const SizedBox(height: 20),
          _buildFeasibilityCard(r),
          const SizedBox(height: 14),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 20),
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
            child: const Text('CO₂ STORAGE FEASIBILITY',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(feasIcon, color: feasColor, size: 28),
              const SizedBox(width: 12),
              Text(feasLabel,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: feasColor)),
            ],
          ),
          if (feasMsg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(feasMsg,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
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
        color: Colors.white,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBase)),
                    const Spacer(),
                    Text('$value $unit',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 6),
                Text(explanation,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
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
        color: Colors.white,
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
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          height: 1.4))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textLight, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildPerformance(Color accentColor) {
    return Column(
      children: [
        _chartPlaceholder(
          title: 'Pressure vs Time',
          description:
              'Shows how reservoir pressure increases over time and where it hits the allowable limit.',
          icon: Icons.show_chart_rounded,
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),
        _chartPlaceholder(
          title: 'Plume Radius vs Time',
          description:
              'Shows how the CO₂ plume spreads in the reservoir over the project duration.',
          icon: Icons.radar_outlined,
          accentColor: AppColors.cyan,
        ),
      ],
    );
  }

  Widget _chartPlaceholder({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBase)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.12)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_chart_outlined_rounded,
                      size: 36, color: accentColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('Chart coming soon',
                      style: TextStyle(
                          fontSize: 12,
                          color: accentColor.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight, height: 1.5)),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Optimization Recommendation',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBase)),
                      const SizedBox(height: 6),
                      Text(iseRec,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.lightbulb_outline, size: 40, color: AppColors.highlight),
                SizedBox(height: 12),
                Text('No recommendation available',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                SizedBox(height: 6),
                Text('Run a simulation to receive optimization guidance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textLight)),
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
        const Text('Calculated KPIs',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBase)),
        const SizedBox(height: 12),
        _kpiCard(
          label: 'Ethylene Production',
          value: ((r['ethyleneKgHr'] as double?) ?? 0.0).toStringAsFixed(1),
          unit: 'kg/hr',
          icon: Icons.bubble_chart_outlined,
          color: accentColor,
          description: 'Mass flow rate of ethylene produced from cracking.',
        ),
        const SizedBox(height: 12),
        _kpiCard(
          label: 'Hydrogen Production',
          value: ((r['hydrogenKgHr'] as double?) ?? 0.0).toStringAsFixed(1),
          unit: 'kg/hr',
          icon: Icons.science_outlined,
          color: AppColors.cyan,
          description: 'Mass flow rate of hydrogen recovered from the process.',
        ),
        const SizedBox(height: 12),
        _kpiCard(
          label: 'CO₂ Emissions',
          value: ((r['co2eKgHr'] as double?) ?? 0.0).toStringAsFixed(1),
          unit: 'kg/hr',
          icon: Icons.cloud_outlined,
          color: Colors.orange,
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
        color: Colors.white,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBase)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textLight, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMedium)),
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
              color: Colors.white.withValues(alpha: 0.92),
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
                const SizedBox(height: 20),
                const Text('Generating Report',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBase)),
                const SizedBox(height: 8),
                const Text('Building your PDF, this may take\na few seconds…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final url = await ReportService.generateReport(
        scenario: widget.scenario['title'] as String,
        temperature: widget.temperature,
        pressure: widget.pressure,
        scenarioId: widget.scenarioId,
        selectedValue: widget.selectedValue,
        useReservoir: widget.useReservoir,
        results: _results!,
      );

      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${widget.scenario['title']}_Report',
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
                color: Colors.white.withValues(alpha: 0.95),
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
                    child: const Icon(Icons.error_outline,
                        color: Colors.red, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Report Failed',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBase)),
                  const SizedBox(height: 8),
                  const Text('Could not generate the PDF report.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  const SizedBox(height: 8),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          height: 1.4)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.darkBase,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('Dismiss',
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

  void _showSaveDialog(BuildContext context, Color accentColor) {
    final nameController = TextEditingController(
      text:
          '${widget.scenario['title']} – ${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Save Scenario',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.darkBase)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name to save this simulation',
                style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
            const SizedBox(height: 12),
            const Text('Scenario Name',
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: const TextStyle(fontSize: 14, color: AppColors.darkBase),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              _saveScenario(context, name);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          'scenarioId':    widget.scenarioId,
          'selectedValue': widget.selectedValue,
          'useReservoir':  widget.useReservoir,
        },
        _rawApiData ?? {},
      );

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
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
                    child: const Icon(Icons.check_circle_outline,
                        color: Color(0xFF2ECC71), size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Scenario Saved',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBase)),
                  const SizedBox(height: 8),
                  const Text('Your simulation has been saved successfully.',
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
                            child: const Text('Dismiss',
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
                              color: AppColors.darkBase,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('View Saved',
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
      showDialog(
        context: context,
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
                    child: const Icon(Icons.error_outline, color: Colors.red, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Save Failed',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBase)),
                  const SizedBox(height: 8),
                  const Text('Could not save the scenario.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  const SizedBox(height: 8),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight, height: 1.4)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.darkBase,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('Dismiss',
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
  late Animation<double> _borderProgress;
  late Animation<double> _glowRadius;
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _borderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.65, curve: Curves.easeInOut)),
    );
    _glowRadius = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTap();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _controller.reset();
            setState(() => _tapped = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_tapped) return;
    setState(() => _tapped = true);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Stack(
          children: [
            Container(
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
                    color: widget.accentColor.withValues(alpha: 0.45),
                    blurRadius: _glowRadius.value,
                    spreadRadius: _glowRadius.value * 0.15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  Text(widget.label,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _BorderDrawPainter(
                  progress: _borderProgress.value,
                  color: widget.accentColor,
                  radius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorderDrawPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  _BorderDrawPainter(
      {required this.progress, required this.color, this.radius = 30});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));
    final metrics = path.computeMetrics().first;
    canvas.drawPath(metrics.extractPath(0, metrics.length * progress), paint);
  }

  @override
  bool shouldRepaint(_BorderDrawPainter old) => old.progress != progress;
}
