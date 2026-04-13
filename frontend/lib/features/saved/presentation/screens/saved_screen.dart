import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/scenario_service.dart';
import '../../../workspace/presentation/screens/simulation_results_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Optimal', 'Warning', 'Critical'];
  List<Map<String, dynamic>> _scenarios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ScenarioService.loadScenarios();
    if (mounted) {
      setState(() {
        _scenarios = list;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _scenarios;
    return _scenarios.where((s) => s['status'] == _filter).toList();
  }

  void _confirmDelete(int realIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Scenario',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkBase)),
        content: Text(
          'Are you sure you want to delete "${_scenarios[realIndex]['name']}"?',
          style: const TextStyle(color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ScenarioService.deleteScenario(realIndex);
              await _load();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                const Text('Saved Scenarios', style: AppTextStyles.heading1),
                const SizedBox(height: 6),
                const Text('Review and manage your previous simulations',
                    style: AppTextStyles.body),
                const SizedBox(height: 20),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: AppColors.textLight, size: 18),
                      const SizedBox(width: 10),
                      ..._filters.map((f) {
                        final selected = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.cyan : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? AppColors.cyan : AppColors.inputBorder,
                              ),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : AppColors.textMedium,
                                )),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // List
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.cyan, strokeWidth: 2),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bookmark_outline,
                                      size: 64, color: AppColors.highlight),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filter == 'All'
                                        ? 'No saved scenarios yet'
                                        : 'No $_filter scenarios',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Run a simulation to save results here',
                                      style: AppTextStyles.body),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.cyan,
                              onRefresh: _load,
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  final s = _filtered[i];
                                  final realIndex = _scenarios.indexOf(s);
                                  return _scenarioCard(s, realIndex);
                                },
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

  // Maps saved scenario title back to the full scenario data needed by SimulationResultsScreen
  static const _scenarioMeta = {
    'Ethane Cracking': {
      'title': 'Ethane Cracking',
      'feedType': 'Ethane',
      'color': AppColors.cyan,
      'tempRange': '800°C – 860°C',
      'pressure': '1.7 – 2.0 bar',
    },
    'Naphtha Cracking': {
      'title': 'Naphtha Cracking',
      'feedType': 'Naphtha',
      'color': AppColors.purple,
      'tempRange': '820°C – 880°C',
      'pressure': '1.5 – 1.8 bar',
    },
    'Mixed Feed Cracking': {
      'title': 'Mixed Feed Cracking',
      'feedType': 'Mixed (Ethane + Naphtha)',
      'color': AppColors.midTone,
      'tempRange': '810°C – 870°C',
      'pressure': '1.6 – 1.9 bar',
    },
  };

  void _openSavedScenario(Map<String, dynamic> s) {
    final scenarioTitle = s['scenario'] as String;
    final scenarioData = Map<String, dynamic>.from(
      _scenarioMeta[scenarioTitle] ?? {
        'title': scenarioTitle,
        'feedType': 'Unknown',
        'color': AppColors.cyan,
        'tempRange': 'N/A',
        'pressure': 'N/A',
      },
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SimulationResultsScreen(
          scenario: scenarioData,
          temperature: s['temperature'] as String,
          pressure: s['pressure'] as String,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _scenarioCard(Map<String, dynamic> s, int index) {
    final status = s['status'] as String;
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Optimal':
        statusColor = const Color(0xFF2ECC71);
        statusIcon = Icons.trending_up_rounded;
        break;
      case 'Warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.trending_down_rounded;
    }

    return GestureDetector(
      onTap: () => _openSavedScenario(s),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(s['name'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBase,
                    )),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') _confirmDelete(index);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: AppColors.textLight, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(s['date'],
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(s['simId'],
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Temperature',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    Text('${s['temperature']}°C',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBase,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pressure',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    Text('${s['pressure']} bar',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBase,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s['scenario'],
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.cyan),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
