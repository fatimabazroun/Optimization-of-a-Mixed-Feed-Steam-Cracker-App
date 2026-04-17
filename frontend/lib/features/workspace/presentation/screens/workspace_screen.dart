import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/simulation_card.dart';
import 'simulation_detail_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  final List<Map<String, dynamic>> _scenarios = [
    {
      'scenarioNumber': 'Scenario 1',
      'title': 'Base Reaction',
      'tagline': 'Evaluate main ethane cracking performance.',
      'description':
          'Based on modifying the fractional conversion of the main feed component (ETHAN-01) in the reactor.',
      'reactionBasis': 'Primary cracking reaction of ethane only.',
      'icon': Icons.bubble_chart_outlined,
      'color': AppColors.cyan,
    },
    {
      'scenarioNumber': 'Scenario 2',
      'title': 'Multi-Reaction',
      'tagline': 'Analyze effect of side reactions and byproducts.',
      'description':
          'Based on modifying the fractional conversion of multiple reactions involving the main feed (ETHAN-01) instead of only the primary reaction.',
      'reactionBasis': 'Primary and secondary cracking reactions.',
      'icon': Icons.account_tree_outlined,
      'color': AppColors.purple,
    },
    {
      'scenarioNumber': 'Scenario 3',
      'title': 'Full Network',
      'tagline': 'Simulate complete reaction network with intermediates.',
      'description':
          'Involves modifying the fractional conversion of all key reactions in the system, including primary, secondary, and reactions involving propylene (PROPY-01) and other intermediates.',
      'reactionBasis': 'Complete reaction network.',
      'icon': Icons.hub_outlined,
      'color': AppColors.midTone,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimations = List.generate(3, (i) {
      final start = i * 0.2;
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + 0.6, curve: Curves.easeOutCubic),
      ));
    });
    _fadeAnimations = List.generate(3, (i) {
      final start = i * 0.2;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.6, curve: Curves.easeIn),
        ),
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openScenario(Map<String, dynamic> scenario) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SimulationDetailScreen(scenario: scenario),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                const Text('Workspace', style: AppTextStyles.heading1),
                const SizedBox(height: 6),
                const Text('Select a scenario to begin your simulation', style: AppTextStyles.body),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.builder(
                    itemCount: _scenarios.length,
                    itemBuilder: (context, i) {
                      return FadeTransition(
                        opacity: _fadeAnimations[i],
                        child: SlideTransition(
                          position: _slideAnimations[i],
                          child: SimulationCard(
                            scenarioNumber: _scenarios[i]['scenarioNumber'],
                            title: _scenarios[i]['title'],
                            tagline: _scenarios[i]['tagline'],
                            reactionBasis: _scenarios[i]['reactionBasis'],
                            icon: _scenarios[i]['icon'],
                            iconColor: _scenarios[i]['color'],
                            onTap: () => _openScenario(_scenarios[i]),
                          ),
                        ),
                      );
                    },
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