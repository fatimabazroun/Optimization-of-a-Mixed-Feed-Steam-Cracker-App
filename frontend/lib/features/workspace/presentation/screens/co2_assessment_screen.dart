import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/field_info_tooltip.dart';
import '../../../../core/services/simulation_service.dart';
import 'co2_assessment_results_screen.dart';

const _green = Color(0xFF27AE60);
const _red = Color(0xFFE74C3C);

class Co2AssessmentScreen extends StatefulWidget {
  const Co2AssessmentScreen({super.key});

  @override
  State<Co2AssessmentScreen> createState() => _Co2AssessmentScreenState();
}

class _Co2AssessmentScreenState extends State<Co2AssessmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;

  // CO₂ rate
  final _co2RateCtrl = TextEditingController();

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

  // C. Pressure constraint
  final _fracPressureCtrl = TextEditingController();
  final _fracGradientCtrl = TextEditingController();
  final _safetyMarginCtrl = TextEditingController();

  // D. Advanced
  final _co2DensityCtrl = TextEditingController();
  final _co2ViscosityCtrl = TextEditingController();
  final _totalCompCtrl = TextEditingController();
  final _wellboreRadiusCtrl = TextEditingController();
  final _skinFactorCtrl = TextEditingController();
  final _co2SaturationCtrl = TextEditingController();
  final _logStartTimeCtrl = TextEditingController();
  final _closedMultCtrl = TextEditingController();

  final Set<String> _errorFields = {};
  final Map<String, String> _fieldRangeErrors = {};
  final Map<String, String> _liveRangeErrors = {};
  bool _running = false;

  static const _fieldRanges = <String, (double, double)>{
    'co2_rate':       (0.001,  10000),
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
    'wellbore_radius':(0.05,   0.3),
    'skin':           (-5,     20),
    'closed_mult':    (1,      5),
    'log_start_time': (0.1,   10),
  };
  bool _showValidationBanner = false;
  String? _runError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _safetyMarginCtrl.text = '1.5';
    _logStartTimeCtrl.text = '1';
    _co2DensityCtrl.text = '700';
    _co2ViscosityCtrl.text = '0.05';
    _totalCompCtrl.text = '0.0001';
    _wellboreRadiusCtrl.text = '0.1';
    _skinFactorCtrl.text = '0';
    _co2SaturationCtrl.text = '0.2';
    _closedMultCtrl.text = '3';

    final listeners = <TextEditingController, String>{
      _co2RateCtrl: 'co2_rate',
      _projDurationCtrl: 'proj_duration',
      _numWellsCtrl: 'n_wells',
      _depthCtrl: 'depth',
      _initPressureCtrl: 'init_pressure',
      _permeabilityCtrl: 'permeability',
      _thicknessCtrl: 'thickness',
      _porosityCtrl: 'porosity',
      _reservoirRadiusCtrl: 'res_radius',
      _fracPressureCtrl: 'frac_pressure',
      _fracGradientCtrl: 'frac_gradient',
      _safetyMarginCtrl: 'safety_margin',
      _co2DensityCtrl: 'co2_density',
      _co2ViscosityCtrl: 'co2_viscosity',
      _totalCompCtrl: 'total_comp',
      _wellboreRadiusCtrl: 'wellbore_radius',
      _skinFactorCtrl: 'skin',
      _co2SaturationCtrl: 'co2_saturation',
      _logStartTimeCtrl: 'log_start_time',
      _closedMultCtrl: 'closed_mult',
    };
    for (final e in listeners.entries) {
      final key = e.value;
      final range = _fieldRanges[key];
      e.key.addListener(() {
        setState(() {
          _errorFields.remove(key);
          _fieldRangeErrors.remove(key);
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
    _fracPressureCtrl.addListener(() => setState(() => _errorFields.remove('frac_gradient')));
    _fracGradientCtrl.addListener(() => setState(() => _errorFields.remove('frac_pressure')));
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
    _co2SaturationCtrl.dispose();
    _logStartTimeCtrl.dispose();
    _closedMultCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  bool _validate() {
    _errorFields.clear();
    _fieldRangeErrors.clear();

    String fmt(double v) =>
        v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

    void req(String key, double? v, double min, double max) {
      if (v == null) { _errorFields.add(key); return; }
      if (v < min || v > max) {
        _errorFields.add(key);
        _fieldRangeErrors[key] = 'entered ${fmt(v)}, valid $min – $max';
      }
    }

    void opt(String key, TextEditingController ctrl, double min, double max) {
      if (ctrl.text.trim().isEmpty) return;
      final v = _parse(ctrl);
      if (v == null || v < min || v > max) {
        _errorFields.add(key);
        if (v != null) _fieldRangeErrors[key] = 'entered ${fmt(v)}, valid $min – $max';
      }
    }

    // CO₂ rate: > 0, max 10 000
    final co2Rate = _parse(_co2RateCtrl);
    if (co2Rate == null || co2Rate <= 0) {
      _errorFields.add('co2_rate');
    } else if (co2Rate > 10000) {
      _errorFields.add('co2_rate');
      _fieldRangeErrors['co2_rate'] = 'entered ${fmt(co2Rate)}, valid > 0 – 10,000';
    }

    req('proj_duration', _parse(_projDurationCtrl), 1,    50);
    req('n_wells',       _parse(_numWellsCtrl),      1,    10);
    req('depth',         _parse(_depthCtrl),          800,  3000);
    req('init_pressure', _parse(_initPressureCtrl),   5,    50);
    req('permeability',  _parse(_permeabilityCtrl),   0.1,  1000);
    req('thickness',     _parse(_thicknessCtrl),      5,    100);
    req('porosity',      _parse(_porosityCtrl),       0.05, 0.4);
    req('res_radius',    _parse(_reservoirRadiusCtrl),500,  10000);

    // Fracture pressure / gradient
    final hasFracP = _fracPressureCtrl.text.trim().isNotEmpty;
    final hasFracG = _fracGradientCtrl.text.trim().isNotEmpty;
    if (!hasFracP && !hasFracG) {
      _errorFields.add('frac_pressure');
      _errorFields.add('frac_gradient');
    } else {
      if (hasFracP) {
        final v = _parse(_fracPressureCtrl);
        if (v == null || v <= 0) _errorFields.add('frac_pressure');
      }
      if (hasFracG) opt('frac_gradient', _fracGradientCtrl, 0.015, 0.025);
    }

    // Optional advanced — always pre-filled with defaults so always validated
    opt('safety_margin',  _safetyMarginCtrl,  1,    5);
    opt('co2_density',    _co2DensityCtrl,    500,  900);
    opt('co2_viscosity',  _co2ViscosityCtrl,  0.03, 0.1);
    opt('co2_saturation', _co2SaturationCtrl, 0.05, 0.6);
    opt('total_comp',     _totalCompCtrl,     1e-5, 1e-3);
    opt('wellbore_radius',_wellboreRadiusCtrl,0.05, 0.3);
    opt('skin',           _skinFactorCtrl,    -5,   20);
    opt('log_start_time', _logStartTimeCtrl,  0.1,  10);
    if (_reservoirType == 'Closed') opt('closed_mult', _closedMultCtrl, 1, 5);

    return _errorFields.isEmpty;
  }

  Map<String, dynamic> _buildReservoirInputs() {
    return {
      'project_duration': _parse(_projDurationCtrl)!,
      'n_wells': _parse(_numWellsCtrl)!.toInt(),
      'depth': _parse(_depthCtrl)!,
      'initial_pressure': _parse(_initPressureCtrl)!,
      'permeability': _parse(_permeabilityCtrl)!,
      'thickness': _parse(_thicknessCtrl)!,
      'porosity': _parse(_porosityCtrl)!,
      'radius': _parse(_reservoirRadiusCtrl)!,
      'reservoir_type': _reservoirType,
      if (_fracPressureCtrl.text.trim().isNotEmpty)
        'fracture_pressure': _parse(_fracPressureCtrl)!,
      if (_fracGradientCtrl.text.trim().isNotEmpty)
        'fracture_gradient': _parse(_fracGradientCtrl)!,
      if (_safetyMarginCtrl.text.trim().isNotEmpty)
        'safety_margin': _parse(_safetyMarginCtrl)!,
      if (_co2DensityCtrl.text.trim().isNotEmpty)
        'co2_density': _parse(_co2DensityCtrl)!,
      if (_co2ViscosityCtrl.text.trim().isNotEmpty)
        'co2_viscosity': _parse(_co2ViscosityCtrl)!,
      if (_totalCompCtrl.text.trim().isNotEmpty)
        'compressibility': _parse(_totalCompCtrl)!,
      if (_wellboreRadiusCtrl.text.trim().isNotEmpty)
        'well_radius': _parse(_wellboreRadiusCtrl)!,
      if (_skinFactorCtrl.text.trim().isNotEmpty)
        'skin': _parse(_skinFactorCtrl)!,
      if (_co2SaturationCtrl.text.trim().isNotEmpty)
        'co2_saturation': _parse(_co2SaturationCtrl)!,
      if (_logStartTimeCtrl.text.trim().isNotEmpty)
        'log_start_time': _parse(_logStartTimeCtrl)!,
      if (_reservoirType == 'Closed' && _closedMultCtrl.text.trim().isNotEmpty)
        'closed_multiplier': _parse(_closedMultCtrl)!,
    };
  }

  Future<void> _runAssessment() async {
    setState(() => _runError = null);
    if (!_validate()) {
      setState(() => _showValidationBanner = true);
      return;
    }
    setState(() { _showValidationBanner = false; _running = true; });
    try {
      final res = await SimulationService.runCo2Assessment(
        co2RateKgHr: _parse(_co2RateCtrl)!,
        reservoirInputs: _buildReservoirInputs(),
      );
      if (mounted) {
        setState(() => _running = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Co2AssessmentResultsScreen(result: res)),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _runError = e.toString().replaceFirst('Exception: ', ''); _running = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
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
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16, color: context.textSecondary),
                        SizedBox(width: 4),
                        Text('Back to Workspace', style: TextStyle(fontSize: 14, color: context.textSecondary)),
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
                        // Title
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.co2_outlined, color: _green, size: 22),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CO₂ Assessment', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.2)),
                                  Text('PETE geological storage feasibility', style: TextStyle(fontSize: 14, color: context.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 28),

                        // CO₂ rate input
                        _sectionTitle('CO₂ Rate'),
                        SizedBox(height: 12),
                        _sectionCard(
                          child: _peteField(
                            label: 'CO₂ emission rate (q_CO₂)',
                            unit: 'kg/hr',
                            controller: _co2RateCtrl,
                            fieldKey: 'co2_rate',
                            hint: 'e.g. 1200',
                            description: 'Total CO₂ mass flow rate to be injected into the geological reservoir.',
                          ),
                        ),

                        SizedBox(height: 24),

                        // A. Project Inputs
                        _peteSubHeader('A', 'Project Inputs'),
                        SizedBox(height: 12),
                        _sectionCard(
                          child: Column(
                            children: [
                              _peteField(
                                label: 'Project duration (T_proj)',
                                unit: 'years',
                                controller: _projDurationCtrl,
                                fieldKey: 'proj_duration',
                                description: '1 – 50 years. Total planned CO₂ injection period. Determines how long pressure and plume radius are simulated.',
                              ),
                              SizedBox(height: 14),
                              _peteField(
                                label: 'Number of wells (N_w)',
                                unit: '–',
                                controller: _numWellsCtrl,
                                fieldKey: 'n_wells',
                                keyboardType: TextInputType.number,
                                description: '1 – 10. Total injection wells. CO₂ flow rate is split equally across all wells.',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // B. Reservoir Inputs
                        _peteSubHeader('B', 'Reservoir Inputs'),
                        SizedBox(height: 12),
                        _sectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Depth (D)', unit: 'm', controller: _depthCtrl, fieldKey: 'depth', description: '800 – 3000 m. Vertical depth to the reservoir. Deeper reservoirs generally have higher pressures and better containment.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Initial pressure (P_i)', unit: 'MPa', controller: _initPressureCtrl, fieldKey: 'init_pressure', description: '5 – 50 MPa. Reservoir pressure before CO₂ injection begins. Used as the baseline for pressure build-up calculations.')),
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Permeability (k)', unit: 'mD', controller: _permeabilityCtrl, fieldKey: 'permeability', description: '0.1 – 1000 mD. Rock\'s ability to allow fluid flow. Higher permeability means CO₂ spreads more easily and pressure builds more slowly.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Thickness (h)', unit: 'm', controller: _thicknessCtrl, fieldKey: 'thickness', description: '5 – 100 m. Net pay thickness of the injection zone. Thicker zones can store more CO₂ at lower pressure.')),
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Porosity (ϕ)', unit: '–', controller: _porosityCtrl, fieldKey: 'porosity', hint: '0 – 1', description: '0.05 – 0.4. Fraction of rock volume that is pore space. Higher porosity means greater storage capacity.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Reservoir radius (r_e)', unit: 'm', controller: _reservoirRadiusCtrl, fieldKey: 'res_radius', description: '500 – 10000 m. Outer boundary radius of the reservoir. Used to determine whether the CO₂ plume stays within safe limits.')),
                                ],
                              ),
                              SizedBox(height: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Reservoir type', style: TextStyle(fontSize: 12, color: context.textTertiary)),
                                      const Spacer(),
                                      _badge('Required'),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  _glassDropdown(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // C. Pressure Constraint
                        _peteSubHeader('C', 'Pressure Constraint'),
                        SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _green.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Either / Or', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _green)),
                              ),
                              SizedBox(width: 8),
                              Text('Provide at least one of the two fields below', style: TextStyle(fontSize: 11, color: context.textTertiary)),
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
                                fieldKey: 'frac_pressure',
                                isRequired: false,
                                badgeLabel: 'Either / Or',
                                description: 'Maximum allowable bottomhole pressure before the rock fractures. Injection must stay below this to avoid caprock damage. Provide this OR fracture gradient.',
                              ),
                              SizedBox(height: 14),
                              _peteField(
                                label: 'Fracture gradient (G_f)',
                                unit: 'MPa/m',
                                controller: _fracGradientCtrl,
                                fieldKey: 'frac_gradient',
                                isRequired: false,
                                badgeLabel: 'Either / Or',
                                description: '0.015 – 0.025 MPa/m. Fracture pressure per unit depth. The app multiplies this by depth to compute the fracture pressure limit. Provide this OR fracture pressure.',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // D. Advanced Inputs
                        _peteSubHeader('D', 'Advanced Inputs'),
                        SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('All fields optional — leave blank to use defaults', style: TextStyle(fontSize: 11, color: context.textTertiary)),
                        ),
                        _sectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'CO₂ density (ρ)', unit: 'kg/m³', controller: _co2DensityCtrl, fieldKey: 'co2_density', isRequired: false, badgeLabel: 'Optional', hint: 'default: 700', description: '500 – 900 kg/m³. CO₂ density at reservoir conditions.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'CO₂ viscosity (μ)', unit: 'cP', controller: _co2ViscosityCtrl, fieldKey: 'co2_viscosity', isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.05', description: '0.03 – 0.1 cP. CO₂ viscosity at reservoir T and P.')),
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Total compressibility (c_t)', unit: '1/MPa', controller: _totalCompCtrl, fieldKey: 'total_comp', isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.0001', description: '1e-5 – 1e-3 /MPa. Combined compressibility of rock and fluids.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Wellbore radius (r_w)', unit: 'm', controller: _wellboreRadiusCtrl, fieldKey: 'wellbore_radius', isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.1', description: '0.05 – 0.3 m. Physical radius of the injection well.')),
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Skin factor (s)', unit: '–', controller: _skinFactorCtrl, fieldKey: 'skin', isRequired: false, badgeLabel: 'Optional', hint: 'default: 0', description: '-5 – 20. 0 = undamaged. Positive = damage; negative = stimulation.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'CO₂ saturation (S_CO₂)', unit: '–', controller: _co2SaturationCtrl, fieldKey: 'co2_saturation', isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.2', description: '0.05 – 0.6. Effective CO₂ saturation in pore space. Used to estimate plume radius.')),
                                ],
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Safety margin (ΔP_safe)', unit: 'MPa', controller: _safetyMarginCtrl, fieldKey: 'safety_margin', isRequired: false, badgeLabel: 'Optional', hint: 'default: 1.5', description: '1 – 5 MPa. Pressure buffer below fracture limit.')),
                                  SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Log start time (t₀)', unit: 'days', controller: _logStartTimeCtrl, fieldKey: 'log_start_time', isRequired: false, badgeLabel: 'Optional', hint: 'default: 1', description: '0.1 – 10 days. Lower bound to avoid log(0) at early time.')),
                                ],
                              ),
                              if (_reservoirType == 'Closed') ...[
                                SizedBox(height: 14),
                                _peteField(
                                  label: 'Closed multiplier (α)',
                                  unit: '–',
                                  controller: _closedMultCtrl,
                                  fieldKey: 'closed_mult',
                                  isRequired: false,
                                  badgeLabel: 'Optional',
                                  hint: 'default: 3',
                                  description: '1 – 5. Pressure buildup multiplier for closed boundary.',
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Validation banner
                        if (_showValidationBanner) _validationBanner(),

                        // Run button
                        _RunButton(running: _running, onTap: _runAssessment),

                        SizedBox(height: 24),

                        if (_runError != null) _errorCard(_runError!),

                        SizedBox(height: 48),
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

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
      );

  Widget _sectionCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: context.cardShadow, blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _peteSubHeader(String letter, String title) => Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text(letter, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _green))),
          ),
          SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
        ],
      );

  Widget _badge(String label, {bool isRequired = true}) {
    final Color bg = isRequired ? _green.withValues(alpha: 0.11) : AppColors.textLight.withValues(alpha: 0.10);
    final Color fg = isRequired ? _green : AppColors.textLight;
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
    String? fieldKey,
    bool isRequired = true,
    String badgeLabel = 'Required',
    String? hint,
    String? description,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true, signed: true),
  }) {
    final hasError = fieldKey != null && _errorFields.contains(fieldKey);
    final liveRange = fieldKey != null ? _liveRangeErrors[fieldKey] : null;
    const errorRed = Color(0xFFE74C3C);
    final hasLiveError = liveRange != null;
    final accent = (hasError || hasLiveError) ? errorRed : _green;
    final hintText = hint ?? (unit != '–' ? unit : 'Enter value');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: hasError ? errorRed : AppColors.textLight))),
            if (description != null) FieldInfoTooltip(description: description),
            _badge(badgeLabel, isRequired: isRequired),
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
                  colors: [Colors.white.withValues(alpha: 0.60), accent.withValues(alpha: 0.07)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: hasError ? errorRed.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.6),
                  width: hasError ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: 12, color: context.textTertiary.withValues(alpha: 0.65), fontWeight: FontWeight.w400),
                  suffix: unit != '–'
                      ? Text(unit, style: TextStyle(fontSize: 11, color: context.textTertiary.withValues(alpha: 0.75), fontWeight: FontWeight.w500))
                      : null,
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
        if (hasLiveError) ...[
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 11, color: Color(0xFFE74C3C)),
                SizedBox(width: 4),
                Expanded(child: Text('Valid range: $liveRange', style: TextStyle(fontSize: 10.5, color: Color(0xFFE74C3C), fontWeight: FontWeight.w600, height: 1.4))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _glassDropdown() => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.55), _green.withValues(alpha: 0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
              boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.15), blurRadius: 16, spreadRadius: 1, offset: const Offset(0, 4))],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reservoirType,
                isExpanded: true,
                dropdownColor: const Color(0xFFF0F4FF).withValues(alpha: 0.97),
                icon: Icon(Icons.keyboard_arrow_down, color: _green, size: 18),
                style: TextStyle(fontSize: 14, color: _green, fontWeight: FontWeight.w600),
                items: ['Open', 'Closed'].map((v) => DropdownMenuItem(
                  value: v,
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(v)),
                )).toList(),
                onChanged: (val) => setState(() => _reservoirType = val!),
              ),
            ),
          ),
        ),
      );

  static const _fieldLabels = {
    'co2_rate':      'CO₂ emission rate',
    'proj_duration': 'Project duration',
    'n_wells':       'Number of wells',
    'depth':         'Depth',
    'init_pressure': 'Initial pressure',
    'permeability':  'Permeability',
    'thickness':     'Thickness',
    'porosity':      'Porosity',
    'res_radius':    'Reservoir radius',
    'frac_pressure': 'Fracture pressure',
    'frac_gradient': 'Fracture gradient',
    'safety_margin': 'Safety margin',
    'co2_density':   'CO₂ density',
    'co2_viscosity': 'CO₂ viscosity',
    'co2_saturation':'CO₂ saturation',
    'total_comp':    'Total compressibility',
    'wellbore_radius':'Wellbore radius',
    'skin':          'Skin factor',
    'closed_mult':    'Closed multiplier',
    'log_start_time': 'Log start time',
  };

  Widget _validationBanner() {
    final missing = <String>[];
    final outOfRange = <String>[];

    for (final key in _errorFields) {
      final label = _fieldLabels[key] ?? key;
      if (_fieldRangeErrors.containsKey(key)) {
        outOfRange.add('$label: ${_fieldRangeErrors[key]}');
      } else {
        missing.add(label);
      }
    }

    // frac pressure/gradient share one logical requirement
    final hasBothFrac = missing.contains('Fracture pressure') && missing.contains('Fracture gradient');
    if (hasBothFrac) {
      missing
        ..remove('Fracture pressure')
        ..remove('Fracture gradient')
        ..add('Fracture pressure or Fracture gradient (at least one)');
    }
    missing.sort();
    outOfRange.sort();

    Widget bulletRow(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 12, color: _red)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4))),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withValues(alpha: 0.30), width: 1.2),
        boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _red, size: 18),
              SizedBox(width: 8),
              Text('Fix the following before running', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
            ],
          ),
          if (missing.isNotEmpty) ...[
            SizedBox(height: 10),
            Text('Missing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textTertiary)),
            SizedBox(height: 4),
            ...missing.map(bulletRow),
          ],
          if (outOfRange.isNotEmpty) ...[
            SizedBox(height: 10),
            Text('Out of range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textTertiary)),
            SizedBox(height: 4),
            ...outOfRange.map(bulletRow),
          ],
        ],
      ),
    );
  }

  Widget _errorCard(String message) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _red.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _red.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(Icons.error_outline, color: _red, size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assessment Failed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  SizedBox(height: 4),
                  Text(message, style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

}

class _RunButton extends StatelessWidget {
  final bool running;
  final VoidCallback onTap;

  const _RunButton({required this.running, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: running ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: running
                    ? [_green.withValues(alpha: 0.5), const Color(0xFF1A6B40).withValues(alpha: 0.5)]
                    : [_green, const Color(0xFF1A6B40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(color: _green.withValues(alpha: running ? 0.15 : 0.40), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (running)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: context.surface, strokeWidth: 2))
                else
                  Icon(Icons.analytics_outlined, color: context.surface, size: 20),
                SizedBox(width: 10),
                Text(
                  running ? 'Running Assessment…' : 'Run CO₂ Assessment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
