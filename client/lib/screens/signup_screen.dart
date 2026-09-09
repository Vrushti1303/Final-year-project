import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'login_screen.dart';
import 'otp_screen.dart';


class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _identifierFocusNode = FocusNode();

  bool _isEmailMode = true;
  bool _isHoveredButton = false;
  bool _isNameFocused = false;
  bool _isIdentifierFocused = false;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _nameFocusNode.addListener(() {
      setState(() => _isNameFocused = _nameFocusNode.hasFocus);
    });

    _identifierFocusNode.addListener(() {
      setState(() => _isIdentifierFocused = _identifierFocusNode.hasFocus);
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _nameFocusNode.dispose();
    _identifierFocusNode.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isEmailMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mobile OTP coming soon. Please use email.')),
        );
        return;
      }

      final String name = _nameController.text.trim();
      final String identifier = _identifierController.text.trim();

      final success = await ref.read(authProvider.notifier).sendOtp(
        email: identifier,
        type: 'signup',
      );

      if (success && mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => OtpScreen(
              email: identifier,
              type: 'signup',
              fullName: name,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Signup failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final tr = ref.read(localeProvider.notifier).translate;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 920;

    // Palette tokens strictly matching design system
    final Color bgSurface = isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE);
    final Color cardSurface = isDark ? const Color(0xFF2B2920) : const Color(0xFFF7F1D0);
    final Color cardBorder = isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0);
    final Color primaryText = isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78);
    final Color secondaryText = isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A);
    final Color accentBlue = const Color(0xFF91ADCD);
    final Color elevatedSurface = isDark ? const Color(0xFF1E334D) : const Color(0xFFF4EFE0);

    return Scaffold(
      backgroundColor: bgSurface,
      body: Stack(
        children: [
          // 1. Subtle Ambient Background Glows
          Positioned(
            top: -120,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentBlue.withValues(alpha: isDark ? 0.12 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF38BDF8) : const Color(0xFF92764B)).withValues(alpha: isDark ? 0.08 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Viewport
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopBar(context, primaryText, cardBorder, isDark, tr),

                // Main Content Body
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48.0 : 20.0,
                        vertical: isDesktop ? 32.0 : 20.0,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 1040 : 460,
                            ),
                            child: isDesktop
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Left: LawBuddy Brand Storytelling (Sign Up specific)
                                      Expanded(
                                        flex: 11,
                                        child: _buildBrandingShowcase(
                                          primaryText,
                                          secondaryText,
                                          cardSurface,
                                          cardBorder,
                                          elevatedSurface,
                                          accentBlue,
                                          isDark,
                                          tr,
                                        ),
                                      ),
                                      const SizedBox(width: 56),

                                      // Right: Refined Sign Up Card
                                      Expanded(
                                        flex: 10,
                                        child: _buildSignupCard(
                                          context,
                                          authState,
                                          primaryText,
                                          secondaryText,
                                          cardSurface,
                                          cardBorder,
                                          elevatedSurface,
                                          accentBlue,
                                          colorScheme,
                                          isDark,
                                          tr,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildMobileBrandHeader(primaryText, secondaryText, accentBlue, isDark, tr),
                                      const SizedBox(height: 24),
                                      _buildSignupCard(
                                        context,
                                        authState,
                                        primaryText,
                                        secondaryText,
                                        cardSurface,
                                        cardBorder,
                                        elevatedSurface,
                                        accentBlue,
                                        colorScheme,
                                        isDark,
                                        tr,
                                      ),
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
    );
  }

  // ==========================================
  // TOP APP BAR (Identical to Login)
  // ==========================================
  Widget _buildTopBar(BuildContext context, Color primaryText, Color borderColor, bool isDark, String Function(String, [Map<String, String>?]) tr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              InkWell(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18, color: primaryText),
                      const SizedBox(width: 6),
                      Text(
                        tr('auth.backToHome'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LEFT: BRANDING & VISUAL STORYTELLING (SIGN UP)
  // ==========================================
  Widget _buildBrandingShowcase(
    Color primaryText,
    Color secondaryText,
    Color cardSurface,
    Color cardBorder,
    Color elevatedSurface,
    Color accentBlue,
    bool isDark,
    String Function(String, [Map<String, String>?]) tr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand Logo Badge
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF91ADCD), Color(0xFF708CAE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentBlue.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('common.appName'),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: primaryText,
                  ),
                ),
                Text(
                  tr('common.appSubtitle'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Headline
        Text(
          tr('auth.buildSaferJourney'),
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.25,
            color: primaryText,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          tr('auth.signUpSubtitle'),
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: secondaryText,
          ),
        ),

        const SizedBox(height: 28),

        // Compact AI Legal Visual Card (Sign Up variant)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.shield_outlined, size: 16, color: accentBlue),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('auth.agreementIntelligence'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final pulse = 0.6 + 0.4 * _pulseController.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35 * pulse),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tr('auth.aiProtectionReady'),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: elevatedSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.document_scanner_outlined, size: 15, color: secondaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('auth.clauseDocVerification'),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),


      ],
    );
  }

  // ==========================================
  // MOBILE BRAND HEADER
  // ==========================================
  Widget _buildMobileBrandHeader(Color primaryText, Color secondaryText, Color accentBlue, bool isDark, String Function(String, [Map<String, String>?]) tr) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF91ADCD), Color(0xFF708CAE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.gavel_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr('common.appName'),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tr('common.appSubtitle'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // RIGHT: REFINED SIGN UP CARD
  // ==========================================
  Widget _buildSignupCard(
    BuildContext context,
    AuthState authState,
    Color primaryText,
    Color secondaryText,
    Color cardSurface,
    Color cardBorder,
    Color elevatedSurface,
    Color accentBlue,
    ColorScheme colorScheme,
    bool isDark,
    String Function(String, [Map<String, String>?]) tr,
  ) {
    final bool isLoading = authState.status == AuthStatus.loading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header inside card
          Text(
            tr('auth.createYourAccount'),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('auth.enterDetails'),
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 24),

          // Segmented Control (Email / Mobile)
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: elevatedSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isEmailMode) {
                        setState(() {
                          _isEmailMode = true;
                          _identifierController.clear();
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: _isEmailMode ? (isDark ? const Color(0xFF2B2920) : Colors.white) : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: _isEmailMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 15,
                            color: _isEmailMode ? primaryText : secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tr('auth.email'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: _isEmailMode ? FontWeight.w700 : FontWeight.w500,
                              color: _isEmailMode ? primaryText : secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isEmailMode) {
                        setState(() {
                          _isEmailMode = false;
                          _identifierController.clear();
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: !_isEmailMode ? (isDark ? const Color(0xFF2B2920) : Colors.white) : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: !_isEmailMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 15,
                            color: !_isEmailMode ? primaryText : secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tr('auth.mobile'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: !_isEmailMode ? FontWeight.w700 : FontWeight.w500,
                              color: !_isEmailMode ? primaryText : secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Form Fields
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Full Name Field
                Text(
                  tr('auth.fullName'),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isNameFocused
                        ? [
                            BoxShadow(
                              color: accentBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryText,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: elevatedSurface,
                      hintText: tr('auth.nameHint'),
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: secondaryText.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: _isNameFocused ? accentBlue : secondaryText,
                        size: 18,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentBlue, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.error),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr('auth.enterFullName');
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Email or Mobile Field
                Text(
                  _isEmailMode ? tr('auth.emailAddress') : tr('auth.mobileNumber'),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isIdentifierFocused
                        ? [
                            BoxShadow(
                              color: accentBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextFormField(
                    controller: _identifierController,
                    focusNode: _identifierFocusNode,
                    keyboardType: _isEmailMode ? TextInputType.emailAddress : TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryText,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: elevatedSurface,
                      hintText: _isEmailMode ? tr('auth.emailHint') : tr('auth.phoneHint'),
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: secondaryText.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        _isEmailMode ? Icons.alternate_email_rounded : Icons.phone_android_rounded,
                        color: _isIdentifierFocused ? accentBlue : secondaryText,
                        size: 18,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentBlue, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.error),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr('auth.enterIdentifier', {'type': _isEmailMode ? tr('auth.email') : tr('auth.mobileNumber')});
                      }
                      if (_isEmailMode) {
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return tr('auth.validEmail');
                        }
                      } else {
                        final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                        final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                        if (!phoneRegex.hasMatch(cleanPhone)) {
                          return tr('auth.validPhone');
                        }
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                MouseRegion(
                  onEnter: (_) => setState(() => _isHoveredButton = true),
                  onExit: (_) => setState(() => _isHoveredButton = false),
                  child: AnimatedScale(
                    scale: _isHoveredButton && !isLoading ? 1.01 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF244A78) : const Color(0xFF244A78),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isHoveredButton ? 4 : 1,
                        shadowColor: const Color(0xFF244A78).withValues(alpha: 0.35),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tr('auth.createAccount'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(color: cardBorder.withValues(alpha: 0.6), height: 1),

          const SizedBox(height: 20),

          // Log In Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tr('auth.alreadyHaveAccount'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    tr('auth.logIn'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF91ADCD) : const Color(0xFF244A78),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

