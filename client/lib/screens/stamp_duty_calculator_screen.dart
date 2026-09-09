import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/user_profile_button.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';

class StampDutyCalculatorScreen extends ConsumerStatefulWidget {
  const StampDutyCalculatorScreen({super.key});

  @override
  ConsumerState<StampDutyCalculatorScreen> createState() => _StampDutyCalculatorScreenState();
}

class _StampDutyCalculatorScreenState extends ConsumerState<StampDutyCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _propertyValueController = TextEditingController();
  final TextEditingController _circleRateController = TextEditingController();

  String? _selectedPropertyType;
  String? _selectedState;
  String? _selectedGender;
  String? _isFirstTimeBuyer;

  bool _hasCalculated = false;

  // Calculation Results
  double _enteredPropertyValue = 0.0;
  double _enteredCircleRate = 0.0;
  double _applicableMarketValue = 0.0;
  double _stampDutyRate = 0.0;
  double _stampDutyAmount = 0.0;
  double _registrationRate = 0.0;
  double _registrationAmount = 0.0;
  double _totalPayable = 0.0;

  final List<String> _propertyTypes = [
    'Residential',
    'Commercial',
    'Agricultural',
    'Other',
  ];

  final List<String> _states = [
    'Maharashtra',
    'Karnataka',
    'Delhi',
    'Gujarat',
    'Tamil Nadu',
    'West Bengal',
    'Rajasthan',
    'Uttar Pradesh',
    'Other',
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Joint',
  ];

  final List<String> _yesNoOptions = [
    'Yes',
    'No',
  ];

  @override
  void dispose() {
    _propertyValueController.dispose();
    _circleRateController.dispose();
    super.dispose();
  }

  String _getPropertyTypeDisplay(String type, LocaleNotifier loc) {
    switch (type) {
      case 'Residential':
        return loc.translate('calc.typeResidential');
      case 'Commercial':
        return loc.translate('calc.typeCommercial');
      case 'Agricultural':
        return loc.translate('calc.typeAgricultural');
      case 'Other':
        return loc.translate('calc.typeOther');
      default:
        return type;
    }
  }

  String _getGenderDisplay(String gender, LocaleNotifier loc) {
    switch (gender) {
      case 'Male':
        return loc.translate('calc.genderMale');
      case 'Female':
        return loc.translate('calc.genderFemale');
      case 'Joint':
        return loc.translate('calc.genderJoint');
      default:
        return gender;
    }
  }

  String _getYesNoDisplay(String opt, LocaleNotifier loc) {
    switch (opt) {
      case 'Yes':
        return loc.translate('calc.yes');
      case 'No':
        return loc.translate('calc.no');
      default:
        return opt;
    }
  }

  // State-specific and Property-type-specific calculation logic configuration
  void _calculateStampDuty() {
    FocusScope.of(context).unfocus();
    final loc = ref.read(localeProvider.notifier);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double propVal = double.tryParse(_propertyValueController.text.replaceAll(',', '')) ?? 0.0;
    final double circleVal = double.tryParse(_circleRateController.text.replaceAll(',', '')) ?? 0.0;

    if (_selectedPropertyType == null || _selectedState == null || _selectedGender == null || _isFirstTimeBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('calc.fillAllError')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (propVal <= 0 && circleVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('calc.validValueError')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Applicable value is the higher of Property Value or Circle Rate
    final double applicableVal = propVal > circleVal ? propVal : circleVal;

    // Base Stamp Duty Rate determination
    double baseRate = 5.0; // Default Residential

    switch (_selectedPropertyType) {
      case 'Residential':
        baseRate = 5.0;
        break;
      case 'Commercial':
        baseRate = 6.0;
        break;
      case 'Agricultural':
        baseRate = 3.0;
        break;
      case 'Other':
        baseRate = 4.0;
        break;
    }

    // State specific adjustments (Demo config object)
    Map<String, double> stateRateMap = {
      'Maharashtra': 6.0,
      'Karnataka': 5.0,
      'Delhi': 6.0,
      'Gujarat': 4.9,
      'Tamil Nadu': 7.0,
      'West Bengal': 5.0,
      'Rajasthan': 6.0,
      'Uttar Pradesh': 7.0,
      'Other': 5.0,
    };

    double effectiveStampRate = stateRateMap[_selectedState] ?? baseRate;

    // Property type adjustment if non-residential
    if (_selectedPropertyType == 'Commercial') {
      effectiveStampRate += 1.0;
    } else if (_selectedPropertyType == 'Agricultural') {
      effectiveStampRate = (effectiveStampRate - 1.5).clamp(1.0, 10.0);
    }

    // Gender Discount Logic
    if (_selectedGender == 'Female') {
      effectiveStampRate -= 1.0; // 1% concession for female buyers
    } else if (_selectedGender == 'Joint') {
      effectiveStampRate -= 0.5; // 0.5% concession for joint registration
    }

    // First-Time Buyer Discount Logic
    if (_isFirstTimeBuyer == 'Yes') {
      effectiveStampRate -= 0.5;
    }

    // Ensure rate does not drop below 1%
    effectiveStampRate = effectiveStampRate.clamp(1.0, 15.0);

    // Registration Fee: 1% standard
    double regRate = 1.0;
    double regAmount = applicableVal * (regRate / 100.0);

    // Maharashtra registration fee cap rule demo (1% up to ₹30,000)
    if (_selectedState == 'Maharashtra' && regAmount > 30000) {
      regAmount = 30000;
      regRate = (regAmount / applicableVal) * 100.0;
    }

    double stampAmount = applicableVal * (effectiveStampRate / 100.0);
    double total = stampAmount + regAmount;

    setState(() {
      _enteredPropertyValue = propVal;
      _enteredCircleRate = circleVal;
      _applicableMarketValue = applicableVal;
      _stampDutyRate = effectiveStampRate;
      _stampDutyAmount = stampAmount;
      _registrationRate = regRate;
      _registrationAmount = regAmount;
      _totalPayable = total;
      _hasCalculated = true;
    });

    // Sync calculation with MongoDB database
    ApiService.saveStampDutyCalculation({
      'propertyType': _selectedPropertyType,
      'state': _selectedState,
      'agreementValue': propVal,
      'circleRate': circleVal,
      'applicableMarketValue': applicableVal,
      'gender': _selectedGender,
      'firstTimeBuyer': _isFirstTimeBuyer,
      'stampDutyRate': effectiveStampRate,
      'stampDutyAmount': stampAmount,
      'registrationRate': regRate,
      'registrationAmount': regAmount,
      'totalPayable': total,
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _propertyValueController.clear();
    _circleRateController.clear();
    setState(() {
      _selectedPropertyType = null;
      _selectedState = null;
      _selectedGender = null;
      _isFirstTimeBuyer = null;
      _hasCalculated = false;
    });
  }

  // Indian Rupee currency formatter (Lakhs & Crores format)
  String _formatIndianRupee(double amount) {
    if (amount <= 0) return '₹ 0';

    final int val = amount.round();
    final String s = val.toString();
    if (s.length <= 3) return '₹ $s';

    final String lastThree = s.substring(s.length - 3);
    final String remaining = s.substring(0, s.length - 3);

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        result.write(',');
      }
      result.write(remaining[i]);
    }
    result.write(',$lastThree');
    return '₹ ${result.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldAccent = isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B);
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF162B43),
                    Color(0xFF13253A),
                    Color(0xFF101F31),
                  ]
                : const [
                    Color(0xFFFBF8EE),
                    Color(0xFFF7F1D0),
                    Color(0xFFF4EFE0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, colorScheme, isDark, loc),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCalculatorFormCard(context, colorScheme, isDark, goldAccent, loc),
                          if (_hasCalculated) ...[
                            const SizedBox(height: 28),
                            _buildResultSummaryCard(context, colorScheme, isDark, goldAccent, loc),
                          ],
                          const SizedBox(height: 24),
                          _buildDisclaimerBox(context, colorScheme, isDark, loc),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, bool isDark, LocaleNotifier loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B43).withValues(alpha: 0.90) : const Color(0xFFFBF8EE).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2920) : const Color(0xFFF7F1D0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                      ),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.translate('calc.screenTitle'),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      loc.translate('calc.screenSubtitle'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const UserProfileButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorFormCard(BuildContext context, ColorScheme colorScheme, bool isDark, Color purpleAccent, LocaleNotifier loc) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2920) : const Color(0xFFF7F1D0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(26.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: purpleAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: purpleAccent.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.calculate_rounded, color: purpleAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.translate('calc.cardTitle'),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoCol = constraints.maxWidth > 560;

                Widget propertyTypeField = _buildDropdownField(
                  label: loc.translate('calc.propertyType'),
                  value: _selectedPropertyType,
                  hintText: loc.translate('calc.selectPropertyType'),
                  items: _propertyTypes,
                  itemLabelBuilder: (val) => _getPropertyTypeDisplay(val, loc),
                  icon: Icons.home_work_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedPropertyType = val),
                );

                Widget stateField = _buildDropdownField(
                  label: loc.translate('calc.state'),
                  value: _selectedState,
                  hintText: loc.translate('calc.selectState'),
                  items: _states,
                  icon: Icons.location_on_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedState = val),
                );

                Widget propertyValueField = _buildTextField(
                  label: loc.translate('calc.agreementValue'),
                  hint: loc.translate('calc.enterAgreementValue'),
                  controller: _propertyValueController,
                  icon: Icons.currency_rupee_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  validator: (val) {
                    if ((val == null || val.trim().isEmpty) && _circleRateController.text.trim().isEmpty) {
                      return loc.translate('calc.enterAgreementValue');
                    }
                    return null;
                  },
                );

                Widget circleRateField = _buildTextField(
                  label: loc.translate('calc.circleRate'),
                  hint: loc.translate('calc.enterCircleRate'),
                  controller: _circleRateController,
                  icon: Icons.account_balance_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  validator: (val) {
                    if ((val == null || val.trim().isEmpty) && _propertyValueController.text.trim().isEmpty) {
                      return loc.translate('calc.enterCircleRate');
                    }
                    return null;
                  },
                );

                Widget genderField = _buildDropdownField(
                  label: loc.translate('calc.gender'),
                  value: _selectedGender,
                  hintText: loc.translate('calc.selectGender'),
                  items: _genders,
                  itemLabelBuilder: (val) => _getGenderDisplay(val, loc),
                  icon: Icons.person_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedGender = val),
                );

                Widget firstTimeBuyerField = _buildDropdownField(
                  label: loc.translate('calc.firstTimeBuyer'),
                  value: _isFirstTimeBuyer,
                  hintText: loc.translate('calc.selectOption'),
                  items: _yesNoOptions,
                  itemLabelBuilder: (val) => _getYesNoDisplay(val, loc),
                  icon: Icons.verified_user_rounded,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _isFirstTimeBuyer = val),
                );

                if (isTwoCol) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: propertyTypeField),
                          const SizedBox(width: 16),
                          Expanded(child: stateField),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: propertyValueField),
                          const SizedBox(width: 16),
                          Expanded(child: circleRateField),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: genderField),
                          const SizedBox(width: 16),
                          Expanded(child: firstTimeBuyerField),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      propertyTypeField,
                      const SizedBox(height: 16),
                      stateField,
                      const SizedBox(height: 16),
                      propertyValueField,
                      const SizedBox(height: 16),
                      circleRateField,
                      const SizedBox(height: 16),
                      genderField,
                      const SizedBox(height: 16),
                      firstTimeBuyerField,
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 26),

            // Buttons: Calculate & Reset
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: purpleAccent.withValues(alpha: 0.3),
                      ),
                      onPressed: _calculateStampDuty,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calculate_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('calc.calculateBtn'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        side: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _resetForm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restart_alt_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            loc.translate('calc.resetBtn'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hintText,
    required List<String> items,
    String Function(String)? itemLabelBuilder,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Text(
                    hintText,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
              items: items.map((String item) {
                final display = itemLabelBuilder != null ? itemLabelBuilder(item) : item;
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        display,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            prefixIcon: Icon(icon, size: 18, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSummaryCard(BuildContext context, ColorScheme colorScheme, bool isDark, Color purpleAccent, LocaleNotifier loc) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2920) : const Color(0xFFF7F1D0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: purpleAccent.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.translate('calc.summaryTitle'),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedState ?? '',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildResultRow(loc.translate('calc.rowAgreementValue'), _formatIndianRupee(_enteredPropertyValue), colorScheme),
          const SizedBox(height: 10),
          _buildResultRow(loc.translate('calc.rowCircleRate'), _formatIndianRupee(_enteredCircleRate), colorScheme),
          const SizedBox(height: 10),
          _buildResultRow(
            loc.translate('calc.rowApplicableMarketValue'),
            _formatIndianRupee(_applicableMarketValue),
            colorScheme,
            isBold: true,
          ),
          const Divider(height: 24),

          _buildResultRow(
            loc.translate('calc.rowStampDuty', {'rate': _stampDutyRate.toStringAsFixed(1)}),
            _formatIndianRupee(_stampDutyAmount),
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildResultRow(
            loc.translate('calc.rowRegistration', {'rate': _registrationRate.toStringAsFixed(1)}),
            _formatIndianRupee(_registrationAmount),
            colorScheme,
          ),
          const Divider(height: 28),

          // Total Payable Prominent Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: purpleAccent.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('calc.totalPayable'),
                      style: TextStyle(
                        color: purpleAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.translate('calc.stampPlusReg'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatIndianRupee(_totalPayable),
                  style: TextStyle(
                    color: purpleAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, ColorScheme colorScheme, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerBox(BuildContext context, ColorScheme colorScheme, bool isDark, LocaleNotifier loc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2920) : const Color(0xFFF7F1D0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.translate('calc.disclaimer'),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
