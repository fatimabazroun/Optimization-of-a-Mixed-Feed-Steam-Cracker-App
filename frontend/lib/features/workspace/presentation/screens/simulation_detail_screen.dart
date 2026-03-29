import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_button.dart';
import 'configure_simulation_screen.dart';

class SimulationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> scenario;
  const SimulationDetailScreen({super.key, required this.scenario});

  @override
  State<SimulationDetailScreen> createState() => _SimulationDetailScreenState();
}

class _SimulationDetailScreenState extends State<SimulationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final List<Map<String, String>> _variables = [
    {
      'title': 'Ethylene Yield',
      'definition': 'Mass fraction of ethylene produced relative to total feed input.',
      'matters': 'Primary product metric — directly impacts revenue and process efficiency.',
      'interpretation': 'Higher values indicate better cracking performance. Target >30% for ethane feed.',
    },
    {
      'title': 'Flash Temperature',
      'definition': 'Temperature at which the feed mixture undergoes phase separation in the flash drum.',
      'matters': 'Controls vapor-liquid equilibrium and feed composition entering the furnace.',
      'interpretation': 'Optimal range varies by feed type. Deviations affect yield distribution significantly.',
    },
    {
      'title': 'Flash Pressure',
      'definition': 'Operating pressure maintained in the flash separation unit.',
      'matters': 'Directly influences vapor fraction and component distribution in the feed.',
      'interpretation': 'Higher pressure increases liquid fraction. Must be balanced with downstream constraints.',
    },
    {
      'title': 'Fuel Duty',
      'definition': 'Total energy consumption of the cracking furnace in MW.',
      'matters': 'Key cost driver — fuel accounts for 60–70% of operating costs in steam cracking.',
      'interpretation': 'Lower values indicate better energy efficiency.',
    },
    {
      'title': 'CO₂ Emissions',
      'definition': 'Total CO₂ equivalent emitted per tonne of ethylene produced.',
      'matters': 'Critical for sustainability compliance and carbon credit calculations.',
      'interpretation': 'Values below regulatory threshold qualify for storage feasibility assessment.',
    },
    {
      'title': 'Hydrogen Recovery',
      'definition': 'Fraction of hydrogen in the cracked gas recovered as a product.',
      'matters': 'Hydrogen is a valuable by-product and can offset operating costs significantly.',
      'interpretation': 'Higher recovery rates improve overall process economics.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final Color accentColor = s['color'] as Color;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          const Text('Back to Workspace', style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ),

                  // Everything scrolls together
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['title'], style: AppTextStyles.heading1),
                          const SizedBox(height: 20),

                          // Schematic
                          Container(
                            width: double.infinity,
                            height: 180,
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: s['feedType'] == 'Ethane'
                                  ? Image.asset(
                                      'assets/images/Ethane-cracking.jpeg',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.schema_outlined, size: 48, color: accentColor.withOpacity(0.4)),
                                        const SizedBox(height: 8),
                                        Text('${s['feedType']} Cracking Schematic',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Input parameters
                          const Text('Input Parameters',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                          const SizedBox(height: 12),
                          _paramCard(Icons.category_outlined, 'Feed Type', s['feedType'], accentColor),
                          const SizedBox(height: 10),
                          _paramCard(Icons.thermostat_outlined, 'Temperature Range', s['tempRange'], accentColor),
                          const SizedBox(height: 10),
                          _paramCard(Icons.compress_outlined, 'Pressure Range', s['pressure'], accentColor),

                          const SizedBox(height: 24),

                          // Model description
                          const Text('Model Description',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                          const SizedBox(height: 10),
                          Text(
                            'Advanced simulation model for analyzing and optimizing ${s['title'].toLowerCase()} operations. '
                            'Evaluates ethylene yield, fuel duty, CO₂ emissions, and hydrogen recovery.',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6),
                          ),

                          const SizedBox(height: 24),

                          _GlowButton(
                            accentColor: accentColor,
                            onPressed: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    ConfigureSimulationScreen(scenario: s),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Output Variables — scroll down to see
                          const Text('Output Variables Explained',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                          const SizedBox(height: 16),

                          ..._variables.map((v) => Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.07),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['title']!,
                                          style: const TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                                      const SizedBox(height: 6),
                                      _richLine('Definition: ', v['definition']!),
                                      const SizedBox(height: 4),
                                      _richLine('Why it matters: ', v['matters']!),
                                      const SizedBox(height: 4),
                                      _richLine('Interpretation: ', v['interpretation']!),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paramCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBase)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _richLine(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyan)),
          TextSpan(text: value, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
        ],
      ),
    );
  }
}

class _GlowButton extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onPressed;

  const _GlowButton({required this.accentColor, required this.onPressed});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderProgress;
  late Animation<double> _glowRadius;
  late Animation<double> _fadeOut;
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Border draws from 0 to 1 in first 65%
    _borderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    // Glow grows as border draws
    _glowRadius = Tween<double>(begin: 6.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    // No fade — button stays visible throughout
    _fadeOut = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPressed();
        // Reset for next time
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
        builder: (_, __) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: Stack(
              children: [
                // Button fades out
                Opacity(
                  opacity: _fadeOut.value,
                  child: Container(
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Start Simulation', style: AppTextStyles.buttonText),
                      ],
                    ),
                  ),
                ),
                // Border draws ON TOP of button
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
          );
        },
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

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(30),
    );

    // Total perimeter
    final perimeter = 2 * (size.width + size.height);
    final drawn = perimeter * progress;

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().first;
    final drawPath = metrics.extractPath(0, drawn.clamp(0, metrics.length));

    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(_BorderDrawPainter old) => old.progress != progress;
}