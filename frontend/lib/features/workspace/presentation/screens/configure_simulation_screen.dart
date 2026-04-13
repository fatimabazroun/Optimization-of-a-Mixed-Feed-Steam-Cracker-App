import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'simulation_results_screen.dart';

class ConfigureSimulationScreen extends StatefulWidget {
  final Map<String, dynamic> scenario;
  const ConfigureSimulationScreen({super.key, required this.scenario});

  @override
  State<ConfigureSimulationScreen> createState() =>
      _ConfigureSimulationScreenState();
}

class _ConfigureSimulationScreenState extends State<ConfigureSimulationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;

  // Non-Ethane state only
  String? _selectedTemp;
  final _pressureController = TextEditingController();
  String _validPhase = 'Vapor-Only';

  // Rxn 1 dropdown (Ethane only)
  double _selectedRxn1 = 0.70;

  static const List<double> _rxn1Values = [
    0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.45, 0.40,
  ];

  bool get _isEthaneCracking => widget.scenario['feedType'] == 'Ethane';

  final List<Map<String, dynamic>> _reactions = [
    {'rxn': 1, 'component': 'ETHAN-01', 'stoichiometry': 'ETHAN-01 → HYDRO-01 + ETHYL-01', 'value': 0.70},
    {'rxn': 2, 'component': 'ETHAN-01', 'stoichiometry': '2 ETHAN-01 → PROPA-01 + METHA-01', 'value': 0.08},
    {'rxn': 3, 'component': 'PROPA-01', 'stoichiometry': 'PROPA-01 → PROPY-01 + HYDRO-01', 'value': 0.05},
    {'rxn': 4, 'component': 'PROPA-01', 'stoichiometry': 'PROPA-01 → METHA-01 + ETHYL-01', 'value': 0.05},
    {'rxn': 5, 'component': 'PROPY-01', 'stoichiometry': 'PROPY-01 → ACETY-01 + METHA-01', 'value': 0.04},
    {'rxn': 6, 'component': 'ETHYL-01', 'stoichiometry': 'ETHYL-01 + ACETY-01 → CYCLO-02', 'value': 0.03},
    {'rxn': 7, 'component': 'ETHAN-01', 'stoichiometry': '2 ETHAN-01 → 2 METHA-01 + ETHYL-01', 'value': 0.03},
    {'rxn': 8, 'component': 'ETHAN-01', 'stoichiometry': 'ETHAN-01 + ETHYL-01 → METHA-01 + PROPY-01', 'value': 0.02},
  ];


  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pressureController.dispose();
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
                        Text('Back to Overview', style: AppTextStyles.body),
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
                        const Text('Configure Simulation', style: AppTextStyles.heading1),
                        const SizedBox(height: 6),
                        const Text('Set input parameters for the simulation', style: AppTextStyles.body),
                        const SizedBox(height: 28),

                        // ── Operating Conditions ──
                        _sectionTitle('Operating Conditions'),
                        const SizedBox(height: 14),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Temperature
                              const Text('Temperature (°C)',
                                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                              const SizedBox(height: 10),
                              _isEthaneCracking
                                  ? _lockedField('850°C', accentColor)
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: ['850', '900', '1000'].map((t) {
                                          final selected = _selectedTemp == t;
                                          return GestureDetector(
                                            onTap: () => setState(() => _selectedTemp = t),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              margin: const EdgeInsets.only(right: 10),
                                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                              decoration: BoxDecoration(
                                                gradient: selected
                                                    ? LinearGradient(
                                                        colors: [accentColor, AppColors.primaryBlue],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      )
                                                    : null,
                                                color: selected ? null : AppColors.inputBg,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: selected ? Colors.transparent : AppColors.inputBorder,
                                                ),
                                                boxShadow: selected
                                                    ? [BoxShadow(
                                                        color: accentColor.withOpacity(0.35),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 4),
                                                      )]
                                                    : [],
                                              ),
                                              child: Text('$t°C',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: selected ? Colors.white : AppColors.textMedium,
                                                  )),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                              const SizedBox(height: 20),

                              // Pressure
                              const Text('Pressure (bar)',
                                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                              const SizedBox(height: 8),
                              _isEthaneCracking
                                  ? _lockedField('1.5 bar', accentColor)
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _pressureController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.darkBase,
                                            ),
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            validator: (val) {
                                              if (val == null || val.isEmpty) return 'Pressure is required';
                                              final p = double.tryParse(val);
                                              if (p == null) return 'Enter a valid number';
                                              if (p < 0.5 || p > 10) return 'Range: 0.5 – 10 bar';
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              hintText: '0.5 – 10 bar',
                                              filled: true,
                                              fillColor: AppColors.inputBg,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: accentColor, width: 1.5),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                              ),
                                              focusedErrorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: AppColors.inputBg,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.inputBorder),
                                          ),
                                          child: const Text('bar',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textMedium,
                                                fontWeight: FontWeight.w600,
                                              )),
                                        ),
                                      ],
                                    ),

                              const SizedBox(height: 20),

                              // Valid phases
                              const Text('Valid Phases',
                                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.inputBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _validPhase,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textLight),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.darkBase,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: ['Vapor-Only', 'Liquid-Only', 'Vapor-Liquid']
                                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _validPhase = val!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Reactions ──
                        _sectionTitle('Reactions'),
                        const SizedBox(height: 14),

                        _sectionCard(
                          child: Column(
                            children: _reactions.asMap().entries.map((entry) {
                              final i = entry.key;
                              final r = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  children: [
                                    // Rxn 1 in Ethane mode → image dropdown
                                    if (i == 0 && _isEthaneCracking)
                                      _rxn1DropdownRow(r, accentColor)
                                    else
                                      Row(
                                        children: [
                                          _rxnBadge(r['rxn'] as int, accentColor),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(r['component'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.darkBase,
                                                    )),
                                                Text(r['stoichiometry'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.textLight,
                                                    )),
                                              ],
                                            ),
                                          ),
                                          _isEthaneCracking
                                              ? _readOnlyFraction(r['value'] as double, accentColor)
                                              : SizedBox(
                                                  width: 70,
                                                  child: TextFormField(
                                                    initialValue: (r['value'] as double).toStringAsFixed(2),
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: accentColor,
                                                    ),
                                                    decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: accentColor.withOpacity(0.08),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                    ),
                                                    onChanged: (val) {
                                                      final parsed = double.tryParse(val);
                                                      if (parsed != null) {
                                                        setState(() => _reactions[i]['value'] = parsed);
                                                      }
                                                    },
                                                  ),
                                                ),
                                        ],
                                      ),
                                    if (i < _reactions.length - 1)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 12),
                                        child: Divider(color: AppColors.inputBorder, height: 1),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 32),

                        _GlowButton(
                          text: 'Execute Simulation',
                          icon: Icons.play_circle_outline_rounded,
                          accentColor: accentColor,
                          onPressed: () {
                            if (!_isEthaneCracking) {
                              if (_selectedTemp == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please select a temperature.'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              if (_pressureController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter a pressure value.'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              final p = double.tryParse(_pressureController.text);
                              if (p == null || p < 0.5 || p > 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Pressure must be between 0.5 – 10 bar.'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                            }
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => SimulationResultsScreen(
                                  scenario: widget.scenario,
                                  temperature: _isEthaneCracking ? '850' : _selectedTemp!,
                                  pressure: _isEthaneCracking ? '1.5' : _pressureController.text,
                                ),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
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

  // ── Locked display (temperature / pressure) ──────────────────────────────
  Widget _lockedField(String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.textLight),
          const SizedBox(width: 10),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentColor,
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Fixed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                )),
          ),
        ],
      ),
    );
  }

  // ── Read-only fraction chip ───────────────────────────────────────────────
  Widget _readOnlyFraction(double value, Color accentColor) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  // ── Rxn number badge ──────────────────────────────────────────────────────
  Widget _rxnBadge(int rxn, Color accentColor) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text('$rxn',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
            )),
      ),
    );
  }

  // ── Rxn 1 numeric dropdown row (Ethane only) ─────────────────────────────
  Widget _rxn1DropdownRow(Map<String, dynamic> r, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _rxnBadge(1, accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['component'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBase,
                      )),
                  Text(r['stoichiometry'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      )),
                ],
              ),
            ),
            // Numeric dropdown for Rxn 1 fraction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _selectedRxn1,
                  isDense: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 16),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                  items: _rxn1Values.map((v) {
                    return DropdownMenuItem<double>(
                      value: v,
                      child: Text(v.toStringAsFixed(2)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRxn1 = val;
                        _reactions[0]['value'] = val;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.darkBase,
        ));
  }

  Widget _sectionCard({required Widget child}) {
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
      child: child,
    );
  }
}

class _GlowButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;

  const _GlowButton({
    required this.text,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
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
      duration: const Duration(milliseconds: 900),
    );
    _borderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeInOut)),
    );
    _glowRadius = Tween<double>(begin: 6.0, end: 30.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPressed();
        Future.delayed(const Duration(milliseconds: 300), () {
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
        builder: (_, __) => SizedBox(
          width: double.infinity,
          height: 52,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.accentColor, AppColors.primaryBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.55),
                      blurRadius: _glowRadius.value,
                      spreadRadius: _glowRadius.value * 0.2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.text, style: AppTextStyles.buttonText),
                  ],
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _BorderDrawPainter(
                    progress: _borderProgress.value,
                    color: widget.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorderDrawPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BorderDrawPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(30),
    ));
    final metrics = path.computeMetrics().first;
    canvas.drawPath(metrics.extractPath(0, metrics.length * progress), paint);
  }

  @override
  bool shouldRepaint(_BorderDrawPainter old) => old.progress != progress;
}
