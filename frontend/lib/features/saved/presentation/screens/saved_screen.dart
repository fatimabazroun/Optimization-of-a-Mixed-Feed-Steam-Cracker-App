import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Simple in-memory store for saved scenarios
class SavedScenariosStore {
  static final List<Map<String, dynamic>> scenarios = [];
}

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Optimal', 'Warning', 'Critical'];

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return SavedScenariosStore.scenarios;
    return SavedScenariosStore.scenarios
        .where((s) => s['status'] == _filter)
        .toList();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Scenario',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkBase)),
        content: Text(
          'Are you sure you want to delete "${SavedScenariosStore.scenarios[index]['name']}"?',
          style: const TextStyle(color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () {
              setState(() => SavedScenariosStore.scenarios.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
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
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_outline,
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
                              const Text('Run a simulation to save results here',
                                  style: AppTextStyles.body),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final s = _filtered[i];
                            final realIndex = SavedScenariosStore.scenarios.indexOf(s);
                            return _scenarioCard(s, realIndex);
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

    return Container(
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
    );
  }
}