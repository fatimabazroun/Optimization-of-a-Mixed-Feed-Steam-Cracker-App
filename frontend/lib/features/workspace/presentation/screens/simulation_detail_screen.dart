import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
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
      body: AppBackground(
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
                          Icon(Icons.arrow_back_ios, size: 16, color: context.textSecondary),
                          SizedBox(width: 4),
                          Text('Back to Workspace', style: TextStyle(fontSize: 14, color: context.textSecondary)),
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
                          // Scenario badge + title
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s['scenarioNumber'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(s['title'] as String, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.2)),
                          SizedBox(height: 6),
                          Text(s['tagline'] as String,
                              style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.5)),
                          SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: context.cardShadow,
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: s['schematic'] != null
                                ? Image.asset(
                                    s['schematic'] as String,
                                    fit: BoxFit.contain,
                                  )
                                : SizedBox(
                                    height: 180,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_outlined, size: 40, color: accentColor.withValues(alpha: 0.35)),
                                        SizedBox(height: 8),
                                        Text(
                                          '${s['scenarioNumber']} — Schematic',
                                          style: TextStyle(fontSize: 12, color: context.textTertiary),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),

                          SizedBox(height: 24),

                          // Scenario info cards
                          Text('Scenario Overview',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                          SizedBox(height: 12),
                          _paramCard(Icons.description_outlined, 'Description', s['description'] as String, accentColor),
                          SizedBox(height: 10),
                          _paramCard(Icons.science_outlined, 'Reaction Basis', s['reactionBasis'] as String, accentColor),

                          SizedBox(height: 24),

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

                          SizedBox(height: 32),

                          Text('Output Variables Explained',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                          SizedBox(height: 16),

                          ..._variables.map((v) => Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: context.cardShadow,
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
                                    color: AppColors.cyan.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v['title']!,
                                          style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                                      SizedBox(height: 6),
                                      _richLine('Definition: ', v['definition']!),
                                      SizedBox(height: 4),
                                      _richLine('Why it matters: ', v['matters']!),
                                      SizedBox(height: 4),
                                      _richLine('Interpretation: ', v['interpretation']!),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                          SizedBox(height: 32),
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

  Widget _richLine(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyan)),
          TextSpan(text: value, style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _paramCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: context.textTertiary)),
                SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary, height: 1.4)),
              ],
            ),
          ),
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
  AnimationController? _ctrl;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 600),
    );
    _ctrl!.addListener(() {
      setState(() => _scale = 1.0 - (_ctrl!.value * 0.07));
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _handleTap() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    ctrl.forward(from: 0.0).then((_) {
      if (!mounted) return;
      widget.onPressed();
      ctrl.animateBack(0.0, curve: Curves.elasticOut);
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
                color: widget.accentColor.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline_rounded, color: context.surface, size: 20),
              SizedBox(width: 8),
              Text('Start Simulation', style: AppTextStyles.buttonText),
            ],
          ),
        ),
      ),
    );
  }
}