import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../widgets/theme_toggle_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _riskSystemKey = GlobalKey();

  late final AnimationController _heroEntryController;
  late final Animation<double> _headlineLine1;
  late final Animation<double> _headlineLine2;
  late final Animation<double> _headlineLine3;
  late final Animation<double> _sideWordsAnim;
  Offset _mousePos = const Offset(600, 300);

  @override
  void initState() {
    super.initState();
    _heroEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _headlineLine1 = CurvedAnimation(
      parent: _heroEntryController,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
    );
    _headlineLine2 = CurvedAnimation(
      parent: _heroEntryController,
      curve: const Interval(0.20, 0.60, curve: Curves.easeOutCubic),
    );
    _headlineLine3 = CurvedAnimation(
      parent: _heroEntryController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );
    _sideWordsAnim = CurvedAnimation(
      parent: _heroEntryController,
      curve: const Interval(0.50, 0.95, curve: Curves.easeOutCubic),
    );

    _heroEntryController.forward();
  }

  @override
  void dispose() {
    _heroEntryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;
    final isTablet = size.width >= 600 && size.width < 960;

    final bgGradientColors = isDark
        ? [const Color(0xFF162B43), const Color(0xFF13253A), const Color(0xFF101F31)]
        : [const Color(0xFFFBF8EE), const Color(0xFFF7F1D0), const Color(0xFFF4EFE0)];

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
              // Subtle interactive ambient glow for desktop
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
                            const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.05 : 0.03),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
              // Top Navigation Header
              _buildTopHeader(isDark, isDesktop),

              // 1. "BEYOND"-Inspired Cinematic LegalTech Hero
              _buildHeroSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 24),

              // 2. Dual-Direction Moving Marquee Strip
              _DualDirectionMarquee(isDark: isDark),

              const SizedBox(height: 64),

              // 4. Three Core Features Section
              _buildCoreFeaturesSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 80),

              // 5. How It Works Section (4-Step Flow)
              _buildHowItWorksSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 80),

              // 6. Risk Assessment Preview & Mock Document Showcase
              _buildRiskSystemSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 80),

              // 7. Bottom CTA Callout Card
              _buildBottomCtaBanner(isDark, isDesktop),

                    const SizedBox(height: 60),

                    // 9. Footer & Legal Disclaimer
                    _buildFooter(isDark),
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
  // TOP NAVIGATION HEADER
  // ==========================================
  Widget _buildTopHeader(bool isDark, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE)).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo + Title
              Expanded(
                child: InkWell(
                  onTap: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF91ADCD), Color(0xFF708CAE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF91ADCD).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LawBuddy',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'REAL ESTATE AI TECH',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF91ADCD),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Desktop Navigation Links
              if (isDesktop)
                Row(
                  children: [
                    _buildNavButton('Features', () => _scrollToSection(_featuresKey), isDark),
                    _buildNavButton('How It Works', () => _scrollToSection(_howItWorksKey), isDark),
                    _buildNavButton('Risk System', () => _scrollToSection(_riskSystemKey), isDark),
                  ],
                ),

              // Right Action Buttons & Theme Toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ThemeToggleButton(),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _navigateToLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ==========================================
  // "BEYOND"-INSPIRED CINEMATIC HERO SECTION
  // ==========================================
  Widget _buildHeroSection(bool isDark, bool isDesktop, bool isTablet) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, _) {
        final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
        final clampedScroll = scrollOffset.clamp(0.0, 450.0);
        final scrollProgress = clampedScroll / 450.0;

        // Dynamic scroll parallax offsets
        final titleShiftBack = scrollProgress * 14.0;
        final titleShiftMid = scrollProgress * 8.0;
        final titleShiftThird = scrollProgress * 4.0;
        final docShift = scrollProgress * -14.0;
        final sideWordInward = (1.0 - scrollProgress) * (isDesktop ? 30.0 : 14.0);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32.0 : (isTablet ? 20.0 : 16.0),
            vertical: isDesktop ? 32.0 : 20.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Layer 1: Atmospheric Background Glow behind Central Document
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: isDesktop ? 800 : 440,
                        height: isDesktop ? 540 : 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.22 : 0.12),
                              const Color(0xFFFFDF8C).withValues(alpha: isDark ? 0.10 : 0.05),
                              Colors.transparent,
                            ],
                            radius: 0.85,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Layer 2: Main Content Column (Eyebrow, Layered Typography, Document, Narrative, CTAs)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Eyebrow Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.4 : 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isDesktop
                                    ? 'AI-POWERED LEGALTECH FOR INDIAN REAL ESTATE'
                                    : 'AI-POWERED REAL ESTATE LEGALTECH',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF5F7895) : const Color(0xFF244A78),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Giant Dimensional 4-Layered Headline (All 3 lines 100% visible & readable)
                      _buildLayeredHeadline(
                        isDark,
                        isDesktop,
                        isTablet,
                        titleShiftBack,
                        titleShiftMid,
                        titleShiftThird,
                      ),

                      const SizedBox(height: 24),

                      // 3D Document Visual with Live Scanning Animation
                      Transform.translate(
                        offset: Offset(0, docShift),
                        child: _HeroDocumentScanVisual(
                          isDark: isDark,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Supporting Narrative
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Text(
                          'Analyze real-estate contracts, detect potential legal risks under RERA, and understand complex clauses in plain English — powered by AI built for Indian property law.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 15.0 : 13.5,
                            height: 1.6,
                            color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA Buttons Row
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: _navigateToSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF5F7895) : const Color(0xFF244A78),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: (isDark ? const Color(0xFF5F7895) : const Color(0xFF244A78)).withValues(alpha: 0.3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToLogin,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              foregroundColor: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                ),
                                children: [
                                  const TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF5F7895) : const Color(0xFF244A78),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Layer 3: Left & Right Background Words with Staggered Entrance
                  if (isDesktop || isTablet) ...[
                    // Left Column Words: SCAN, ANALYZE, PROTECT, UNDERSTAND
                    Positioned(
                      left: isDesktop ? 16 : 8,
                      top: isDesktop ? 390 : 310,
                      child: AnimatedBuilder(
                        animation: _sideWordsAnim,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (_sideWordsAnim.value * (0.65 + (scrollProgress * 0.25))).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(-sideWordInward + (1.0 - _sideWordsAnim.value) * -20.0, 0),
                              child: child,
                            ),
                          );
                        },
                        child: _buildSideWordColumn(
                          ['SCAN', 'ANALYZE', 'PROTECT', 'UNDERSTAND'],
                          CrossAxisAlignment.start,
                          isDark,
                          isDesktop,
                          isTablet,
                        ),
                      ),
                    ),

                    // Right Column Words: PROPERTY, RERA, CLAUSES, SECURE
                    Positioned(
                      right: isDesktop ? 16 : 8,
                      top: isDesktop ? 390 : 310,
                      child: AnimatedBuilder(
                        animation: _sideWordsAnim,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (_sideWordsAnim.value * (0.65 + (scrollProgress * 0.25))).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(sideWordInward + (1.0 - _sideWordsAnim.value) * 20.0, 0),
                              child: child,
                            ),
                          );
                        },
                        child: _buildSideWordColumn(
                          ['PROPERTY', 'RERA', 'CLAUSES', 'SECURE'],
                          CrossAxisAlignment.end,
                          isDark,
                          isDesktop,
                          isTablet,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // LAYERED 3D TYPOGRAPHY (MASKED STAGGERED REVEAL)
  // ==========================================
  Widget _buildLayeredHeadline(
    bool isDark,
    bool isDesktop,
    bool isTablet,
    double shiftBack,
    double shiftMid,
    double shiftThird,
  ) {
    final fontSize = isDesktop ? 68.0 : (isTablet ? 46.0 : 30.0);

    final backOffsetY = (isDesktop ? 18.0 : (isTablet ? 12.0 : 9.0)) + shiftBack;
    final secOffsetY = (isDesktop ? 12.0 : (isTablet ? 8.0 : 6.0)) + shiftMid;
    final thirdOffsetY = (isDesktop ? 6.0 : (isTablet ? 4.0 : 3.0)) + shiftThird;

    final baseStyle = GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: -1.5,
    );

    Widget buildHeadlineLine(String lineText, Animation<double> anim) {
      return ClipRect(
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            final progress = anim.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, (1.0 - progress) * 35.0),
                child: child,
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Back Deep Blue
              Transform.translate(
                offset: Offset(0, backOffsetY),
                child: Text(
                  lineText,
                  textAlign: TextAlign.center,
                  style: baseStyle.copyWith(
                    color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.45 : 0.25),
                  ),
                ),
              ),

              // Layer 2: Second Electric Blue / Cyan
              Transform.translate(
                offset: Offset(0, secOffsetY),
                child: Text(
                  lineText,
                  textAlign: TextAlign.center,
                  style: baseStyle.copyWith(
                    color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.35 : 0.20),
                  ),
                ),
              ),

              // Layer 3: Third Brighter Cyan/Green-Blue
              Transform.translate(
                offset: Offset(0, thirdOffsetY),
                child: Text(
                  lineText,
                  textAlign: TextAlign.center,
                  style: baseStyle.copyWith(
                    color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.25 : 0.15),
                  ),
                ),
              ),

              // Layer 4: Front Crisp Dominant Layer
              Text(
                lineText,
                textAlign: TextAlign.center,
                style: baseStyle.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildHeadlineLine('UNDERSTAND', _headlineLine1),
        buildHeadlineLine('YOUR PROPERTY', _headlineLine2),
        buildHeadlineLine('BEFORE YOU SIGN.', _headlineLine3),
      ],
    );
  }

  // ==========================================
  // SIDE WORDS COLUMN (EDITORIAL BACKGROUND TYPOGRAPHY)
  // ==========================================
  Widget _buildSideWordColumn(
    List<String> words,
    CrossAxisAlignment alignment,
    bool isDark,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: words.map((word) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 12.0 : 7.0),
          child: Text(
            word,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 26.0 : (isTablet ? 18.0 : 12.0),
              fontWeight: FontWeight.w900,
              letterSpacing: isDesktop ? 5.5 : 3.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        );
      }).toList(),
    );
  }



  // ==========================================
  // TRUST & VALUE STRIP
  // ==========================================
  Widget _buildTrustStrip(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [
            _buildTrustItem(Icons.lock_outline_rounded, 'Secure & Private', isDark),
            _buildTrustItem(Icons.balance_rounded, 'RERA Focused', isDark),
            _buildTrustItem(Icons.auto_awesome_rounded, 'AI-Powered Analysis', isDark),
            _buildTrustItem(Icons.picture_as_pdf_outlined, 'PDF Reports', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CORE FEATURES SECTION (6-CARD SUITE)
  // ==========================================
  Widget _buildCoreFeaturesSection(bool isDark, bool isDesktop, bool isTablet) {
    final features = [
      const _FeatureCard(
        icon: Icons.document_scanner_outlined,
        accentColor: Color(0xFF3B82F6),
        tag: 'OCR & PDF',
        title: 'Scan & Extract',
        description: 'Upload PDF agreements, capture physical contracts via OCR camera, or paste legal text directly.',
      ),
      const _FeatureCard(
        icon: Icons.shield_outlined,
        accentColor: Color(0xFFEF4444),
        tag: 'AI AUDIT',
        title: 'Detect Legal Risks',
        description: 'Identify potentially unfair, non-compliant, or one-sided builder clauses with RERA-trained AI.',
      ),
      const _FeatureCard(
        icon: Icons.lightbulb_outline_rounded,
        accentColor: Color(0xFF10B981),
        tag: 'SIMPLIFIED',
        title: 'Plain-English Insights',
        description: 'Demystify dense legal jargon into 2-3 sentence layman explanations and negotiation advice.',
      ),
      const _FeatureCard(
        icon: Icons.calculate_outlined,
        accentColor: Color(0xFF8B5CF6),
        tag: 'STATE-WISE',
        title: 'Stamp Duty Calculator',
        description: 'Compute state-wise stamp duty, registration charges, local cess, and female buyer discounts across India.',
      ),
      const _FeatureCard(
        icon: Icons.forum_outlined,
        accentColor: Color(0xFFF59E0B),
        tag: '24/7 CHAT',
        title: 'AI Legal Assistant',
        description: 'Get instant 24/7 answers on property laws, tenancy disputes, builder notices, and contract clauses.',
      ),
      const _FeatureCard(
        icon: Icons.checklist_rounded,
        accentColor: Color(0xFF06B6D4),
        tag: 'CHECKLIST',
        title: 'Due Diligence Checklists',
        description: 'Step-by-step buyer verification covering title clearance, RERA approvals, encumbrance & OC records.',
      ),
    ];

    return Container(
      key: _featuresKey,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'YOUR LEGAL DOCUMENTS, MADE CLEAR.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything You Need to Review Property Contracts',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A comprehensive LegalTech suite designed specifically for real estate buyers, tenants, and property investors.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              if (isDesktop)
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: features[0]),
                        const SizedBox(width: 20),
                        Expanded(child: features[1]),
                        const SizedBox(width: 20),
                        Expanded(child: features[2]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: features[3]),
                        const SizedBox(width: 20),
                        Expanded(child: features[4]),
                        const SizedBox(width: 20),
                        Expanded(child: features[5]),
                      ],
                    ),
                  ],
                )
              else if (isTablet)
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: features[0]),
                        const SizedBox(width: 16),
                        Expanded(child: features[1]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: features[2]),
                        const SizedBox(width: 16),
                        Expanded(child: features[3]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: features[4]),
                        const SizedBox(width: 16),
                        Expanded(child: features[5]),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < features.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      features[i],
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HOW IT WORKS SECTION (4-STEP FLOW)
  // ==========================================
  Widget _buildHowItWorksSection(bool isDark, bool isDesktop, bool isTablet) {
    return Container(
      key: _howItWorksKey,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'SIMPLE 4-STEP PROCESS',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How It Works',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 36),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _StepCard(number: '01', title: 'Upload Agreement', description: 'Upload your property agreement, sale deed, or rental contract.', isDark: isDark)),
                        _buildStepArrow(isDark),
                        Expanded(child: _StepCard(number: '02', title: 'AI Contract Scan', description: 'AI examines the text and evaluates statutory RERA compliance.', isDark: isDark)),
                        _buildStepArrow(isDark),
                        Expanded(child: _StepCard(number: '03', title: 'Plain-English Insights', description: 'Get plain-English explanations and flagged risk highlights.', isDark: isDark)),
                        _buildStepArrow(isDark),
                        Expanded(child: _StepCard(number: '04', title: 'Legal Audit Report', description: 'Generate and download a structured legal risk assessment PDF.', isDark: isDark)),
                      ],
                    )
                  : Column(
                      children: [
                        _StepCard(number: '01', title: 'Upload Agreement', description: 'Upload your property agreement, sale deed, or rental contract.', isDark: isDark),
                        const SizedBox(height: 14),
                        _StepCard(number: '02', title: 'AI Contract Scan', description: 'AI examines the text and evaluates statutory RERA compliance.', isDark: isDark),
                        const SizedBox(height: 14),
                        _StepCard(number: '03', title: 'Plain-English Insights', description: 'Get plain-English explanations and flagged risk highlights.', isDark: isDark),
                        const SizedBox(height: 14),
                        _StepCard(number: '04', title: 'Legal Audit Report', description: 'Generate and download a structured legal risk assessment PDF.', isDark: isDark),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepArrow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 56),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      ),
    );
  }

  // ==========================================
  // LEGAL RISK SYSTEM SHOWCASE SECTION
  // ==========================================
  Widget _buildRiskSystemSection(bool isDark, bool isDesktop, bool isTablet) {
    return Container(
      key: _riskSystemKey,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'AI-POWERED AUDIT PREVIEW',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See What LawBuddy Finds',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Our RERA-trained engine inspects agreement clauses line-by-line to flag unfair conditions, non-compliant timelines, and asymmetric liabilities.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              // Interactive Live Simulation Showcase
              _RiskSystemShowcase(isDark: isDark, isDesktop: isDesktop),
            ],
          ),
        ),
      ),
    );
  }



  // ==========================================
  // BOTTOM CTA CALLOUT BANNER
  // ==========================================
  Widget _buildBottomCtaBanner(bool isDark, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: isDesktop ? 42 : 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Before You Sign,\nKnow What You\'re Signing.',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Upload your property document and let LawBuddy help you understand the clauses, risks, and important legal considerations.',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _scrollToSection(_featuresKey),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70, width: 1.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Explore Features',
                              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _navigateToSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1D4ED8),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: Text(
                              'Analyze Your Document →',
                              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Before You Sign,\nKnow What You\'re Signing.',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your property document and let LawBuddy help you understand the clauses, risks, and important legal considerations.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: _navigateToSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Analyze Your Document →',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => _scrollToSection(_featuresKey),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70, width: 1.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Explore Features',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FOOTER & LEGAL DISCLAIMER
  // ==========================================
  Widget _buildFooter(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Muted Disclaimer Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.gavel_outlined, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legal Disclaimer',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This application provides AI-generated information for preliminary document review and educational purposes only. It does not constitute legal advice or create an advocate-client relationship. For important property transactions, consult a qualified legal professional.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              height: 1.45,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
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
}

// ==========================================
// CENTRAL HERO DOCUMENT 3D OBJECT (LIVE AI SCAN ANIMATION)
// ==========================================
class _HeroDocumentScanVisual extends StatefulWidget {
  final bool isDark;
  final bool isDesktop;
  final bool isTablet;

  const _HeroDocumentScanVisual({
    required this.isDark,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  State<_HeroDocumentScanVisual> createState() => _HeroDocumentScanVisualState();
}

class _HeroDocumentScanVisualState extends State<_HeroDocumentScanVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isDesktop = widget.isDesktop;
    final isTablet = widget.isTablet;

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          constraints: BoxConstraints(maxWidth: isDesktop ? 540 : (isTablet ? 460 : 360)),
          child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF91ADCD).withValues(alpha: _isHovered ? 0.45 : (isDark ? 0.35 : 0.15)),
                        blurRadius: _isHovered ? 54 : 42,
                        spreadRadius: 2,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 22 : 18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2B2920) : const Color(0xFFF7F1D0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Header with pulsating AI Scan Active indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF91ADCD).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.description_outlined,
                                            size: 16,
                                            color: Color(0xFF91ADCD),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'PROPERTY SALE AGREEMENT',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // AI Scan Active Badge with subtle pulsing light
                                  AnimatedBuilder(
                                    animation: _scanController,
                                    builder: (context, child) {
                                      final pulse = 0.6 + 0.4 * _scanController.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.4 * pulse),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.25 * pulse),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF10B981),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.8 * pulse),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'AI Scan Active',
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
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

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Clause 7.2 Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Clause 7.2 — Forfeiture',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Relevant Property Law',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Clause Body with subtle border pulse
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF162B43).withValues(alpha: 0.7)
                                      : const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  '"In case of delay beyond 30 days, 100% of earnest deposit shall be forfeited without notice."',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // AI Assessment Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.shield_outlined, size: 14, color: Color(0xFFEF4444)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'High Legal Risk Detected',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFEF4444),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Score: 68/100',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: 0.68,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Plain English: The builder can confiscate all your advance money even for minor payment delays.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        height: 1.4,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Animated scanning laser line sweeping across the card
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _scanController,
                              builder: (context, _) {
                                final topOffset = _scanController.value * 320.0;
                                return Stack(
                                  children: [
                                    Positioned(
                                      top: topOffset,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}



// ==========================================
// REUSABLE FEATURE CARD WITH HOVER EFFECT & TAG
// ==========================================
// ==========================================
// REUSABLE FEATURE CARD WITH HOVER EFFECT & TAG
// ==========================================
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final String? tag;

  const _FeatureCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    this.tag,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        constraints: const BoxConstraints(minHeight: 185),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.8)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.accentColor,
                    size: 22,
                  ),
                ),
                if (widget.tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.tag!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// REUSABLE STEP CARD WITH HOVER EFFECT
// ==========================================
class _StepCard extends StatefulWidget {
  final String number;
  final String title;
  final String description;
  final bool isDark;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 165),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: _isHovered ? 1.0 : 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF3B82F6).withValues(alpha: 0.8)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.35 : (isDark ? 0.2 : 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.number,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _isHovered ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// LEGAL RISK SYSTEM SHOWCASE WIDGET (LIVE SIMULATION)
// ==========================================
class _RiskSystemShowcase extends StatefulWidget {
  final bool isDark;
  final bool isDesktop;

  const _RiskSystemShowcase({
    required this.isDark,
    required this.isDesktop,
  });

  @override
  State<_RiskSystemShowcase> createState() => _RiskSystemShowcaseState();
}

class _RiskSystemShowcaseState extends State<_RiskSystemShowcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scoreAnim;
  late final Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _scoreAnim = Tween<double>(begin: 0.0, end: 72.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isDesktop = widget.isDesktop;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: _buildMockDocumentPanel(isDark)),
                const SizedBox(width: 24),
                Expanded(flex: 9, child: _buildRiskScorePanel(isDark)),
              ],
            )
          : Column(
              children: [
                _buildMockDocumentPanel(isDark),
                const SizedBox(height: 20),
                _buildRiskScorePanel(isDark),
              ],
            ),
    );
  }

  Widget _buildMockDocumentPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B43) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF274366) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.article_outlined, size: 16, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      Text(
                        'AGREEMENT FOR SALE (EXTRACT)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      final pulse = 0.7 + 0.3 * _animController.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 * pulse : 0.15 * pulse),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5 * pulse),
                          ),
                        ),
                        child: Text(
                          'POTENTIAL RISK DETECTED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Clause 7.2 — Default & Forfeiture of Earnest Deposit',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final glow = 0.3 + 0.4 * _animController.value;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: glow),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15 * glow),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Text(
                  '"In the event of any delay in milestone payment exceeding 15 days, the Promoter shall have the unilateral right to cancel the allotment and forfeit 100% of the Earnest Money Deposit and accrued interest without further notice."',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Excessive forfeiture clause exceeds statutory 10% ceiling prescribed under Section 13(1) of RERA Model Rules.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Scanning sweep beam across the extract
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _scanLineAnim,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Positioned(
                        top: _scanLineAnim.value * 200.0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF38BDF8).withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScorePanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B43) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF274366) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Legal Risk Assessment',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              AnimatedBuilder(
                animation: _scoreAnim,
                builder: (context, _) {
                  final score = _scoreAnim.value.round();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$score / 100 • Elevated',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, _) {
              final progress = (_scoreAnim.value / 100.0).clamp(0.0, 1.0);
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildRiskItemRow('🔴 High Risk', 'Clause 7.2: Unilateral earnest forfeiture (100%)', const Color(0xFFEF4444), isDark),
          const SizedBox(height: 8),
          _buildRiskItemRow('🟡 Caution', 'Clause 14.1: Asymmetric delay penalty compensation', const Color(0xFFF59E0B), isDark),
          const SizedBox(height: 8),
          _buildRiskItemRow('🟢 Standard', 'Clause 3.1: Carpet area specification & RERA warranty', const Color(0xFF10B981), isDark),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommendation: Demand amendment to restrict forfeiture to max 10% of total consideration as per standard MahaRERA guidelines.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.4,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
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

  Widget _buildRiskItemRow(String tag, String text, Color color, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            tag,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.35,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// DUAL-DIRECTION CONTINUOUS HORIZONTAL MARQUEE
// ==========================================
class _DualDirectionMarquee extends StatefulWidget {
  final bool isDark;
  const _DualDirectionMarquee({required this.isDark});

  @override
  State<_DualDirectionMarquee> createState() => _DualDirectionMarqueeState();
}

class _DualDirectionMarqueeState extends State<_DualDirectionMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _track1Text =
      'SCAN CONTRACTS  ✦  RERA COMPLIANCE AUDIT  ✦  PLAIN-ENGLISH INSIGHTS  ✦  DETECT UNFAIR CLAUSES  ✦  INDIAN PROPERTY LAW  ✦  ';
  static const _track2Text =
      'STAMP DUTY CALCULATOR  ✦  DUE DILIGENCE CHECKLISTS  ✦  24/7 LEGAL AI CHAT  ✦  EXPORTABLE PDF REPORTS  ✦  TITLE CLEARANCE & OC  ✦  ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF132338) : const Color(0xFFF4EFE0)).withValues(alpha: 0.65),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? const Color(0xFF334356).withValues(alpha: 0.5) : const Color(0xFFE4DDD0),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Line 1: Moving Left
              _buildMarqueeTrack(
                text: _track1Text,
                moveLeft: true,
                isDark: isDark,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF244A78),
              ),
              const SizedBox(height: 10),
              // Line 2: Moving Right (Opposite Direction)
              _buildMarqueeTrack(
                text: _track2Text,
                moveLeft: false,
                isDark: isDark,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF244A78),
              ),
            ],
          ),
          // Left Fade Gradient Mask
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
          // Right Fade Gradient Mask
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarqueeTrack({
    required String text,
    required bool moveLeft,
    required bool isDark,
    required Color color,
  }) {
    return SizedBox(
      height: 24,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                const singleChunkWidth = 1180.0;
                final offset = moveLeft
                    ? -(_controller.value * singleChunkWidth)
                    : ((_controller.value - 1.0) * singleChunkWidth);

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: offset,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(6, (_) {
                            return Text(
                              text,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                                color: color,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}





