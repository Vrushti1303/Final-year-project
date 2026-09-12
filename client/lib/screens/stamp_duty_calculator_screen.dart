import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/user_profile_button.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';

class StampDutyCalculatorScreen extends ConsumerStatefulWidget {
  const StampDutyCalculatorScreen({super.key});

  @override
  ConsumerState<StampDutyCalculatorScreen> createState() => _StampDutyCalculatorScreenState();
}

class _StampDutyCalculatorScreenState extends ConsumerState<StampDutyCalculatorScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _propertyValueController = TextEditingController();
  final TextEditingController _circleRateController = TextEditingController();

  String? _selectedPropertyType;
  String? _selectedState;
  String? _selectedGender;
  String? _isFirstTimeBuyer;

  bool _hasCalculated = false;
  Offset _mousePos = const Offset(600, 300);

  // Animation Controllers
  AnimationController? _ambientController;
  Animation<double>? _pulseAnimation;
  AnimationController? _entryController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

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

  void _initControllers() {
    if (_entryController == null) {
      _entryController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
      );
      _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
      );
      _entryController!.forward();
    }

    _ambientController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    _pulseAnimation ??= Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ambientController!, curve: Curves.easeInOutSine),
    );
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _entryController?.dispose();
    _ambientController?.dispose();
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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (propVal <= 0 && circleVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('calc.validValueError')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
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

    // State specific adjustments
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

    // Maharashtra registration fee cap rule (1% up to ₹30,000)
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
    _initControllers();
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    final bgGradientColors = isDark
        ? const [
            Color(0xFF162B43),
            Color(0xFF13253A),
            Color(0xFF101F31),
          ]
        : const [
            Color(0xFFFBF8EE),
            Color(0xFFF7F1D0),
            Color(0xFFF4EFE0),
          ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
      body: MouseRegion(
        onHover: (event) {
          if (isDesktop) {
            setState(() => _mousePos = event.position);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgGradientColors,
            ),
          ),
          child: Stack(
            children: [
              // ==========================================
              // AMBIENT LIGHTING (CYAN PRIMARY FOR STAMP DUTY)
              // ==========================================
              AnimatedBuilder(
                animation: _ambientController!,
                builder: (context, child) {
                  final pulse = _pulseAnimation?.value ?? 1.0;
                  return Stack(
                    children: [
                      // Orb 1: Top-Left Cyan Ambient Aurora
                      Positioned(
                        top: -140 + (25 * _ambientController!.value),
                        left: -120 + (20 * _ambientController!.value),
                        child: IgnorePointer(
                          child: Container(
                            width: 580 * pulse,
                            height: 580 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.14 : 0.08),
                                  const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.06 : 0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 2: Bottom-Right Gold Ambient Aurora
                      Positioned(
                        bottom: -100 + (30 * (1.0 - _ambientController!.value)),
                        right: -140,
                        child: IgnorePointer(
                          child: Container(
                            width: 620 * (2.0 - pulse),
                            height: 620 * (2.0 - pulse),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.09 : 0.05),
                                  const Color(0xFFFFDF8C).withValues(alpha: isDark ? 0.04 : 0.02),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 3: Mouse-responsive Interactive Spotlight (Desktop)
                      if (isDesktop)
                        Positioned(
                          left: _mousePos.dx - 350,
                          top: _mousePos.dy - 350,
                          child: IgnorePointer(
                            child: Container(
                              width: 700,
                              height: 700,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.045 : 0.025),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // ==========================================
              // MAIN CONTENT
              // ==========================================
              SafeArea(
                child: Column(
                  children: [
                    // TOP BAR
                    _buildTopBar(context, isDark, loc),

                    // BODY CONTENT
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                        child: SlideTransition(
                          position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 48.0 : 20.0,
                              vertical: 16.0,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 880),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // HERO HEADER
                                    _buildHeroHeader(isDark, loc, isDesktop),
                                    const SizedBox(height: 24),

                                    // CALCULATOR FORM CARD
                                    _buildCalculatorFormCard(context, isDark, loc, isDesktop),

                                    // RESULTS BREAKDOWN SECTION
                                    if (_hasCalculated) ...[
                                      const SizedBox(height: 28),
                                      _buildResultSummaryCard(context, isDark, loc),
                                    ],

                                    const SizedBox(height: 24),

                                    // STATUTORY DISCLAIMER
                                    _buildDisclaimerBox(context, isDark, loc),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, bool isDark, LocaleNotifier loc) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: Back button
          Align(
            alignment: Alignment.centerLeft,
            child: _HoverGlassButton(
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.translate('common.back'),
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Exact dead-center badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.35 : 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF38BDF8),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF38BDF8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STATUTORY TAX & REGISTRY CALCULATOR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF38BDF8),
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Profile Button
          const Align(
            alignment: Alignment.centerRight,
            child: UserProfileButton(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HERO HEADER
  // ==========================================
  Widget _buildHeroHeader(bool isDark, LocaleNotifier loc, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Eyebrow Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.14 : 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF38BDF8),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF38BDF8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'STATE REGISTRATION ACT • CIRCLE RATES • STAMP REBATES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Main Title
        Text(
          loc.translate('calc.screenTitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 30 : 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: isDark ? Colors.white : const Color(0xFF101F31),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            loc.translate('calc.screenSubtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 14 : 13,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CALCULATOR FORM CARD
  // ==========================================
  Widget _buildCalculatorFormCard(BuildContext context, bool isDark, LocaleNotifier loc, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.95) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('calc.cardTitle'),
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF101F31),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Input deed consideration, circle valuation & concessions',
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Form Inputs Grid
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
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedPropertyType = val),
                );

                Widget stateField = _buildDropdownField(
                  label: loc.translate('calc.state'),
                  value: _selectedState,
                  hintText: loc.translate('calc.selectState'),
                  items: _states,
                  icon: Icons.location_on_rounded,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedState = val),
                );

                Widget propertyValueField = _buildTextField(
                  label: loc.translate('calc.agreementValue'),
                  hint: loc.translate('calc.enterAgreementValue'),
                  controller: _propertyValueController,
                  icon: Icons.currency_rupee_rounded,
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
                          const SizedBox(width: 18),
                          Expanded(child: stateField),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: propertyValueField),
                          const SizedBox(width: 18),
                          Expanded(child: circleRateField),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: genderField),
                          const SizedBox(width: 18),
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

            const SizedBox(height: 30),

            // Action Buttons: Calculate & Reset
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _HoverCalculateButton(
                    onTap: _calculateStampDuty,
                    label: loc.translate('calc.calculateBtn'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 1,
                  child: _HoverResetButton(
                    onTap: _resetForm,
                    label: loc.translate('calc.resetBtn'),
                    isDark: isDark,
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
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101F31) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  Text(
                    hintText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              items: items.map((String item) {
                final display = itemLabelBuilder != null ? itemLabelBuilder(item) : item;
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
                      const SizedBox(width: 10),
                      Text(
                        display,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
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
    required bool isDark,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF101F31) : Colors.white,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // RESULTS SUMMARY CARD
  // ==========================================
  Widget _buildResultSummaryCard(BuildContext context, bool isDark, LocaleNotifier loc) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.95) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.translate('calc.summaryTitle'),
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? Colors.white : const Color(0xFF101F31),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_rounded, size: 13, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 5),
                    Text(
                      _selectedState ?? '',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _buildResultRow(loc.translate('calc.rowAgreementValue'), _formatIndianRupee(_enteredPropertyValue), isDark),
          const SizedBox(height: 12),
          _buildResultRow(loc.translate('calc.rowCircleRate'), _formatIndianRupee(_enteredCircleRate), isDark),
          const SizedBox(height: 12),
          _buildResultRow(
            loc.translate('calc.rowApplicableMarketValue'),
            _formatIndianRupee(_applicableMarketValue),
            isDark,
            isBold: true,
            highlightColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 0.8, color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
          const SizedBox(height: 16),

          _buildResultRow(
            loc.translate('calc.rowStampDuty', {'rate': _stampDutyRate.toStringAsFixed(1)}),
            _formatIndianRupee(_stampDutyAmount),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            loc.translate('calc.rowRegistration', {'rate': _registrationRate.toStringAsFixed(1)}),
            _formatIndianRupee(_registrationAmount),
            isDark,
          ),
          const SizedBox(height: 22),

          // Total Payable Prominent Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF38BDF8).withValues(alpha: 0.18),
                        const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                      ]
                    : [
                        const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        const Color(0xFF1D4ED8).withValues(alpha: 0.06),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('calc.totalPayable'),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loc.translate('calc.stampPlusReg'),
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatIndianRupee(_totalPayable),
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : const Color(0xFF101F31),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isBold
                ? (isDark ? Colors.white : const Color(0xFF101F31))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: highlightColor ?? (isDark ? Colors.white : const Color(0xFF101F31)),
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DISCLAIMER BOX
  // ==========================================
  Widget _buildDisclaimerBox(BuildContext context, bool isDark, LocaleNotifier loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.6) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.translate('calc.disclaimer'),
              style: GoogleFonts.inter(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HOVER CALCULATE BUTTON
// ==========================================
class _HoverCalculateButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool isDark;

  const _HoverCalculateButton({
    required this.onTap,
    required this.label,
    required this.isDark,
  });

  @override
  State<_HoverCalculateButton> createState() => _HoverCalculateButtonState();
}

class _HoverCalculateButtonState extends State<_HoverCalculateButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: _isHovered ? 0.35 : 0.2),
                blurRadius: _isHovered ? 14 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calculate_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOVER RESET BUTTON
// ==========================================
class _HoverResetButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool isDark;

  const _HoverResetButton({
    required this.onTap,
    required this.label,
    required this.isDark,
  });

  @override
  State<_HoverResetButton> createState() => _HoverResetButtonState();
}

class _HoverResetButtonState extends State<_HoverResetButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark ? const Color(0xFF334356).withValues(alpha: 0.5) : const Color(0xFFE2E8F0))
                : (widget.isDark ? const Color(0xFF101F31) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restart_alt_rounded,
                size: 18,
                color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOVER GLASS BUTTON
// ==========================================
class _HoverGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;

  const _HoverGlassButton({
    required this.child,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_HoverGlassButton> createState() => _HoverGlassButtonState();
}

class _HoverGlassButtonState extends State<_HoverGlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.22) : const Color(0xFF38BDF8).withValues(alpha: 0.18))
                : (widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.7) : const Color(0xFFFBF8EE).withValues(alpha: 0.9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                  : (widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
