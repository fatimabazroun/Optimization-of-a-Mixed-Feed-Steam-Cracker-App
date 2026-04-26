import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/field_info_tooltip.dart';
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

  // Rxn 1 dropdown (Ethane only)
  double _selectedRxn1 = 0.70;

  static const List<double> _rxn1Values = [
    0.40,
    0.45,
    0.50,
    0.55,
    0.60,
    0.65,
    0.70,
    0.75,
    0.80,
    0.85,
  ];

  bool get _isScenario1 => widget.scenario['scenarioNumber'] == 'Scenario 1';
  bool get _isScenario2 => widget.scenario['scenarioNumber'] == 'Scenario 2';
  bool get _isScenario3 => widget.scenario['scenarioNumber'] == 'Scenario 3';
  bool get _hasLockedConditions => _isScenario1 || _isScenario2 || _isScenario3;

  String _buildScenarioId() {
    if (_isScenario1) return 'S1';
    if (_isScenario2) return 'S2';
    if (_isScenario3) return 'S3';
    return 'S1';
  }

  // Returns the value to match against the S3 JSON "conversion" or "selection" key.
  // S1 → conversion double (e.g. 0.70)
  // S2 → "rxn1-rxn2" string (e.g. "0.85-0.04")
  // S3 → "rxn1-rxn2-rxn3" string (e.g. "0.75-0.03-0.01")
  dynamic _buildSelectedValue() {
    if (_isScenario1) return _selectedRxn1;
    if (_isScenario2) {
      final p = _rxnPairs[_selectedPairIndex];
      return '${p[0]}-${p[1]}';
    }
    if (_isScenario3) {
      final t = _rxnTriplets[_selectedTripletIndex];
      return '${t[0]}-${t[1]}-${t[2]}';
    }
    return _selectedRxn1;
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.40),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: Color(0xFFE74C3C), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(msg,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // Populates _errorFields with all failing keys. Returns false if any errors.
  bool _validatePeteInputs() {
    _errorFields.clear();
    double? parse(TextEditingController c) =>
        double.tryParse(c.text.trim());

    // Required fields — non-empty and > 0
    final requiredPositive = <String, TextEditingController>{
      'proj_duration': _projDurationCtrl,
      'n_wells': _numWellsCtrl,
      'depth': _depthCtrl,
      'init_pressure': _initPressureCtrl,
      'permeability': _permeabilityCtrl,
      'thickness': _thicknessCtrl,
      'res_radius': _reservoirRadiusCtrl,
    };
    for (final e in requiredPositive.entries) {
      final v = parse(e.value);
      if (e.value.text.trim().isEmpty || v == null || v <= 0) {
        _errorFields.add(e.key);
      }
    }

    // Porosity: required, 0 ≤ ϕ ≤ 1
    final phi = parse(_porosityCtrl);
    if (_porosityCtrl.text.trim().isEmpty || phi == null || phi < 0 || phi > 1) {
      _errorFields.add('porosity');
    }

    // Section C: at least one of frac_pressure / frac_gradient
    final hasFracP = _fracPressureCtrl.text.trim().isNotEmpty;
    final hasFracG = _fracGradientCtrl.text.trim().isNotEmpty;
    if (!hasFracP && !hasFracG) {
      _errorFields.add('frac_pressure');
      _errorFields.add('frac_gradient');
    } else {
      if (hasFracP) {
        final v = parse(_fracPressureCtrl);
        if (v == null || v <= 0) _errorFields.add('frac_pressure');
      }
      if (hasFracG) {
        final v = parse(_fracGradientCtrl);
        if (v == null || v <= 0) _errorFields.add('frac_gradient');
      }
    }

    // Optional positives — validate only if filled
    final optPositive = <String, TextEditingController>{
      'safety_margin': _safetyMarginCtrl,
      'co2_density': _co2DensityCtrl,
      'co2_viscosity': _co2ViscosityCtrl,
      'total_comp': _totalCompCtrl,
      'well_radius': _wellboreRadiusCtrl,
      'log_start_time': _logStartTimeCtrl,
    };
    for (final e in optPositive.entries) {
      final txt = e.value.text.trim();
      if (txt.isEmpty) continue;
      final v = parse(e.value);
      if (v == null || v <= 0) _errorFields.add(e.key);
    }

    if (_skinFactorCtrl.text.trim().isNotEmpty &&
        double.tryParse(_skinFactorCtrl.text.trim()) == null) {
      _errorFields.add('skin_factor');
    }

    if (_reservoirType == 'Closed' && _closedMultCtrl.text.trim().isNotEmpty) {
      final v = parse(_closedMultCtrl);
      if (v == null || v <= 0) _errorFields.add('closed_mult');
    }

    return _errorFields.isEmpty;
  }

  Map<String, dynamic> _buildReservoirInputs() {
    double? parse(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : double.tryParse(t);
    }

    return {
      'project_duration': parse(_projDurationCtrl)!,
      'n_wells': parse(_numWellsCtrl)!.toInt(),
      'depth': parse(_depthCtrl)!,
      'initial_pressure': parse(_initPressureCtrl)!,
      'permeability': parse(_permeabilityCtrl)!,
      'thickness': parse(_thicknessCtrl)!,
      'porosity': parse(_porosityCtrl)!,
      'radius': parse(_reservoirRadiusCtrl)!,
      'reservoir_type': _reservoirType,
      if (_fracPressureCtrl.text.trim().isNotEmpty)
        'fracture_pressure': parse(_fracPressureCtrl)!,
      if (_fracGradientCtrl.text.trim().isNotEmpty)
        'fracture_gradient': parse(_fracGradientCtrl)!,
      if (_safetyMarginCtrl.text.trim().isNotEmpty)
        'safety_margin': parse(_safetyMarginCtrl)!,
      if (_co2DensityCtrl.text.trim().isNotEmpty)
        'co2_density': parse(_co2DensityCtrl)!,
      if (_co2ViscosityCtrl.text.trim().isNotEmpty)
        'co2_viscosity': parse(_co2ViscosityCtrl)!,
      if (_totalCompCtrl.text.trim().isNotEmpty)
        'compressibility': parse(_totalCompCtrl)!,
      if (_wellboreRadiusCtrl.text.trim().isNotEmpty)
        'well_radius': parse(_wellboreRadiusCtrl)!,
      if (_skinFactorCtrl.text.trim().isNotEmpty)
        'skin': parse(_skinFactorCtrl)!,
      if (_co2SaturationCtrl.text.trim().isNotEmpty)
        'co2_saturation': parse(_co2SaturationCtrl)!,
      if (_logStartTimeCtrl.text.trim().isNotEmpty)
        'log_start_time': parse(_logStartTimeCtrl)!,
      if (_reservoirType == 'Closed' && _closedMultCtrl.text.trim().isNotEmpty)
        'closed_multiplier': parse(_closedMultCtrl)!,
    };
  }

  // Scenario 2 — allowed Rxn1/Rxn2 pairs (in order from spec)
  static const List<List<double>> _rxnPairs = [
    [0.90, 0.04],
    [0.85, 0.08],
    [0.85, 0.06],
    [0.85, 0.04],
    [0.80, 0.08],
    [0.80, 0.06],
    [0.80, 0.04],
  ];
  int _selectedPairIndex = 0;

  // Scenario 3 — allowed Rxn1/Rxn2/Rxn3 triplets (in order from spec)
  static const List<List<double>> _rxnTriplets = [
    [0.75, 0.03, 0.01],
    [0.75, 0.04, 0.02],
    [0.75, 0.05, 0.03],
    [0.80, 0.03, 0.01],
    [0.80, 0.04, 0.02],
    [0.80, 0.05, 0.03],
  ];
  int _selectedTripletIndex = 0;

  static const _rxnDescriptions = <int, String>{
    1: 'Primary cracking of ethane to hydrogen and ethylene. This is the main target reaction — higher conversion directly increases ethylene yield.',
    2: 'Secondary ethane reaction producing propane and methane as byproducts. Competes with Rxn 1 and reduces ethylene selectivity.',
    3: 'Propane cracking to propylene and hydrogen. Beneficial side reaction that produces valuable propylene.',
    4: 'Propane cracking to methane and ethylene. Competes with Rxn 3 for propane consumption.',
    5: 'Propylene decomposition to acetylene and methane. Undesirable reaction that reduces propylene yield.',
    6: 'Condensation of ethylene and acetylene to form cyclobutadiene. An undesired secondary product.',
    7: 'Ethane coupling producing methane and ethylene. Minor side reaction competing with primary cracking.',
    8: 'Reaction between ethane and ethylene forming methane and propylene. Reduces net ethylene yield.',
  };

  final List<Map<String, dynamic>> _reactions = [
    {
      'rxn': 1,
      'component': 'ETHAN-01',
      'stoichiometry': 'ETHAN-01 → HYDRO-01 + ETHYL-01',
      'value': 0.70
    },
    {
      'rxn': 2,
      'component': 'ETHAN-01',
      'stoichiometry': '2 ETHAN-01 → PROPA-01 + METHA-01',
      'value': 0.08
    },
    {
      'rxn': 3,
      'component': 'PROPA-01',
      'stoichiometry': 'PROPA-01 → PROPY-01 + HYDRO-01',
      'value': 0.05
    },
    {
      'rxn': 4,
      'component': 'PROPA-01',
      'stoichiometry': 'PROPA-01 → METHA-01 + ETHYL-01',
      'value': 0.05
    },
    {
      'rxn': 5,
      'component': 'PROPY-01',
      'stoichiometry': 'PROPY-01 → ACETY-01 + METHA-01',
      'value': 0.04
    },
    {
      'rxn': 6,
      'component': 'ETHYL-01',
      'stoichiometry': 'ETHYL-01 + ACETY-01 → CYCLO-02',
      'value': 0.03
    },
    {
      'rxn': 7,
      'component': 'ETHAN-01',
      'stoichiometry': '2 ETHAN-01 → 2 METHA-01 + ETHYL-01',
      'value': 0.03
    },
    {
      'rxn': 8,
      'component': 'ETHAN-01',
      'stoichiometry': 'ETHAN-01 + ETHYL-01 → METHA-01 + PROPY-01',
      'value': 0.02
    },
  ];

  // ── PETE — CO₂ Storage Assessment ────────────────────────────────────────
  // A. Project inputs
  final _projDurationCtrl = TextEditingController();
  final _numWellsCtrl = TextEditingController();
  // B. Reservoir inputs
  final _depthCtrl = TextEditingController();
  final _initPressureCtrl = TextEditingController();
  final _permeabilityCtrl = TextEditingController();
  final _thicknessCtrl = TextEditingController();
  final _porosityCtrl = TextEditingController();
  final _reservoirRadiusCtrl = TextEditingController();
  String _reservoirType = 'Open';
  bool _hasReservoirInfo = true;
  // C. Pressure constraint
  final _fracPressureCtrl = TextEditingController();
  final _fracGradientCtrl = TextEditingController();
  final _safetyMarginCtrl = TextEditingController();
  // D. Advanced inputs
  final _co2DensityCtrl = TextEditingController();
  final _co2ViscosityCtrl = TextEditingController();
  final _totalCompCtrl = TextEditingController();
  final _wellboreRadiusCtrl = TextEditingController();
  final _skinFactorCtrl = TextEditingController();
  final _co2SaturationCtrl = TextEditingController();
  final _closedMultCtrl = TextEditingController();
  final _logStartTimeCtrl = TextEditingController();

  final Set<String> _errorFields = {};
  final Map<String, String> _liveRangeErrors = {};

  static const _fieldRanges = <String, (double, double)>{
    'proj_duration':  (1,      50),
    'n_wells':        (1,      10),
    'depth':          (800,    3000),
    'init_pressure':  (5,      50),
    'permeability':   (0.1,    1000),
    'thickness':      (5,      100),
    'porosity':       (0.05,   0.4),
    'res_radius':     (500,    10000),
    'frac_gradient':  (0.015,  0.025),
    'safety_margin':  (1,      5),
    'co2_density':    (500,    900),
    'co2_viscosity':  (0.03,   0.1),
    'co2_saturation': (0.05,   0.6),
    'total_comp':     (1e-5,   1e-3),
    'well_radius':    (0.05,   0.3),
    'skin_factor':    (-5,     20),
    'closed_mult':    (1,      5),
    'log_start_time': (0.1,    10),
  };

  void _clearFieldError(String key) {
    if (_errorFields.contains(key)) setState(() => _errorFields.remove(key));
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    // Pre-fill optional defaults
    _safetyMarginCtrl.text = '1.5';
    _co2DensityCtrl.text = '700';
    _co2ViscosityCtrl.text = '0.05';
    _totalCompCtrl.text = '0.0001';
    _wellboreRadiusCtrl.text = '0.1';
    _skinFactorCtrl.text = '0';
    _co2SaturationCtrl.text = '0.2';
    _closedMultCtrl.text = '3';
    _logStartTimeCtrl.text = '1';

    // Wire error-clear + live range validation for every PETE field
    final fieldListeners = <TextEditingController, String>{
      _projDurationCtrl:    'proj_duration',
      _numWellsCtrl:        'n_wells',
      _depthCtrl:           'depth',
      _initPressureCtrl:    'init_pressure',
      _permeabilityCtrl:    'permeability',
      _thicknessCtrl:       'thickness',
      _porosityCtrl:        'porosity',
      _reservoirRadiusCtrl: 'res_radius',
      _fracPressureCtrl:    'frac_pressure',
      _fracGradientCtrl:    'frac_gradient',
      _safetyMarginCtrl:    'safety_margin',
      _co2DensityCtrl:      'co2_density',
      _co2ViscosityCtrl:    'co2_viscosity',
      _totalCompCtrl:       'total_comp',
      _wellboreRadiusCtrl:  'well_radius',
      _skinFactorCtrl:      'skin_factor',
      _co2SaturationCtrl:   'co2_saturation',
      _closedMultCtrl:      'closed_mult',
      _logStartTimeCtrl:    'log_start_time',
    };
    for (final e in fieldListeners.entries) {
      final key = e.value;
      final range = _fieldRanges[key];
      e.key.addListener(() {
        setState(() {
          _errorFields.remove(key);
          final text = e.key.text.trim();
          if (range != null && text.isNotEmpty) {
            final v = double.tryParse(text);
            if (v != null && (v < range.$1 || v > range.$2)) {
              _liveRangeErrors[key] = '${range.$1} – ${range.$2}';
            } else {
              _liveRangeErrors.remove(key);
            }
          } else {
            _liveRangeErrors.remove(key);
          }
        });
      });
    }
    // frac either/or: editing either one clears both highlights
    _fracPressureCtrl.addListener(() => _clearFieldError('frac_gradient'));
    _fracGradientCtrl.addListener(() => _clearFieldError('frac_pressure'));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pressureController.dispose();
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
    _co2SaturationCtrl.dispose();
    _closedMultCtrl.dispose();
    _logStartTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = widget.scenario['color'] as Color;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            size: 16, color: context.textSecondary),
                        SizedBox(width: 4),
                        Text('Back to Overview', style: TextStyle(fontSize: 14, color: context.textSecondary)),
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
                        Text('Configure Simulation',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.2)),
                        SizedBox(height: 6),
                        Text('Set input parameters for the simulation',
                            style: TextStyle(fontSize: 14, color: context.textSecondary)),
                        SizedBox(height: 28),

                        // ── Operating Conditions ──
                        _sectionTitle('Operating Conditions'),
                        SizedBox(height: 14),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Temperature
                              Row(children: [
                                Text('Temperature (°C)',
                                    style: TextStyle(fontSize: 12, color: context.textTertiary)),
                                FieldInfoTooltip(description: 'Cracking furnace temperature. Fixed at 850°C — the validated standard operating condition for this simulation model.'),
                              ]),
                              SizedBox(height: 10),
                              _hasLockedConditions
                                  ? _lockedField('850°C', accentColor)
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children:
                                            ['850', '900', '1000'].map((t) {
                                          final selected = _selectedTemp == t;
                                          return GestureDetector(
                                            onTap: () => setState(
                                                () => _selectedTemp = t),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 10, sigmaY: 10),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 22,
                                                        vertical: 13),
                                                    decoration: BoxDecoration(
                                                      gradient: selected
                                                          ? LinearGradient(
                                                              colors: [
                                                                accentColor,
                                                                AppColors
                                                                    .primaryBlue
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            )
                                                          : LinearGradient(
                                                              colors: [
                                                                Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.60),
                                                                accentColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.06),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      border: Border.all(
                                                        color: selected
                                                            ? Colors.white
                                                                .withValues(
                                                                    alpha: 0.4)
                                                            : Colors.white
                                                                .withValues(
                                                                    alpha: 0.6),
                                                        width: 1.2,
                                                      ),
                                                      boxShadow: selected
                                                          ? [
                                                              BoxShadow(
                                                                color: accentColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.35),
                                                                blurRadius: 14,
                                                                offset:
                                                                    const Offset(
                                                                        0, 4),
                                                              )
                                                            ]
                                                          : [
                                                              BoxShadow(
                                                                color: accentColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.08),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                        0, 3),
                                                              )
                                                            ],
                                                    ),
                                                    child: Text('$t°C',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: selected
                                                              ? Colors.white
                                                              : accentColor,
                                                        )),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                              SizedBox(height: 20),

                              // Pressure
                              Row(children: [
                                Text('Pressure (bar)',
                                    style: TextStyle(fontSize: 12, color: context.textTertiary)),
                                FieldInfoTooltip(description: 'Operating pressure in the cracking furnace. Fixed at 1.5 bar — this is the validated standard condition for this simulation model.'),
                              ]),
                              SizedBox(height: 8),
                              _hasLockedConditions
                                  ? _lockedField('1.5 bar', accentColor)
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: 10, sigmaY: 10),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withValues(
                                                          alpha: 0.60),
                                                      accentColor.withValues(
                                                          alpha: 0.07),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.6),
                                                      width: 1.2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: accentColor
                                                            .withValues(
                                                                alpha: 0.10),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4)),
                                                  ],
                                                ),
                                                child: TextFormField(
                                                  controller:
                                                      _pressureController,
                                                  keyboardType:
                                                      const TextInputType
                                                          .numberWithOptions(
                                                          decimal: true),
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: accentColor),
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                  validator: (val) {
                                                    if (val == null ||
                                                        val.isEmpty) {
                                                      return 'Pressure is required';
                                                    }
                                                    final p =
                                                        double.tryParse(val);
                                                    if (p == null) {
                                                      return 'Enter a valid number';
                                                    }
                                                    if (p < 0.5 || p > 10) {
                                                      return 'Range: 0.5 – 10 bar';
                                                    }
                                                    return null;
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText: '0.5 – 10 bar',
                                                    hintStyle: TextStyle(
                                                        color: AppColors
                                                            .textLight
                                                            .withValues(
                                                                alpha: 0.7)),
                                                    filled: false,
                                                    border: InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    focusedErrorBorder:
                                                        InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 14,
                                                            vertical: 14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withValues(
                                                        alpha: 0.55),
                                                    accentColor.withValues(
                                                        alpha: 0.10),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.6),
                                                    width: 1.2),
                                              ),
                                              child: Text('bar',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: accentColor,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                              SizedBox(height: 20),

                              // Valid phases
                              Row(children: [
                                Text('Valid Phases',
                                    style: TextStyle(fontSize: 12, color: context.textTertiary)),
                                FieldInfoTooltip(description: 'Phase state allowed in the reactor. Set to Vapor-Only because steam cracking operates entirely in the gas phase — liquid feed is vaporised before entering the furnace.'),
                              ]),
                              SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.2),
                                ),
                                child: Text(
                                  'Vapor-Only',
                                  style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 28),

                        // ── Reactions ──
                        _sectionTitle('Reactions'),
                        SizedBox(height: 14),

                        _sectionCard(
                          child: Column(
                            children: _reactions
                                .asMap()
                                .entries
                                .where((e) => !(_isScenario2 && e.key == 1))
                                .where((e) => !(_isScenario3 &&
                                    (e.key == 1 || e.key == 2)))
                                .map((entry) {
                              final i = entry.key;
                              final r = entry.value;
                              final isLast = i == _reactions.length - 1;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  children: [
                                    if (i == 0 && _isScenario1)
                                      _rxn1DropdownRow(r, accentColor)
                                    else if (i == 0 && _isScenario2)
                                      _rxnPairDropdownRow(accentColor)
                                    else if (i == 0 && _isScenario3)
                                      _rxnTripletDropdownRow(accentColor)
                                    else
                                      Row(
                                        children: [
                                          _rxnBadge(
                                              r['rxn'] as int, accentColor),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(r['component'] as String,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .darkBase)),
                                                Text(
                                                    r['stoichiometry']
                                                        as String,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .textLight)),
                                              ],
                                            ),
                                          ),
                                          if (_rxnDescriptions.containsKey(r['rxn'] as int))
                                            FieldInfoTooltip(description: _rxnDescriptions[r['rxn'] as int]!),
                                          SizedBox(width: 6),
                                          _hasLockedConditions
                                              ? _readOnlyFraction(
                                                  (_isScenario3 &&
                                                          r['rxn'] == 5)
                                                      ? 0.02
                                                      : r['value'] as double,
                                                  accentColor)
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 8, sigmaY: 8),
                                                    child: Container(
                                                      width: 70,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.55),
                                                            accentColor
                                                                .withValues(
                                                                    alpha: 0.12)
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.55),
                                                            width: 1.1),
                                                      ),
                                                      child: TextFormField(
                                                        initialValue: (r[
                                                                    'value']
                                                                as double)
                                                            .toStringAsFixed(2),
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                                decimal: true),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: accentColor),
                                                        decoration:
                                                            const InputDecoration(
                                                          filled: false,
                                                          border:
                                                              InputBorder.none,
                                                          enabledBorder:
                                                              InputBorder.none,
                                                          focusedBorder:
                                                              InputBorder.none,
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          10),
                                                        ),
                                                        onChanged: (val) {
                                                          final parsed =
                                                              double.tryParse(
                                                                  val);
                                                          if (parsed != null) {
                                                            setState(() =>
                                                                _reactions[i][
                                                                        'value'] =
                                                                    parsed);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    if (!isLast)
                                      Padding(
                                        padding: EdgeInsets.only(top: 12),
                                        child: Divider(
                                            color: context.inputBorder,
                                            height: 1),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(height: 32),

                        // ── PETE — CO₂ Storage Assessment ──
                        _peteSectionHeader(accentColor),
                        SizedBox(height: 14),

                        // Yes / No toggle — controls entire PETE section
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                    'Do you have reservoir information?',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary)),
                              ),
                              SizedBox(width: 12),
                              _yesNoToggle(accentColor),
                            ],
                          ),
                        ),

                        if (_hasReservoirInfo) ...[
                          SizedBox(height: 18),

                          // A. Project Inputs
                          _peteSubHeader('A', 'Project Inputs', accentColor),
                          SizedBox(height: 12),
                          _sectionCard(
                            child: Column(
                              children: [
                                _peteField(
                                    label: 'Project duration (T_proj)',
                                    unit: 'years',
                                    controller: _projDurationCtrl,
                                    accentColor: accentColor,
                                    fieldKey: 'proj_duration',
                                    description: '1 – 50 years. Total planned CO₂ injection period. Determines how long pressure and plume radius are simulated.'),
                                SizedBox(height: 14),
                                _peteField(
                                    label: 'Number of wells (N_w)',
                                    unit: '–',
                                    controller: _numWellsCtrl,
                                    accentColor: accentColor,
                                    fieldKey: 'n_wells',
                                    keyboardType: TextInputType.number,
                                    description: '1 – 10. Total injection wells. CO₂ flow rate is split equally across all wells.'),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // B. Reservoir Inputs
                          _peteSubHeader('B', 'Reservoir Inputs', accentColor),
                          SizedBox(height: 12),
                          _sectionCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label: 'Depth (D)',
                                            unit: 'm',
                                            controller: _depthCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'depth',
                                            description: '800 – 3000 m. Vertical depth to the reservoir. Deeper reservoirs generally have higher pressures and better containment.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'Initial pressure (P_i)',
                                            unit: 'MPa',
                                            controller: _initPressureCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'init_pressure',
                                            description: '5 – 50 MPa. Reservoir pressure before CO₂ injection begins. Used as the baseline for pressure build-up calculations.')),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label: 'Permeability (k)',
                                            unit: 'mD',
                                            controller: _permeabilityCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'permeability',
                                            description: '0.1 – 1000 mD. Rock\'s ability to allow fluid flow. Higher permeability means CO₂ spreads more easily and pressure builds more slowly.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'Thickness (h)',
                                            unit: 'm',
                                            controller: _thicknessCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'thickness',
                                            description: '5 – 100 m. Net pay thickness of the injection zone. Thicker zones can store more CO₂ at lower pressure.')),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label: 'Porosity (ϕ)',
                                            unit: '–',
                                            controller: _porosityCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'porosity',
                                            hint: '0 – 1',
                                            description: '0.05 – 0.4. Fraction of rock volume that is pore space. Higher porosity means greater storage capacity.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'Reservoir radius (r_e)',
                                            unit: 'm',
                                            controller: _reservoirRadiusCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'res_radius',
                                            description: '500 – 10000 m. Outer boundary radius of the reservoir. Used to determine whether the CO₂ plume stays within safe limits.')),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Reservoir type',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: context.textTertiary)),
                                        const Spacer(),
                                        _peteBadge('Required', accentColor,
                                            isRequired: true),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    _glassDropdownShell(
                                      accentColor: accentColor,
                                      isExpanded: true,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _reservoirType,
                                          isExpanded: true,
                                          dropdownColor: const Color(0xFFF0F4FF),
                                          icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                                          style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                                          items: ['Open', 'Closed']
                                              .map((v) => DropdownMenuItem(
                                                    value: v,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                                      child: Text(v),
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (val) => setState(() => _reservoirType = val!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // C. Pressure Constraint
                          _peteSubHeader(
                              'C', 'Pressure Constraint', accentColor),
                          SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Either / Or',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor)),
                                ),
                                SizedBox(width: 8),
                                Text(
                                    'Provide at least one of the two fields below',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.textTertiary)),
                              ],
                            ),
                          ),
                          _sectionCard(
                            child: Column(
                              children: [
                                _peteField(
                                    label: 'Fracture pressure (P_frac)',
                                    unit: 'MPa',
                                    controller: _fracPressureCtrl,
                                    accentColor: accentColor,
                                    fieldKey: 'frac_pressure',
                                    isRequired: false,
                                    badgeLabel: 'Either / Or',
                                    description: 'Maximum allowable bottomhole pressure before the rock fractures. Injection must stay below this to avoid caprock damage. Provide this OR fracture gradient.'),
                                SizedBox(height: 14),
                                _peteField(
                                    label: 'Fracture gradient (G_f)',
                                    unit: 'MPa/m',
                                    controller: _fracGradientCtrl,
                                    accentColor: accentColor,
                                    fieldKey: 'frac_gradient',
                                    isRequired: false,
                                    badgeLabel: 'Either / Or',
                                    description: '0.015 – 0.025 MPa/m. Fracture pressure per unit depth. The app multiplies this by depth to compute the fracture pressure limit. Provide this OR fracture pressure.'),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // D. Advanced Inputs
                          _peteSubHeader('D', 'Advanced Inputs', accentColor),
                          SizedBox(height: 6),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                                'All fields optional — leave blank to use defaults',
                                style: TextStyle(
                                    fontSize: 11, color: context.textTertiary)),
                          ),
                          _sectionCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label: 'CO₂ density (ρ)',
                                            unit: 'kg/m³',
                                            controller: _co2DensityCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'co2_density',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 700',
                                            description:
                                                'CO₂ density at reservoir conditions. Affects injectivity calculations.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'CO₂ viscosity (μ)',
                                            unit: 'cP',
                                            controller: _co2ViscosityCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'co2_viscosity',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 0.05',
                                            description:
                                                'CO₂ viscosity at reservoir temperature and pressure.')),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label:
                                                'Total compressibility (c_t)',
                                            unit: '1/MPa',
                                            controller: _totalCompCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'total_comp',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 0.0001',
                                            description:
                                                'Combined compressibility of rock and fluids in the reservoir.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'Wellbore radius (r_w)',
                                            unit: 'm',
                                            controller: _wellboreRadiusCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'well_radius',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 0.1',
                                            description:
                                                'Physical radius of the injection well at the reservoir face.')),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label: 'Skin factor (s)',
                                            unit: '–',
                                            controller: _skinFactorCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'skin_factor',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 0',
                                            description:
                                                '-5 – 20. 0 = undamaged. Positive = damage; negative = stimulation.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'CO₂ saturation (S_CO₂)',
                                            unit: '–',
                                            controller: _co2SaturationCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'co2_saturation',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 0.2',
                                            description:
                                                '0.05 – 0.6. Effective CO₂ saturation in pore space. Used to estimate plume radius.')),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _peteField(
                                            label: 'Safety margin (ΔP_safe)',
                                            unit: 'MPa',
                                            controller: _safetyMarginCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'safety_margin',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 1.5',
                                            description:
                                                '1 – 5 MPa. Pressure buffer below fracture limit.')),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: _peteField(
                                            label: 'Log start time (t₀)',
                                            unit: 'days',
                                            controller: _logStartTimeCtrl,
                                            accentColor: accentColor,
                                            fieldKey: 'log_start_time',
                                            isRequired: false,
                                            badgeLabel: 'Optional',
                                            hint: 'default: 1',
                                            description:
                                                '0.1 – 10 days. Lower bound to avoid log(0) at early time.')),
                                  ],
                                ),
                                if (_reservoirType == 'Closed') ...[
                                  SizedBox(height: 14),
                                  _peteField(
                                      label: 'Closed multiplier (α)',
                                      unit: '–',
                                      controller: _closedMultCtrl,
                                      accentColor: accentColor,
                                      fieldKey: 'closed_mult',
                                      isRequired: false,
                                      badgeLabel: 'Optional',
                                      hint: 'default: 3',
                                      description:
                                          'Multiplier for closed boundary effects — only applies to closed reservoir type.'),
                                ],
                              ],
                            ),
                          ),
                        ], // end if (_hasReservoirInfo)

                        SizedBox(height: 32),

                        _GlowButton(
                          text: 'Execute Simulation',
                          icon: Icons.play_circle_outline_rounded,
                          accentColor: accentColor,
                          onPressed: () {
                            if (!_hasLockedConditions) {
                              if (_selectedTemp == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Please select a temperature.'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              if (_pressureController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Please enter a pressure value.'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                              final p =
                                  double.tryParse(_pressureController.text);
                              if (p == null || p < 0.5 || p > 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Pressure must be between 0.5 – 10 bar.'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }
                            }
                            if (_hasReservoirInfo) {
                              final valid = _validatePeteInputs();
                              setState(() {});
                              if (!valid) {
                                _showError(context,
                                    'Please fill in all highlighted fields correctly.');
                                return;
                              }
                            }
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    SimulationResultsScreen(
                                  scenario: widget.scenario,
                                  temperature: _hasLockedConditions
                                      ? '850'
                                      : _selectedTemp!,
                                  pressure: _hasLockedConditions
                                      ? '1.5'
                                      : _pressureController.text,
                                  scenarioId: _buildScenarioId(),
                                  selectedValue: _buildSelectedValue(),
                                  useReservoir: _hasReservoirInfo,
                                  reservoirInputs: _hasReservoirInfo
                                      ? _buildReservoirInputs()
                                      : null,
                                ),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 40),
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
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 16, color: accentColor.withValues(alpha: 0.6)),
              SizedBox(width: 10),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: accentColor)),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text('Fixed',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor)),
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
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.55), width: 1.1),
          ),
          child: Center(
            child: Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accentColor),
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
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: accentColor)),
      ),
    );
  }

  // ── Rxn 1 + Rxn 2 constrained pair dropdown (Scenario 2) ─────────────────
  Widget _rxnPairDropdownRow(Color accentColor) {
    final pair = _rxnPairs[_selectedPairIndex];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pair selector spanning both reactions ──
          Row(
            children: [
              Text('Rxn 1 & 2',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor)),
              SizedBox(width: 4),
              FieldInfoTooltip(description: 'Fractional conversion for Rxn 1 (primary ethane cracking) and Rxn 2 (secondary ethane reaction). Only pre-validated pairs are available to ensure mass balance.'),
              SizedBox(width: 4),
              Expanded(
                child: Text('— only valid combinations',
                    style: TextStyle(fontSize: 10, color: context.textTertiary)),
              ),
            ],
          ),
          SizedBox(height: 8),
          _glassDropdownShell(
            accentColor: accentColor,
            isExpanded: true,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedPairIndex,
                isExpanded: true,
                dropdownColor: const Color(0xFFF0F4FF),
                icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                items: _rxnPairs.asMap().entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Rxn 1: ${e.value[0].toStringAsFixed(2)}   Rxn 2: ${e.value[1].toStringAsFixed(2)}'),
                  ),
                )).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedPairIndex = val;
                    _reactions[0]['value'] = _rxnPairs[val][0];
                    _reactions[1]['value'] = _rxnPairs[val][1];
                  });
                },
              ),
            ),
          ),

          SizedBox(height: 12),

          // ── Stacked reaction cards ──
          _rxnMiniCard(
              badge: 1,
              component: _reactions[0]['component'] as String,
              stoichiometry: _reactions[0]['stoichiometry'] as String,
              value: pair[0],
              accentColor: accentColor),
          SizedBox(height: 10),
          _rxnMiniCard(
              badge: 2,
              component: _reactions[1]['component'] as String,
              stoichiometry: _reactions[1]['stoichiometry'] as String,
              value: pair[1],
              accentColor: accentColor),
        ],
      ),
    );
  }

  Widget _rxnMiniCard(
      {required int badge,
      required String component,
      required String stoichiometry,
      required double value,
      required Color accentColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rxnBadge(badge, accentColor),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(component,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                SizedBox(height: 4),
                Text(stoichiometry,
                    style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text(value.toStringAsFixed(2),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accentColor)),
        ],
      ),
    );
  }

  // ── Rxn 1+2+3 constrained triplet dropdown (Scenario 3) ──────────────────
  Widget _rxnTripletDropdownRow(Color accentColor) {
    final triplet = _rxnTriplets[_selectedTripletIndex];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Rxn 1, 2 & 3',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor)),
              SizedBox(width: 4),
              FieldInfoTooltip(description: 'Fractional conversions for Rxn 1 (primary ethane cracking), Rxn 2 (secondary ethane), and Rxn 3 (propane cracking). Only pre-validated triplets are available to ensure mass balance across the full reaction network.'),
              SizedBox(width: 4),
              Expanded(
                child: Text('— only valid combinations',
                    style: TextStyle(fontSize: 10, color: context.textTertiary)),
              ),
            ],
          ),
          SizedBox(height: 8),
          _glassDropdownShell(
            accentColor: accentColor,
            isExpanded: true,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedTripletIndex,
                isExpanded: true,
                dropdownColor: const Color(0xFFF0F4FF),
                icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                items: _rxnTriplets.asMap().entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${e.value[0].toStringAsFixed(2)} / ${e.value[1].toStringAsFixed(2)} / ${e.value[2].toStringAsFixed(2)}'),
                  ),
                )).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedTripletIndex = val;
                    _reactions[0]['value'] = _rxnTriplets[val][0];
                    _reactions[1]['value'] = _rxnTriplets[val][1];
                    _reactions[2]['value'] = _rxnTriplets[val][2];
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          _rxnMiniCard(
              badge: 1,
              component: _reactions[0]['component'] as String,
              stoichiometry: _reactions[0]['stoichiometry'] as String,
              value: triplet[0],
              accentColor: accentColor),
          SizedBox(height: 10),
          _rxnMiniCard(
              badge: 2,
              component: _reactions[1]['component'] as String,
              stoichiometry: _reactions[1]['stoichiometry'] as String,
              value: triplet[1],
              accentColor: accentColor),
          SizedBox(height: 10),
          _rxnMiniCard(
              badge: 3,
              component: _reactions[2]['component'] as String,
              stoichiometry: _reactions[2]['stoichiometry'] as String,
              value: triplet[2],
              accentColor: accentColor),
        ],
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
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['component'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      )),
                  Text(r['stoichiometry'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textTertiary,
                      )),
                ],
              ),
            ),
            FieldInfoTooltip(description: _rxnDescriptions[1]!),
            SizedBox(width: 6),
            _glassDropdownShell(
              accentColor: accentColor,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _selectedRxn1,
                  dropdownColor: const Color(0xFFF0F4FF),
                  icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 18),
                  style: TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.w600),
                  items: _rxn1Values.map((v) => DropdownMenuItem(
                    value: v,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(v.toStringAsFixed(2)),
                    ),
                  )).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() { _selectedRxn1 = val; _reactions[0]['value'] = val; });
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
              colors: [
                Colors.white.withValues(alpha: 0.55),
                accentColor.withValues(alpha: 0.10)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.co2_outlined, color: accentColor, size: 20),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CO₂ Storage Assessment',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accentColor)),
                    SizedBox(height: 2),
                    Text('Geological storage feasibility inputs',
                        style: TextStyle(
                            fontSize: 11, color: context.textTertiary)),
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
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(7)),
          child: Center(
              child: Text(letter,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor))),
        ),
        SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary)),
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _peteField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required Color accentColor,
    String? fieldKey,
    bool isRequired = true,
    String badgeLabel = 'Required',
    String? hint,
    String? description,
    TextInputType keyboardType =
        const TextInputType.numberWithOptions(decimal: true, signed: true),
  }) {
    final hintText = hint ?? (unit != '–' ? unit : 'Enter value');
    final hasError = fieldKey != null && _errorFields.contains(fieldKey);
    final liveRange = fieldKey != null ? _liveRangeErrors[fieldKey] : null;
    final hasLiveError = liveRange != null;
    const errorRed = Color(0xFFE74C3C);
    final effectiveColor = (hasError || hasLiveError) ? errorRed : accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: (hasError || hasLiveError) ? errorRed : AppColors.textLight)),
            ),
            if (description != null) FieldInfoTooltip(description: description),
            _peteBadge(badgeLabel, effectiveColor, isRequired: isRequired),
          ],
        ),
        SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.60),
                    effectiveColor.withValues(alpha: 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: (hasError || hasLiveError)
                        ? errorRed.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.6),
                    width: (hasError || hasLiveError) ? 1.5 : 1.2),
                boxShadow: [
                  BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                      fontSize: 12,
                      color: context.textTertiary.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w400),
                  suffix: unit != '–'
                      ? Text(unit, style: TextStyle(fontSize: 11, color: context.textTertiary.withValues(alpha: 0.75), fontWeight: FontWeight.w500))
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
          ),
        ),
        if (hasLiveError) ...[
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 11, color: Color(0xFFE74C3C)),
                SizedBox(width: 4),
                Expanded(child: Text('Valid range: $liveRange',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFFE74C3C), fontWeight: FontWeight.w600, height: 1.4))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _yesNoToggle(Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['Yes', 'No'].map((label) {
        final selected =
            label == 'Yes' ? _hasReservoirInfo : !_hasReservoirInfo;
        return GestureDetector(
          onTap: () => setState(() => _hasReservoirInfo = label == 'Yes'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            margin: EdgeInsets.only(left: label == 'No' ? 6 : 0),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [accentColor, AppColors.primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: selected ? null : AppColors.inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? Colors.transparent : AppColors.inputBorder),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMedium,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.textPrimary,
        ));
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      final raw = _ctrl!.value;
      // compress on forward (0→1 maps 1.0→0.93), bounce on reverse with overshoot
      setState(() => _scale = 1.0 - (raw * 0.07));
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
              Icon(widget.icon, color: context.surface, size: 20),
              SizedBox(width: 8),
              Text(widget.text, style: AppTextStyles.buttonText),
            ],
          ),
        ),
      ),
    );
  }
}
