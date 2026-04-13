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
  final List<String> _tabs = ['Overview', 'Performance', 'Trends'];

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

    // Temperature classification
    String tempStatus;
    String tempMessage;
    Color tempColor;
    if (temp >= 650 && temp <= 720) {
      tempStatus = 'No Cracking';
      tempMessage = 'Ethane remains mostly unreacted.';
      tempColor = Colors.red;
    } else if (temp >= 750 && temp <= 800) {
      tempStatus = 'Initial Cracking';
      tempMessage = 'Small amounts of ethylene and hydrogen forming.';
      tempColor = Colors.orange;
    } else if (temp >= 820 && temp <= 880) {
      tempStatus = 'Optimal';
      tempMessage = 'High ethylene production and stable reactor operation.';
      tempColor = const Color(0xFF2ECC71);
    } else if (temp >= 900 && temp <= 1000) {
      tempStatus = 'Over-Cracking';
      tempMessage = 'Secondary reactions increasing methane, hydrogen, acetylene.';
      tempColor = Colors.orange;
    } else {
      tempStatus = 'Out of Range';
      tempMessage = 'Temperature outside known operating scenarios.';
      tempColor = Colors.red;
    }

    // Pressure classification
    String pressureStatus;
    String pressureMessage;
    Color pressureColor;
    if (pressure >= 0.5 && pressure <= 1.5) {
      pressureStatus = 'Optimal';
      pressureMessage = 'Highest ethylene yield expected.';
      pressureColor = const Color(0xFF2ECC71);
    } else if (pressure >= 2 && pressure <= 4) {
      pressureStatus = 'Warning';
      pressureMessage = 'Cracking efficiency decreases; more recombination reactions.';
      pressureColor = Colors.orange;
    } else if (pressure >= 5 && pressure <= 10) {
      pressureStatus = 'Suppressed';
      pressureMessage = 'Cracking suppressed; heavier hydrocarbons favored.';
      pressureColor = Colors.red;
    } else {
      pressureStatus = 'Out of Range';
      pressureMessage = 'Pressure outside known operating scenarios.';
      pressureColor = Colors.red;
    }

    // Overall status
    final hasWarning = tempStatus != 'Optimal' || pressureStatus != 'Optimal';
    final hasCritical = tempStatus == 'No Cracking' || pressureStatus == 'Suppressed';
    String overallStatus;
    Color overallColor;
    IconData overallIcon;
    if (hasCritical) {
      overallStatus = 'Critical Conditions';
      overallColor = Colors.red;
      overallIcon = Icons.cancel_outlined;
    } else if (hasWarning) {
      overallStatus = 'Operating With Warnings';
      overallColor = Colors.orange;
      overallIcon = Icons.warning_amber_outlined;
    } else {
      overallStatus = 'Optimal Operation';
      overallColor = const Color(0xFF2ECC71);
      overallIcon = Icons.check_circle_outline;
    }

    // Estimated KPIs (simplified model)
    final ethyleneYield = temp >= 820 && temp <= 880 ? 32.5 : temp >= 900 ? 24.1 : 15.3;
    final co2Emissions = pressure <= 1.5 ? 388.0 : pressure <= 4 ? 432.0 : 510.0;
    final fuelDuty = temp >= 820 ? 12.4 : 8.9;
    final h2Recovery = temp >= 820 && temp <= 880 ? 78.5 : 61.2;

    return {
      'overallStatus': overallStatus,
      'overallColor': overallColor,
      'overallIcon': overallIcon,
      'tempStatus': tempStatus,
      'tempMessage': tempMessage,
      'tempColor': tempColor,
      'pressureStatus': pressureStatus,
      'pressureMessage': pressureMessage,
      'pressureColor': pressureColor,
      'ethyleneYield': ethyleneYield,
      'co2Emissions': co2Emissions,
      'fuelDuty': fuelDuty,
      'h2Recovery': h2Recovery,
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
    final overallColor = _results['overallColor'] as Color;

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
                        const SizedBox(height: 16),

                        // Status banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: overallColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: overallColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(_results['overallIcon'] as IconData,
                                  color: overallColor, size: 22),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_results['overallStatus'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: overallColor,
                                      )),
                                  Text(
                                    'T: ${widget.temperature}°C  •  P: ${widget.pressure} bar',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tabs
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: _tabs.asMap().entries.map((e) {
                              final selected = _selectedTab == e.key;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = e.key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selected ? Colors.white : AppColors.textLight,
                                        )),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tab content
                        if (_selectedTab == 0) _buildOverview(),
                        if (_selectedTab == 1) _buildPerformance(accentColor),
                        if (_selectedTab == 2) _buildTrends(accentColor),

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
    return Column(
      children: [
        _kpiCard(
          label: 'OUTLET TEMPERATURE',
          value: widget.temperature,
          unit: '°C',
          status: _results['tempStatus'],
          message: _results['tempMessage'],
          color: _results['tempColor'],
        ),
        const SizedBox(height: 14),
        _kpiCard(
          label: 'OUTLET PRESSURE',
          value: widget.pressure,
          unit: 'bar',
          status: _results['pressureStatus'],
          message: _results['pressureMessage'],
          color: _results['pressureColor'],
        ),
        const SizedBox(height: 14),
        _kpiCard(
          label: 'CO₂ EMISSIONS',
          value: _results['co2Emissions'].toStringAsFixed(0),
          unit: 'kg/h',
          status: _results['pressureStatus'] == 'Optimal' ? 'Within Limits' : 'Warning',
          message: 'CO₂ output based on operating pressure.',
          color: _results['pressureColor'],
        ),
      ],
    );
  }

  Widget _buildPerformance(Color accentColor) {
    return Container(
      height: 220,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: accentColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Performance Charts', style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          )),
          const SizedBox(height: 8),
          const Text('Coming soon', style: TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
          )),
        ],
      ),
    );
  }

  Widget _buildTrends(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
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
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String unit,
    required String status,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBase,
                  )),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                color == const Color(0xFF2ECC71)
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                color: color,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(message,
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.7,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color.withOpacity(0.5)),
              minHeight: 4,
            ),
          ),
        ],
      ),
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
        tempStatus: _results['tempStatus'] as String,
        tempMessage: _results['tempMessage'] as String,
        pressureStatus: _results['pressureStatus'] as String,
        pressureMessage: _results['pressureMessage'] as String,
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
                    color: widget.accentColor.withOpacity(0.45),
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
      ..color = Colors.white.withOpacity(0.9)
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