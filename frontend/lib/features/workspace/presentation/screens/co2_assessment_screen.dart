import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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
  final _closedMultCtrl = TextEditingController();

  final Set<String> _errorFields = {};
  bool _running = false;
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
    _co2DensityCtrl.text = '700';
    _co2ViscosityCtrl.text = '0.05';
    _totalCompCtrl.text = '0.0001';
    _wellboreRadiusCtrl.text = '0.1';
    _skinFactorCtrl.text = '0';
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
    };
    for (final e in listeners.entries) {
      final key = e.value;
      e.key.addListener(() {
        if (_errorFields.contains(key)) setState(() => _errorFields.remove(key));
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
    _closedMultCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  bool _validate() {
    _errorFields.clear();

    final co2Rate = _parse(_co2RateCtrl);
    if (co2Rate == null || co2Rate <= 0) _errorFields.add('co2_rate');

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
      final v = _parse(e.value);
      if (v == null || v <= 0) _errorFields.add(e.key);
    }

    final phi = _parse(_porosityCtrl);
    if (phi == null || phi < 0 || phi > 1) _errorFields.add('porosity');

    final hasFracP = _fracPressureCtrl.text.trim().isNotEmpty;
    final hasFracG = _fracGradientCtrl.text.trim().isNotEmpty;
    if (!hasFracP && !hasFracG) {
      _errorFields.add('frac_pressure');
      _errorFields.add('frac_gradient');
    } else {
      if (hasFracP && (_parse(_fracPressureCtrl) ?? 0) <= 0) _errorFields.add('frac_pressure');
      if (hasFracG && (_parse(_fracGradientCtrl) ?? 0) <= 0) _errorFields.add('frac_gradient');
    }

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
                        Text('Back to Workspace', style: AppTextStyles.body),
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
                              child: const Icon(Icons.co2_outlined, color: _green, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CO₂ Assessment', style: AppTextStyles.heading1),
                                  Text('PETE geological storage feasibility', style: AppTextStyles.body),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // CO₂ rate input
                        _sectionTitle('CO₂ Rate'),
                        const SizedBox(height: 12),
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

                        const SizedBox(height: 24),

                        // A. Project Inputs
                        _peteSubHeader('A', 'Project Inputs'),
                        const SizedBox(height: 12),
                        _sectionCard(
                          child: Column(
                            children: [
                              _peteField(
                                label: 'Project duration (T_proj)',
                                unit: 'years',
                                controller: _projDurationCtrl,
                                fieldKey: 'proj_duration',
                              ),
                              const SizedBox(height: 14),
                              _peteField(
                                label: 'Number of wells (N_w)',
                                unit: '–',
                                controller: _numWellsCtrl,
                                fieldKey: 'n_wells',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // B. Reservoir Inputs
                        _peteSubHeader('B', 'Reservoir Inputs'),
                        const SizedBox(height: 12),
                        _sectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Depth (D)', unit: 'm', controller: _depthCtrl, fieldKey: 'depth')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Initial pressure (P_i)', unit: 'MPa', controller: _initPressureCtrl, fieldKey: 'init_pressure')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Permeability (k)', unit: 'mD', controller: _permeabilityCtrl, fieldKey: 'permeability')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Thickness (h)', unit: 'm', controller: _thicknessCtrl, fieldKey: 'thickness')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Porosity (ϕ)', unit: '–', controller: _porosityCtrl, fieldKey: 'porosity', hint: '0 – 1')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Reservoir radius (r_e)', unit: 'm', controller: _reservoirRadiusCtrl, fieldKey: 'res_radius')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Reservoir type', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                      const Spacer(),
                                      _badge('Required'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _glassDropdown(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // C. Pressure Constraint
                        _peteSubHeader('C', 'Pressure Constraint'),
                        const SizedBox(height: 6),
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
                                child: const Text('Either / Or', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _green)),
                              ),
                              const SizedBox(width: 8),
                              const Text('Provide at least one of the two fields below', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
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
                              ),
                              const SizedBox(height: 14),
                              _peteField(
                                label: 'Fracture gradient (G_f)',
                                unit: 'MPa/m',
                                controller: _fracGradientCtrl,
                                fieldKey: 'frac_gradient',
                                isRequired: false,
                                badgeLabel: 'Either / Or',
                              ),
                              const SizedBox(height: 14),
                              _peteField(
                                label: 'Safety margin (ΔP_safe)',
                                unit: 'MPa',
                                controller: _safetyMarginCtrl,
                                isRequired: false,
                                badgeLabel: 'Optional',
                                hint: 'default: 1.5',
                                description: 'Pressure buffer kept below the fracture limit to avoid reservoir damage.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // D. Advanced Inputs
                        _peteSubHeader('D', 'Advanced Inputs'),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('All fields optional — leave blank to use defaults', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ),
                        _sectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'CO₂ density (ρ)', unit: 'kg/m³', controller: _co2DensityCtrl, isRequired: false, badgeLabel: 'Optional', hint: 'default: 700', description: 'CO₂ density at reservoir conditions.')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'CO₂ viscosity (μ)', unit: 'cP', controller: _co2ViscosityCtrl, isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.05', description: 'CO₂ viscosity at reservoir T and P.')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Total compressibility (c_t)', unit: '1/MPa', controller: _totalCompCtrl, isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.0001', description: 'Combined compressibility of rock and fluids.')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _peteField(label: 'Wellbore radius (r_w)', unit: 'm', controller: _wellboreRadiusCtrl, isRequired: false, badgeLabel: 'Optional', hint: 'default: 0.1', description: 'Physical radius of the injection well.')),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _peteField(label: 'Skin factor (s)', unit: '–', controller: _skinFactorCtrl, isRequired: false, badgeLabel: 'Optional', hint: 'default: 0', description: '0 = undamaged. Positive = damage; negative = stimulation.')),
                                  const SizedBox(width: 12),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                              if (_reservoirType == 'Closed') ...[
                                const SizedBox(height: 14),
                                _peteField(
                                  label: 'Closed multiplier (α)',
                                  unit: '–',
                                  controller: _closedMultCtrl,
                                  isRequired: false,
                                  badgeLabel: 'Optional',
                                  hint: 'default: 3',
                                  description: 'Multiplier for closed boundary effects.',
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Validation banner
                        if (_showValidationBanner) _validationBanner(),

                        // Run button
                        _RunButton(running: _running, onTap: _runAssessment),

                        const SizedBox(height: 24),

                        if (_runError != null) _errorCard(_runError!),

                        const SizedBox(height: 48),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkBase),
      );

  Widget _sectionCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4)),
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
            child: Center(child: Text(letter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _green))),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
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
    const errorRed = Color(0xFFE74C3C);
    final accent = hasError ? errorRed : _green;
    final hintText = hint ?? (unit != '–' ? unit : 'Enter value');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: hasError ? errorRed : AppColors.textLight))),
            _badge(badgeLabel, isRequired: isRequired),
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
        if (description != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(description, style: TextStyle(fontSize: 10.5, color: AppColors.textLight.withValues(alpha: 0.8), height: 1.4)),
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
                icon: const Icon(Icons.keyboard_arrow_down, color: _green, size: 18),
                style: const TextStyle(fontSize: 14, color: _green, fontWeight: FontWeight.w600),
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
    'co2_rate': 'CO₂ emission rate',
    'proj_duration': 'Project duration',
    'n_wells': 'Number of wells',
    'depth': 'Depth',
    'init_pressure': 'Initial pressure',
    'permeability': 'Permeability',
    'thickness': 'Thickness',
    'porosity': 'Porosity',
    'res_radius': 'Reservoir radius',
    'frac_pressure': 'Fracture pressure',
    'frac_gradient': 'Fracture gradient',
  };

  Widget _validationBanner() {
    final missing = _errorFields
        .map((k) => _fieldLabels[k] ?? k)
        .toSet()
        .toList()
      ..sort();

    // frac pressure/gradient share one logical requirement
    final hasBothFrac = missing.contains('Fracture pressure') && missing.contains('Fracture gradient');
    if (hasBothFrac) {
      missing
        ..remove('Fracture pressure')
        ..remove('Fracture gradient')
        ..add('Fracture pressure or Fracture gradient (at least one)');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withValues(alpha: 0.30), width: 1.2),
        boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _red, size: 18),
              SizedBox(width: 8),
              Text('Please complete the required fields', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
            ],
          ),
          const SizedBox(height: 10),
          ...missing.map((label) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 12, color: _red)),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _errorCard(String message) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _red.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _red.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, color: _red, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assessment Failed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBase)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
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
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  running ? 'Running Assessment…' : 'Run CO₂ Assessment',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
