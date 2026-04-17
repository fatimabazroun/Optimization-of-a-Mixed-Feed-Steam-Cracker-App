import 'dart:ui' show ImageFilter;
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
    0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85,
  ];

  bool get _isScenario1 => widget.scenario['scenarioNumber'] == 'Scenario 1';

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

  // ── PETE — CO₂ Storage Assessment ────────────────────────────────────────
  // A. Project inputs
  final _co2RateCtrl        = TextEditingController();
  final _projDurationCtrl   = TextEditingController();
  final _numWellsCtrl       = TextEditingController();
  // B. Reservoir inputs
  final _depthCtrl          = TextEditingController();
  final _initPressureCtrl   = TextEditingController();
  final _permeabilityCtrl   = TextEditingController();
  final _thicknessCtrl      = TextEditingController();
  final _porosityCtrl       = TextEditingController();
  final _reservoirRadiusCtrl = TextEditingController();
  String _reservoirType     = 'Open';
  // C. Pressure constraint
  final _fracPressureCtrl   = TextEditingController();
  final _fracGradientCtrl   = TextEditingController();
  final _safetyMarginCtrl   = TextEditingController();
  // D. Advanced inputs
  final _co2DensityCtrl     = TextEditingController();
  final _co2ViscosityCtrl   = TextEditingController();
  final _totalCompCtrl      = TextEditingController();
  final _wellboreRadiusCtrl = TextEditingController();
  final _skinFactorCtrl     = TextEditingController();
  final _closedMultCtrl     = TextEditingController();
  final _logStartTimeCtrl   = TextEditingController();

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
    _co2RateCtrl.dispose();
    _projDurationCtrl.dispose();
    _numWellsCtrl.dispose();
    _depthCtrl.dispose();
    _initPressureCtrl.dispose();
    _permeabilityCtrl.dispose();
    _thicknessCtrl.dispose();
    _porosityCtrl.dispose();
    _reservoirRadiusCtrl.dispose();
    _fracPressureCtrl.dispose();
    _fracGradientCtrl.dispose();
    _safetyMarginCtrl.dispose();
    _co2DensityCtrl.dispose();
    _co2ViscosityCtrl.dispose();
    _totalCompCtrl.dispose();
    _wellboreRadiusCtrl.dispose();
    _skinFactorCtrl.dispose();
    _closedMultCtrl.dispose();
    _logStartTimeCtrl.dispose();
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
                              _isScenario1
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
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                                    decoration: BoxDecoration(
                                                      gradient: selected
                                                          ? LinearGradient(
                                                              colors: [accentColor, AppColors.primaryBlue],
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            )
                                                          : LinearGradient(
                                                              colors: [
                                                                Colors.white.withValues(alpha: 0.60),
                                                                accentColor.withValues(alpha: 0.06),
                                                              ],
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            ),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(
                                                        color: selected
                                                            ? Colors.white.withValues(alpha: 0.4)
                                                            : Colors.white.withValues(alpha: 0.6),
                                                        width: 1.2,
                                                      ),
                                                      boxShadow: selected
                                                          ? [BoxShadow(
                                                              color: accentColor.withValues(alpha: 0.35),
                                                              blurRadius: 14,
                                                              offset: const Offset(0, 4),
                                                            )]
                                                          : [BoxShadow(
                                                              color: accentColor.withValues(alpha: 0.08),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 3),
                                                            )],
                                                    ),
                                                    child: Text('$t°C',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: selected ? Colors.white : accentColor,
                                                        )),
                                                  ),
                                                ),
                                              ),
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
                              _isScenario1
                                  ? _lockedField('1.5 bar', accentColor)
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 0.60),
                                                      accentColor.withValues(alpha: 0.07),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
                                                  boxShadow: [
                                                    BoxShadow(color: accentColor.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
                                                  ],
                                                ),
                                                child: TextFormField(
                                                  controller: _pressureController,
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: accentColor),
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
                                                    hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
                                                    filled: false,
                                                    border: InputBorder.none,
                                                    enabledBorder: InputBorder.none,
                                                    focusedBorder: InputBorder.none,
                                                    errorBorder: InputBorder.none,
                                                    focusedErrorBorder: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withValues(alpha: 0.55),
                                                    accentColor.withValues(alpha: 0.10),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
                                              ),
                                              child: Text('bar',
                                                  style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                              const SizedBox(height: 20),

                              // Valid phases
                              const Text('Valid Phases',
                                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                              const SizedBox(height: 8),
                              _glassDropdownShell(
                                accentColor: accentColor,
                                isExpanded: true,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _validPhase,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFFF0F4FF).withValues(alpha: 0.97),
                                    icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: ['Vapor-Only', 'Liquid-Only', 'Vapor-Liquid']
                                        .map((item) => DropdownMenuItem(
                                              value: item,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Text(item),
                                              ),
                                            ))
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
                                    if (i == 0 && _isScenario1)
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
                                          _isScenario1
                                              ? _readOnlyFraction(r['value'] as double, accentColor)
                                              : ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                                    child: Container(
                                                      width: 70,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.white.withValues(alpha: 0.55),
                                                            accentColor.withValues(alpha: 0.12),
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.1),
                                                      ),
                                                      child: TextFormField(
                                                        initialValue: (r['value'] as double).toStringAsFixed(2),
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accentColor),
                                                        decoration: const InputDecoration(
                                                          filled: false,
                                                          border: InputBorder.none,
                                                          enabledBorder: InputBorder.none,
                                                          focusedBorder: InputBorder.none,
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                                                        ),
                                                        onChanged: (val) {
                                                          final parsed = double.tryParse(val);
                                                          if (parsed != null) {
                                                            setState(() => _reactions[i]['value'] = parsed);
                                                          }
                                                        },
                                                      ),
                                                    ),
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

                        // ── PETE — CO₂ Storage Assessment ──
                        _peteSectionHeader(accentColor),
                        const SizedBox(height: 18),

                        // A. Project Inputs
                        _peteSubHeader('A', 'Project Inputs', accentColor),
                        const SizedBox(height: 12),
                        _sectionCard(
                          child: Column(
                            children: [
                              _peteField(label: 'CO₂ rate (ṁ_total)', unit: 'kg/hr', controller: _co2RateCtrl, accentColor: accentColor),
                              const SizedBox(height: 14),
                              _peteField(label: 'Project duration (T_proj)', unit: 'years', controller: _projDurationCtrl, accentColor: accentColor),
                              const SizedBox(height: 14),
                              _peteField(label: 'Number of wells (N_w)', unit: '–', controller: _numWellsCtrl, accentColor: accentColor, keyboardType: TextInputType.number),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // B. Reservoir Inputs
                        _peteSubHeader('B', 'Reservoir Inputs', accentColor),
                        const SizedBox(height: 12),
                        _sectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Depth (D)', unit: 'm', controller: _depthCtrl, accentColor: accentColor)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Initial pressure (P_i)', unit: 'MPa', controller: _initPressureCtrl, accentColor: accentColor)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Permeability (k)', unit: 'mD', controller: _permeabilityCtrl, accentColor: accentColor)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Thickness (h)', unit: 'm', controller: _thicknessCtrl, accentColor: accentColor)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Porosity (ϕ)', unit: '–', controller: _porosityCtrl, accentColor: accentColor, hint: '0 – 1')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Reservoir radius (r_e)', unit: 'm', controller: _reservoirRadiusCtrl, accentColor: accentColor)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Reservoir type', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                      const Spacer(),
                                      _peteBadge('Required', accentColor, isRequired: true),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _glassDropdownShell(
                                    accentColor: accentColor,
                                    isExpanded: true,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _reservoirType,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFFF0F4FF).withValues(alpha: 0.97),
                                        icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                                        style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                                        items: ['Open', 'Closed'].map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Text(v),
                                          ),
                                        )).toList(),
                                        onChanged: (val) => setState(() => _reservoirType = val!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // C. Pressure Constraint
                        _peteSubHeader('C', 'Pressure Constraint', accentColor),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Either / Or', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
                              ),
                              const SizedBox(width: 8),
                              const Text('Provide at least one of the two fields below', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                        _sectionCard(
                          child: Column(
                            children: [
                              _peteField(label: 'Fracture pressure (P_frac)', unit: 'MPa', controller: _fracPressureCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Either / Or'),
                              const SizedBox(height: 14),
                              _peteField(label: 'Fracture gradient (G_f)', unit: 'MPa/m', controller: _fracGradientCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Either / Or'),
                              const SizedBox(height: 14),
                              _peteField(label: 'Safety margin (ΔP_safe)', unit: 'MPa', controller: _safetyMarginCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // D. Advanced Inputs
                        _peteSubHeader('D', 'Advanced Inputs', accentColor),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('All fields optional — leave blank to use defaults', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ),
                        _sectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'CO₂ density (ρ)', unit: 'kg/m³', controller: _co2DensityCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'CO₂ viscosity (μ)', unit: 'cP', controller: _co2ViscosityCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Total compressibility (c_t)', unit: '1/MPa', controller: _totalCompCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Wellbore radius (r_w)', unit: 'm', controller: _wellboreRadiusCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Skin factor (s)', unit: '–', controller: _skinFactorCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Log start time (t₀)', unit: 'days', controller: _logStartTimeCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional')),
                                ],
                              ),
                              if (_reservoirType == 'Closed') ...[
                                const SizedBox(height: 14),
                                _peteField(label: 'Closed multiplier (α)', unit: '–', controller: _closedMultCtrl, accentColor: accentColor, isRequired: false, badgeLabel: 'Optional'),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        _GlowButton(
                          text: 'Execute Simulation',
                          icon: Icons.play_circle_outline_rounded,
                          accentColor: accentColor,
                          onPressed: () {
                            if (!_isScenario1) {
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
                                  temperature: _isScenario1 ? '850' : _selectedTemp!,
                                  pressure: _isScenario1 ? '1.5' : _pressureController.text,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.60),
                accentColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(color: accentColor.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: accentColor.withValues(alpha: 0.6)),
              const SizedBox(width: 10),
              Text(value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accentColor)),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text('Fixed',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Read-only fraction chip ───────────────────────────────────────────────
  Widget _readOnlyFraction(double value, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.55),
                accentColor.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.1),
          ),
          child: Center(
            child: Text(
              value.toStringAsFixed(2),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accentColor),
            ),
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
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text('$rxn',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor)),
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
            // Liquid glass dropdown for Rxn 1 fraction
            _glassDropdownShell(
              accentColor: accentColor,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _selectedRxn1,
                  isDense: true,
                  dropdownColor: const Color(0xFFF0F4FF).withValues(alpha: 0.97),
                  icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                  items: _rxn1Values.map((v) {
                    return DropdownMenuItem<double>(
                      value: v,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(v.toStringAsFixed(2)),
                      ),
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

  // ── Liquid glass dropdown shell ───────────────────────────────────────────
  Widget _glassDropdownShell({
    required Color accentColor,
    required Widget child,
    bool isExpanded = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.55),
                accentColor.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── PETE helpers ─────────────────────────────────────────────────────────

  Widget _peteSectionHeader(Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withValues(alpha: 0.55), accentColor.withValues(alpha: 0.10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.co2_outlined, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PETE — CO₂ Storage Assessment',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accentColor)),
                    const SizedBox(height: 2),
                    const Text('Geological storage feasibility inputs',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _peteSubHeader(String letter, String title, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(7)),
          child: Center(child: Text(letter, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accentColor))),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
      ],
    );
  }

  Widget _peteBadge(String label, Color accentColor, {bool isRequired = true}) {
    final Color bg = isRequired
        ? accentColor.withValues(alpha: 0.11)
        : AppColors.textLight.withValues(alpha: 0.10);
    final Color fg = isRequired ? accentColor : AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _peteField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required Color accentColor,
    bool isRequired = true,
    String badgeLabel = 'Required',
    String? hint,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true, signed: true),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    if (unit != '–') ...[
                      const TextSpan(text: '  '),
                      TextSpan(text: unit, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            _peteBadge(badgeLabel, accentColor, isRequired: isRequired),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.60), accentColor.withValues(alpha: 0.07)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
                boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.09), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
                decoration: InputDecoration(
                  hintText: hint ?? 'Enter value',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textLight.withValues(alpha: 0.65), fontWeight: FontWeight.w400),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
          ),
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
            color: AppColors.primaryBlue.withValues(alpha: 0.07),
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
                      color: widget.accentColor.withValues(alpha: 0.55),
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
      ..color = Colors.white.withValues(alpha: 0.9)
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
