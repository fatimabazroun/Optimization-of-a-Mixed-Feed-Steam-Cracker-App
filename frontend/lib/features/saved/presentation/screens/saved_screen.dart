import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    var list = _filter == 'All'
        ? _scenarios
        : _scenarios.where((s) => s['status'] == _filter).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) => (s['name'] as String? ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _confirmDelete(Map<String, dynamic> s) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
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
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Delete Scenario',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBase)),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${s['name']}"? This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMedium, height: 1.5),
                ),
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
                          child: const Text('Cancel',
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
                        onTap: () async {
                          Navigator.pop(context);
                          await ScenarioService.deleteScenario(
                            userId:     s['userId'] as String,
                            scenarioId: s['scenarioId'] as String,
                            s3Key:      s['s3Key'] as String,
                          );
                          await _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('Delete',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved Scenarios', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.2)),
                          const SizedBox(height: 6),
                          Text('Review and manage your previous simulations',
                              style: TextStyle(fontSize: 14, color: context.textSecondary)),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/Transparent_logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List — search + filters scroll away with content (Apple standard)
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.cyan, strokeWidth: 2),
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                              // iOS-style pull-to-refresh
                              CupertinoSliverRefreshControl(
                                onRefresh: _load,
                              ),

                              // Search bar — scrolls away on scroll down
                              SliverToBoxAdapter(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    style: const TextStyle(fontSize: 14, color: AppColors.darkBase),
                                    decoration: InputDecoration(
                                      hintText: 'Search scenarios…',
                                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                                      prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () => _searchCtrl.clear(),
                                              child: const Icon(Icons.close, color: AppColors.textLight, size: 18),
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 14)),

                              // Filter chips — also scrolls away
                              SliverToBoxAdapter(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.filter_list, color: AppColors.textLight, size: 18),
                                      const SizedBox(width: 10),
                                      ..._filters.map((f) {
                                        final selected = _filter == f;
                                        final Color chipColor = switch (f) {
                                          'Optimal'  => const Color(0xFF2ECC71),
                                          'Warning'  => const Color(0xFFF39C12),
                                          'Critical' => const Color(0xFFE74C3C),
                                          _          => AppColors.cyan,
                                        };
                                        return GestureDetector(
                                          onTap: () => setState(() => _filter = f),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? chipColor.withValues(alpha: 0.15)
                                                  : Colors.white.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: selected
                                                    ? chipColor.withValues(alpha: 0.6)
                                                    : Colors.white.withValues(alpha: 0.8),
                                                width: 1.2,
                                              ),
                                              boxShadow: selected
                                                  ? [BoxShadow(color: chipColor.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 3))]
                                                  : [],
                                            ),
                                            child: Text(f,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: selected ? chipColor : AppColors.textMedium,
                                                )),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 16)),

                              // Cards or empty state
                              _filtered.isEmpty
                                  ? SliverFillRemaining(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.bookmark_outline,
                                              size: 64, color: AppColors.highlight),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? 'No results for "$_searchQuery"'
                                                : _filter == 'All'
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
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, i) {
                                          final s = _filtered[i];
                                          final realIndex = _scenarios.indexOf(s);
                                          return _scenarioCard(s, realIndex);
                                        },
                                        childCount: _filtered.length,
                                      ),
                                    ),
                            ],
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

  Future<void> _openSavedScenario(Map<String, dynamic> s) async {
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

    if (!mounted) return;

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
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.18), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.18),
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
                    color: AppColors.cyan.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2.5),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Loading Scenario',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBase)),
                const SizedBox(height: 8),
                const Text('Fetching your saved results…',
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
      final rawData = await ScenarioService.getScenarioResults(s['s3Key'] as String);
      if (!mounted) return;
      Navigator.pop(context); // close loader

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => SimulationResultsScreen(
            scenario:      scenarioData,
            temperature:   s['temperature'] as String,
            pressure:      s['pressure'] as String,
            scenarioId:    s['scenarioType'] as String? ?? s['scenarioId'] as String? ?? 'S1',
            selectedValue: s['selectedValue'] ?? '',
            useReservoir:  s['useReservoir'] as bool? ?? false,
            cachedRawData: rawData,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader

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
                  const Text('Failed to Load',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBase)),
                  const SizedBox(height: 8),
                  const Text('Could not retrieve the scenario results.',
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

  String _reactionLabel(Map<String, dynamic> s) {
    final scenarioId = s['scenarioType'] as String? ?? s['scenarioId'] as String? ?? 'S1';
    final sel = s['selectedValue'];
    if (sel == null) return '';
    if (scenarioId == 'S1') {
      final val = (sel is num) ? sel.toDouble() : double.tryParse(sel.toString()) ?? 0.0;
      return 'Rxn 1 — conv. ${(val * 100).toStringAsFixed(0)}%';
    }
    final parts = sel.toString().split('-');
    if (scenarioId == 'S2' && parts.length >= 2) {
      final v1 = (double.tryParse(parts[0]) ?? 0) * 100;
      final v2 = (double.tryParse(parts[1]) ?? 0) * 100;
      return 'Rxn 1 & 2 — ${v1.toStringAsFixed(0)}%, ${v2.toStringAsFixed(0)}%';
    }
    if (scenarioId == 'S3' && parts.length >= 3) {
      final v1 = (double.tryParse(parts[0]) ?? 0) * 100;
      final v2 = (double.tryParse(parts[1]) ?? 0) * 100;
      final v3 = (double.tryParse(parts[2]) ?? 0) * 100;
      return 'Rxn 1, 2 & 3 — ${v1.toStringAsFixed(0)}%, ${v2.toStringAsFixed(0)}%, ${v3.toStringAsFixed(0)}%';
    }
    return '';
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
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: context.cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(s['name'],
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
              ),
              GestureDetector(
                onTap: () => _confirmDelete(s),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: context.textTertiary),
              const SizedBox(width: 4),
              Flexible(child: Text(s['date'], style: TextStyle(fontSize: 12, color: context.textTertiary))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
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
              Flexible(child: Text(s['simId'], style: TextStyle(fontSize: 11, color: context.textTertiary))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temperature', style: TextStyle(fontSize: 11, color: context.textTertiary)),
                    Text('${s['temperature']}°C', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pressure', style: TextStyle(fontSize: 11, color: context.textTertiary)),
                    Text('${s['pressure']} bar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _reactionLabel(s),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s['scenario'], style: TextStyle(fontSize: 12, color: context.textSecondary)),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.cyan),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
