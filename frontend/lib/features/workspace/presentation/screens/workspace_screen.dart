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
      'title': 'Ethane Cracking',
      'description': 'High ethylene yield with pure ethane feed. Optimized for maximum olefin production.',
      'icon': Icons.bubble_chart_outlined,
      'color': AppColors.cyan,
      'feedType': 'Ethane',
      'tempRange': '800°C – 860°C',
      'pressure': '1.7 – 2.0 bar',
    },
    {
      'title': 'Naphtha Cracking',
      'description': 'Mixed product slate with naphtha feed. Balanced ethylene and propylene output.',
      'icon': Icons.thermostat_outlined,
      'color': AppColors.purple,
      'feedType': 'Naphtha',
      'tempRange': '820°C – 880°C',
      'pressure': '1.5 – 1.8 bar',
    },
    {
      'title': 'Mixed Feed Cracking',
      'description': 'Flexible feed combining ethane and naphtha for optimal trade-offs.',
      'icon': Icons.merge_type_outlined,
      'color': AppColors.midTone,
      'feedType': 'Mixed (Ethane + Naphtha)',
      'tempRange': '810°C – 870°C',
      'pressure': '1.6 – 1.9 bar',
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
                const Text('Select a simulation model to begin', style: AppTextStyles.body),
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
                            title: _scenarios[i]['title'],
                            description: _scenarios[i]['description'],
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