import 'package:flutter/material.dart';
import 'main_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/scenario_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/report_service.dart';

class SimulationResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final String temperature;
  final String pressure;

  const SimulationResultsScreen({
    super.key,
    required this.scenario,
    required this.temperature,
    required this.pressure,
  });

  @override
  State<SimulationResultsScreen> createState() => _SimulationResultsScreenState();
}

class _SimulationResultsScreenState extends State<SimulationResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Performance', 'Trends', 'Recommendation'];

  // Determine status and KPI values based on temp & pressure
  late final Map<String, dynamic> _results;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _results = _computeResults();
  }

  Map<String, dynamic> _computeResults() {
    final temp = double.tryParse(widget.temperature) ?? 850;
    final pressure = double.tryParse(widget.pressure) ?? 1.5;

    // Estimated cracking KPIs
    final ethyleneYield = temp >= 820 && temp <= 880 ? 32.5 : temp >= 900 ? 24.1 : 15.3;
    final co2Emissions  = pressure <= 1.5 ? 388.0 : pressure <= 4 ? 432.0 : 510.0;
    final fuelDuty      = temp >= 820 ? 12.4 : 8.9;
    final h2Recovery    = temp >= 820 && temp <= 880 ? 78.5 : 61.2;

    // Cracking overview KPIs (placeholder — replace with backend values)
    final furnaceReduction = temp >= 820 && temp <= 880 ? 18.3 : temp >= 900 ? 12.7 : 7.4; // %
    final cost             = pressure <= 1.5 ? 142.0 : pressure <= 4 ? 167.0 : 198.0;       // $/tonne
    final hydrogenPurity   = temp >= 820 && temp <= 880 ? 94.2 : temp >= 900 ? 88.6 : 79.1; // %

    // ── PETE outputs (placeholder — replace with backend values) ──
    const double maxInjectionTime    = 18.5;   // years
    const double pressureAtEnd       = 28.4;   // MPa
    const double maxSustainableRate  = 1850.0; // kg/hr
    const double plumeRadius         = 2340.0; // m

    // Feasibility classification
    // Feasible: injection time covers full project duration (assume 20 yr default)
    // Conditional: some capacity but not full duration
    // Infeasible: cannot safely inject
    const String feasibility = 'Feasible'; // swap with backend result
    const Color  feasibilityColor = Color(0xFF2ECC71);
    const IconData feasibilityIcon = Icons.check_circle_outline;
    const String feasibilityMessage = 'Reservoir can sustain the required CO₂ rate for the full project duration without exceeding pressure limits.';

    return {
      'overallStatus':       feasibility,
      'overallColor':        feasibilityColor,
      'overallIcon':         feasibilityIcon,
      // PETE
      'feasibility':         feasibility,
      'feasibilityColor':    feasibilityColor,
      'feasibilityIcon':     feasibilityIcon,
      'feasibilityMessage':  feasibilityMessage,
      'maxInjectionTime':    maxInjectionTime,
      'pressureAtEnd':       pressureAtEnd,
      'maxSustainableRate':  maxSustainableRate,
      'plumeRadius':         plumeRadius,
      // Cracking KPIs
      'ethyleneYield':    ethyleneYield,
      'co2Emissions':     co2Emissions,
      'fuelDuty':         fuelDuty,
      'h2Recovery':       h2Recovery,
      'furnaceReduction': furnaceReduction,
      'cost':             cost,
      'hydrogenPurity':   hydrogenPurity,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textMedium),
                        SizedBox(width: 4),
                        Text('Back to Configuration', style: AppTextStyles.body),
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
                        const Text('Simulation Results', style: AppTextStyles.heading1),
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
                                  onTap: () => setState(() => _selectedTab = e.key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: selected
                                          ? LinearGradient(
                                              colors: [accentColor, AppColors.primaryBlue],
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
                                          color: selected ? Colors.white : AppColors.textLight,
                                        )),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tab content
                        if (_selectedTab == 0) _buildOverview(),
                        if (_selectedTab == 1) _buildPerformance(accentColor),
                        if (_selectedTab == 2) _buildTrends(accentColor),
                        if (_selectedTab == 3) _buildRecommendation(accentColor),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(child: _GlowActionButton(icon: Icons.bookmark_outline, label: 'Save', accentColor: accentColor, onTap: () => _showSaveDialog(context, accentColor))),
                            const SizedBox(width: 12),
                            Expanded(child: _GlowActionButton(icon: Icons.download_outlined, label: 'Report', accentColor: accentColor, onTap: () => _generateReport(context))),
                            const SizedBox(width: 12),
                            Expanded(child: _GlowActionButton(icon: Icons.refresh_rounded, label: 'Recalculate', accentColor: accentColor, onTap: () => Navigator.pop(context))),
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

  Widget _buildOverview() {
    final feasColor  = _results['feasibilityColor'] as Color;
    final feasIcon   = _results['feasibilityIcon'] as IconData;
    final feasLabel  = _results['feasibility'] as String;
    final feasMsg    = _results['feasibilityMessage'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Feasibility Result (most important) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: feasColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: feasColor.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [BoxShadow(color: feasColor.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: feasColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('MOST IMPORTANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(feasIcon, color: feasColor, size: 28),
                  const SizedBox(width: 12),
                  Text('Feasibility Result',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                ],
              ),
              const SizedBox(height: 6),
              Text(feasLabel,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: feasColor)),
              const SizedBox(height: 8),
              Text(feasMsg,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 2–5. Metric cards in 2×2 grid ──
        Row(
          children: [
            Expanded(child: _peteMetricCard(
              label: 'Max Safe\nInjection Time',
              value: (_results['maxInjectionTime'] as double).toStringAsFixed(1),
              unit: 'years',
              icon: Icons.timer_outlined,
              description: 'How long we can inject before reaching the pressure limit.',
              color: AppColors.cyan,
            )),
            const SizedBox(width: 12),
            Expanded(child: _peteMetricCard(
              label: 'Pressure at\nProject End',
              value: (_results['pressureAtEnd'] as double).toStringAsFixed(1),
              unit: 'MPa',
              icon: Icons.compress_outlined,
              description: 'Reservoir pressure at the end of the full project duration.',
              color: AppColors.purple,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _peteMetricCard(
              label: 'Max Sustainable\nInjection Rate',
              value: (_results['maxSustainableRate'] as double).toStringAsFixed(0),
              unit: 'kg/hr',
              icon: Icons.speed_outlined,
              description: 'Maximum CO₂ rate the reservoir can handle safely.',
              color: AppColors.midTone,
            )),
            const SizedBox(width: 12),
            Expanded(child: _peteMetricCard(
              label: 'Plume\nRadius',
              value: (_results['plumeRadius'] as double).toStringAsFixed(0),
              unit: 'm',
              icon: Icons.radar_outlined,
              description: 'How large the CO₂ plume becomes by end of project.',
              color: const Color(0xFF2ECC71),
            )),
          ],
        ),

        const SizedBox(height: 20),
        const Text('Cracking Performance',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _peteMetricCard(
              label: 'Ethylene\nYield',
              value: (_results['ethyleneYield'] as double).toStringAsFixed(1),
              unit: '%',
              icon: Icons.bubble_chart_outlined,
              description: 'Mass fraction of ethylene produced relative to total feed.',
              color: AppColors.cyan,
            )),
            const SizedBox(width: 12),
            Expanded(child: _peteMetricCard(
              label: 'Furnace\nReduction',
              value: (_results['furnaceReduction'] as double).toStringAsFixed(1),
              unit: '%',
              icon: Icons.local_fire_department_outlined,
              description: 'Reduction in furnace fuel duty vs baseline operation.',
              color: Colors.orange,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _peteMetricCard(
              label: 'Operating\nCost',
              value: (_results['cost'] as double).toStringAsFixed(0),
              unit: '\$/t',
              icon: Icons.attach_money_outlined,
              description: 'Estimated operating cost per tonne of ethylene produced.',
              color: AppColors.purple,
            )),
            const SizedBox(width: 12),
            Expanded(child: _peteMetricCard(
              label: 'Hydrogen\nPurity',
              value: (_results['hydrogenPurity'] as double).toStringAsFixed(1),
              unit: '%',
              icon: Icons.science_outlined,
              description: 'Purity of recovered hydrogen as a by-product stream.',
              color: AppColors.midTone,
            )),
          ],
        ),
      ],
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
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 10, color: AppColors.textLight, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildPerformance(Color accentColor) {
    return Column(
      children: [
        _chartPlaceholder(
          title: 'Pressure vs Time',
          description: 'Shows how reservoir pressure increases over time and where it hits the allowable limit.',
          icon: Icons.show_chart_rounded,
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),
        _chartPlaceholder(
          title: 'Plume Radius vs Time',
          description: 'Shows how the CO₂ plume spreads in the reservoir over the project duration.',
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
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
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
                  Icon(Icons.insert_chart_outlined_rounded, size: 36, color: accentColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('Chart coming soon', style: TextStyle(fontSize: 12, color: accentColor.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRecommendation(Color accentColor) {
    final feasibility = _results['feasibility'] as String;
    final feasColor   = _results['feasibilityColor'] as Color;

    final List<Map<String, dynamic>> items;
    if (feasibility == 'Feasible') {
      items = [
        {'icon': Icons.check_circle_outline, 'color': const Color(0xFF2ECC71), 'title': 'Proceed with injection', 'body': 'The reservoir can sustain the required CO₂ rate for the full project duration. No adjustments needed.'},
        {'icon': Icons.monitor_heart_outlined, 'color': AppColors.cyan, 'title': 'Monitor reservoir pressure', 'body': 'Although feasible, continuous pressure monitoring is recommended to detect any unexpected behaviour early.'},
        {'icon': Icons.water_drop_outlined, 'color': AppColors.midTone, 'title': 'Track plume migration', 'body': 'Periodic seismic surveys are advised to confirm the CO₂ plume stays within the modelled radius.'},
      ];
    } else if (feasibility == 'Conditional') {
      items = [
        {'icon': Icons.warning_amber_outlined, 'color': Colors.orange, 'title': 'Reduce injection rate', 'body': 'The reservoir can handle some injection but not for the full project duration. Consider reducing the CO₂ rate or phasing injection.'},
        {'icon': Icons.hourglass_top_outlined, 'color': Colors.orange, 'title': 'Shorten project duration', 'body': 'Adjusting the project timeline to match the maximum safe injection time can make this scenario viable.'},
        {'icon': Icons.add_location_alt_outlined, 'color': AppColors.cyan, 'title': 'Consider additional wells', 'body': 'Distributing the CO₂ load across more injection wells can extend the safe injection window.'},
      ];
    } else {
      items = [
        {'icon': Icons.cancel_outlined, 'color': Colors.red, 'title': 'Injection not recommended', 'body': 'The reservoir cannot safely handle the required CO₂ rate. Exceeding pressure limits risks fracturing and containment failure.'},
        {'icon': Icons.search_outlined, 'color': AppColors.purple, 'title': 'Re-evaluate reservoir selection', 'body': 'Consider reservoirs with higher permeability, greater thickness, or lower initial pressure for safer storage.'},
        {'icon': Icons.tune_outlined, 'color': AppColors.midTone, 'title': 'Revisit input parameters', 'body': 'Review CO₂ rate, number of wells, and fracture pressure estimates — small adjustments may shift the feasibility outcome.'},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Feasibility summary chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: feasColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: feasColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(_results['feasibilityIcon'] as IconData, color: feasColor, size: 18),
              const SizedBox(width: 10),
              Text('Result: $feasibility',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: feasColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                    const SizedBox(height: 4),
                    Text(item['body'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTrends(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trend Analysis',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
          const SizedBox(height: 16),
          _trendRow('Ethylene Yield', _results['ethyleneYield'] / 40, accentColor),
          const SizedBox(height: 12),
          _trendRow('H₂ Recovery', _results['h2Recovery'] / 100, AppColors.cyan),
          const SizedBox(height: 12),
          _trendRow('CO₂ Efficiency', (1 - (_results['co2Emissions'] as double) / 600).toDouble(), Colors.orange),
          const SizedBox(height: 12),
          _trendRow('Fuel Efficiency', (1 - (_results['fuelDuty'] as double) / 20).toDouble(), AppColors.purple),
        ],
      ),
    );
  }

  Widget _trendRow(String label, double value, Color color) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            Text('${(clamped * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }




  Future<void> _generateReport(BuildContext context) async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Generating PDF report…'),
          ],
        ),
        backgroundColor: AppColors.cyan,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final attrs = await AuthService.fetchUserAttributes();
      await ReportService.generateAndShare(
        scenarioTitle: widget.scenario['title'] as String,
        feedType: widget.scenario['feedType'] as String? ?? '',
        temperature: widget.temperature,
        pressure: widget.pressure,
        overallStatus: _results['overallStatus'] as String,
        tempStatus: _results['feasibility'] as String,
        tempMessage: _results['feasibilityMessage'] as String,
        pressureStatus: _results['feasibility'] as String,
        pressureMessage: _results['feasibilityMessage'] as String,
        ethyleneYield: _results['ethyleneYield'] as double,
        co2Emissions: _results['co2Emissions'] as double,
        fuelDuty: _results['fuelDuty'] as double,
        h2Recovery: _results['h2Recovery'] as double,
        userName: attrs['name'] ?? '',
        userEmail: attrs['email'] ?? '',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to generate report. Please try again.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSaveDialog(BuildContext context, Color accentColor) {
    final nameController = TextEditingController(
      text: '${widget.scenario['title']} – ${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Save Scenario',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkBase)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _saveScenario(BuildContext context, String name) async {
    try {
      final now = DateTime.now();
      final simId = 'SIM-${now.year}-${now.millisecondsSinceEpoch % 10000}';
      final date = '${_monthName(now.month)} ${now.day}, ${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await ScenarioService.addScenario({
        'name': name,
        'date': date,
        'simId': simId,
        'status': _results['overallStatus'].toString().contains('Optimal') ? 'Optimal'
            : _results['overallStatus'].toString().contains('Warning') ? 'Warning' : 'Critical',
        'temperature': widget.temperature,
        'pressure': widget.pressure,
        'scenario': widget.scenario['title'],
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Scenario saved successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'View Saved',
            textColor: Colors.white,
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const MainShell(initialIndex: 0),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 400),
              ),
              (route) => false,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Error in Saving Scenario'),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeInOut)),
    );
    _glowRadius = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
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
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
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

  _BorderDrawPainter({required this.progress, required this.color, this.radius = 30});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));
    final metrics = path.computeMetrics().first;
    canvas.drawPath(metrics.extractPath(0, metrics.length * progress), paint);
  }

  @override
  bool shouldRepaint(_BorderDrawPainter old) => old.progress != progress;
}