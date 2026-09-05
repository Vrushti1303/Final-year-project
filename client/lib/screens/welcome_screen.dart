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

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _riskSystemKey = GlobalKey();

  @override
  void dispose() {
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
        ? [const Color(0xFF0B1120), const Color(0xFF0F172A), const Color(0xFF020617)]
        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradientColors,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Top Navigation Header
              _buildTopHeader(isDark, isDesktop),

              // 1. "BEYOND"-Inspired Cinematic LegalTech Hero
              _buildHeroSection(isDark, isDesktop, isTablet),

              // 2. Continuous Marquee Banner
              _MarqueeStrip(isDark: isDark),

              const SizedBox(height: 36),

              // 3. Trust & Value Strip
              _buildTrustStrip(isDark),

              const SizedBox(height: 64),

              // 4. Three Core Features Section
              _buildCoreFeaturesSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 80),

              // 5. How It Works Section (4-Step Flow)
              _buildHowItWorksSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 80),

              // 6. Risk Assessment Preview Section (3 Indicators)
              _buildRiskSystemSection(isDark, isDesktop, isTablet),

              const SizedBox(height: 80),

              // 7. Bottom CTA Callout Card
              _buildBottomCtaBanner(isDark, isDesktop),

              const SizedBox(height: 60),

              // 8. Footer & Legal Disclaimer
              _buildFooter(isDark),
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
        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
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
                              'Legal Document Scanner',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                color: const Color(0xFF3B82F6),
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
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.10),
                              const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.08 : 0.03),
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
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.4 : 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF38BDF8),
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
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
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

                      // 3D Document Visual (Cleanly positioned with full visibility)
                      Transform.translate(
                        offset: Offset(0, docShift),
                        child: _buildCentralDocumentVisual(isDark, isDesktop, isTablet),
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
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
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
                              foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                children: [
                                  const TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
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

                  // Layer 3: Left & Right Background Words (Aligned cleanly alongside Document)
                  if (isDesktop || isTablet) ...[
                    // Left Column Words: SCAN, ANALYZE, PROTECT, UNDERSTAND
                    Positioned(
                      left: isDesktop ? 16 : 8,
                      top: isDesktop ? 390 : 310,
                      child: Transform.translate(
                        offset: Offset(-sideWordInward, 0),
                        child: Opacity(
                          opacity: (0.65 + (scrollProgress * 0.25)).clamp(0.0, 1.0),
                          child: _buildSideWordColumn(
                            ['SCAN', 'ANALYZE', 'PROTECT', 'UNDERSTAND'],
                            CrossAxisAlignment.start,
                            isDark,
                            isDesktop,
                            isTablet,
                          ),
                        ),
                      ),
                    ),

                    // Right Column Words: PROPERTY, RERA, CLAUSES, SECURE
                    Positioned(
                      right: isDesktop ? 16 : 8,
                      top: isDesktop ? 390 : 310,
                      child: Transform.translate(
                        offset: Offset(sideWordInward, 0),
                        child: Opacity(
                          opacity: (0.65 + (scrollProgress * 0.25)).clamp(0.0, 1.0),
                          child: _buildSideWordColumn(
                            ['PROPERTY', 'RERA', 'CLAUSES', 'SECURE'],
                            CrossAxisAlignment.end,
                            isDark,
                            isDesktop,
                            isTablet,
                          ),
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
  // LAYERED 3D TYPOGRAPHY (4-LAYER BEYOND SPEC)
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
    const text = 'UNDERSTAND\nYOUR PROPERTY\nBEFORE YOU SIGN.';

    final backOffsetY = (isDesktop ? 18.0 : (isTablet ? 12.0 : 9.0)) + shiftBack;
    final secOffsetY = (isDesktop ? 12.0 : (isTablet ? 8.0 : 6.0)) + shiftMid;
    final thirdOffsetY = (isDesktop ? 6.0 : (isTablet ? 4.0 : 3.0)) + shiftThird;

    final baseStyle = GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: -1.5,
    );

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1: Back Deep Blue (+18px offset, ~45% opacity)
          Transform.translate(
            offset: Offset(0, backOffsetY),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.45 : 0.25),
              ),
            ),
          ),

          // Layer 2: Second Electric Blue / Cyan (+12px offset, ~35% opacity)
          Transform.translate(
            offset: Offset(0, secOffsetY),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.35 : 0.20),
              ),
            ),
          ),

          // Layer 3: Third Brighter Cyan/Green-Blue (+6px offset, ~25% opacity)
          Transform.translate(
            offset: Offset(0, thirdOffsetY),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.25 : 0.15),
              ),
            ),
          ),

          // Layer 4: Front Crisp Dominant Layer (0px offset)
          Text(
            text,
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
  // CENTRAL HERO DOCUMENT 3D OBJECT
  // ==========================================
  Widget _buildCentralDocumentVisual(bool isDark, bool isDesktop, bool isTablet) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 540 : (isTablet ? 460 : 360)),
        child: Transform.rotate(
          angle: isDesktop ? -0.016 : -0.010,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Secondary Layered Document/Paper Edge behind main card
              Positioned(
                top: 8,
                left: 8,
                right: -8,
                bottom: -8,
                child: Transform.rotate(
                  angle: 0.018,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Main Active Document Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    // Ambient Blue Depth Glow
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.15),
                      blurRadius: 42,
                      spreadRadius: 2,
                      offset: const Offset(0, 16),
                    ),
                    // Crisp Drop Shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 22 : 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Document Card Top Header
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
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: Color(0xFF3B82F6),
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
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // AI Scan Active Badge with subtle pulse glow
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
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
                                        color: const Color(0xFF10B981).withValues(alpha: 0.8),
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Scanning Line Bar
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

                      // Clause Text Highlight
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"The purchaser shall forfeit 100% of earnest deposit without arbitration if payment is delayed by over 7 calendar days..."',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Potential Risk Detected • Excessive forfeiture',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // AI Assessment Score Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
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
                                Flexible(
                                  child: Text(
                                    'AI Legal Risk Assessment',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '72 / 100 — Elevated Risk',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: 0.72,
                                minHeight: 6,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Risk Indicators Wrap
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildMiniBadge('🔴 2 High Risk', const Color(0xFFEF4444), isDark),
                                _buildMiniBadge('🟡 4 Caution', const Color(0xFFF59E0B), isDark),
                                _buildMiniBadge('🟢 8 Standard', const Color(0xFF10B981), isDark),
                              ],
                            ),
                          ],
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

  Widget _buildMiniBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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
  // 3 CORE FEATURES SECTION
  // ==========================================
  Widget _buildCoreFeaturesSection(bool isDark, bool isDesktop, bool isTablet) {
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
                'A dedicated LegalTech toolkit designed specifically for real estate buyers, tenants, and landlords.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              isDesktop
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.document_scanner_outlined,
                            accentColor: Color(0xFF3B82F6),
                            title: 'Scan & Extract',
                            description: 'Upload PDF agreements, capture physical contracts via OCR, or paste legal text directly.',
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.shield_outlined,
                            accentColor: Color(0xFFEF4444),
                            title: 'Detect Legal Risks',
                            description: 'Identify potentially unfair, non-compliant, or one-sided builder clauses with RERA-trained AI.',
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.lightbulb_outline_rounded,
                            accentColor: Color(0xFF10B981),
                            title: 'Understand in Plain English',
                            description: 'Tap on dense legal jargon for 2-3 sentence layman explanations and negotiation advice.',
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      children: [
                        _FeatureCard(
                          icon: Icons.document_scanner_outlined,
                          accentColor: Color(0xFF3B82F6),
                          title: 'Scan & Extract',
                          description: 'Upload PDF agreements, capture physical contracts via OCR, or paste legal text directly.',
                        ),
                        SizedBox(height: 14),
                        _FeatureCard(
                          icon: Icons.shield_outlined,
                          accentColor: Color(0xFFEF4444),
                          title: 'Detect Legal Risks',
                          description: 'Identify potentially unfair, non-compliant, or one-sided builder clauses with RERA-trained AI.',
                        ),
                        SizedBox(height: 14),
                        _FeatureCard(
                          icon: Icons.lightbulb_outline_rounded,
                          accentColor: Color(0xFF10B981),
                          title: 'Understand in Plain English',
                          description: 'Tap on dense legal jargon for 2-3 sentence layman explanations and negotiation advice.',
                        ),
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
                        Expanded(child: _buildStepItem('01', 'Upload', 'Upload your property agreement, sale deed, or rental contract.', isDark)),
                        _buildStepArrow(isDark),
                        Expanded(child: _buildStepItem('02', 'Analyze', 'AI examines the text and evaluates statutory RERA compliance.', isDark)),
                        _buildStepArrow(isDark),
                        Expanded(child: _buildStepItem('03', 'Understand', 'Get plain-English explanations and flagged risk highlights.', isDark)),
                        _buildStepArrow(isDark),
                        Expanded(child: _buildStepItem('04', 'Report', 'Generate and download a structured legal risk assessment PDF.', isDark)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStepItem('01', 'Upload', 'Upload your property agreement, sale deed, or rental contract.', isDark),
                        const SizedBox(height: 14),
                        _buildStepItem('02', 'Analyze', 'AI examines the text and evaluates statutory RERA compliance.', isDark),
                        const SizedBox(height: 14),
                        _buildStepItem('03', 'Understand', 'Get plain-English explanations and flagged risk highlights.', isDark),
                        const SizedBox(height: 14),
                        _buildStepItem('04', 'Report', 'Generate and download a structured legal risk assessment PDF.', isDark),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description, bool isDark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 165),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
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
  // RISK ASSESSMENT PREVIEW SECTION
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
                'INTUITIVE RISK CLASSIFICATION',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See What Needs Your Attention',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Our 3-tier severity rating establishes clear, immediate visibility across every agreement you scan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),

              isDesktop
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _RiskIndicatorCard(
                            tag: 'STANDARD',
                            color: Color(0xFF10B981),
                            title: '🟢 Standard Clause',
                            description: 'Fair, standard terms aligned with statutory property norms and normal legal practice.',
                          ),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: _RiskIndicatorCard(
                            tag: 'CAUTION',
                            color: Color(0xFFF59E0B),
                            title: '🟡 Caution / Ambiguous',
                            description: 'Missing buyer protections, vague maintenance terms, or clauses requiring clarification.',
                          ),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: _RiskIndicatorCard(
                            tag: 'HIGH RISK',
                            color: Color(0xFFEF4444),
                            title: '🔴 High Legal Risk',
                            description: 'Potentially one-sided penalties, non-compliant terms under RERA, or unfair forfeiture clauses.',
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      children: [
                        _RiskIndicatorCard(
                          tag: 'STANDARD',
                          color: Color(0xFF10B981),
                          title: '🟢 Standard Clause',
                          description: 'Fair, standard terms aligned with statutory property norms and normal legal practice.',
                        ),
                        SizedBox(height: 12),
                        _RiskIndicatorCard(
                          tag: 'CAUTION',
                          color: Color(0xFFF59E0B),
                          title: '🟡 Caution / Ambiguous',
                          description: 'Missing buyer protections, vague maintenance terms, or clauses requiring clarification.',
                        ),
                        SizedBox(height: 12),
                        _RiskIndicatorCard(
                          tag: 'HIGH RISK',
                          color: Color(0xFFEF4444),
                          title: '🔴 High Legal Risk',
                          description: 'Potentially one-sided penalties, non-compliant terms under RERA, or unfair forfeiture clauses.',
                        ),
                      ],
                    ),
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
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 36 : 28,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
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
                              'Ready to review your property agreement?',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start scanning your contract today and get an instant AI risk assessment.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: _navigateToSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Text(
                          'Analyze Your First Document →',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ready to review your property agreement?',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Start scanning your contract today and get an instant AI risk assessment.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _navigateToSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Analyze Your First Document →',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
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

              const SizedBox(height: 20),

              Text(
                '© 2026 Legal Document Scanner • Built with Flutter, Node.js & Gemini AI for Real Estate LegalTech',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
// CONTINUOUS MARQUEE STRIP (ISOLATED ANIMATION)
// ==========================================
class _MarqueeStrip extends StatefulWidget {
  final bool isDark;
  const _MarqueeStrip({required this.isDark});

  @override
  State<_MarqueeStrip> createState() => _MarqueeStripState();
}

class _MarqueeStripState extends State<_MarqueeStrip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _text = 'SCAN  •  ANALYZE  •  UNDERSTAND  •  PROTECT  •  RERA FOCUSED  •  PROPERTY LAW  •  AI ANALYSIS  •  LEGAL RISK DETECTION  •  ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
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
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                const singleChunkWidth = 920.0;
                final offset = -(_controller.value * singleChunkWidth);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: offset,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (_) {
                            return Text(
                              _text,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
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

// ==========================================
// REUSABLE FEATURE CARD WITH HOVER EFFECT
// ==========================================
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
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
        padding: const EdgeInsets.all(20),
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
// REUSABLE RISK INDICATOR CARD
// ==========================================
class _RiskIndicatorCard extends StatelessWidget {
  final String tag;
  final Color color;
  final String title;
  final String description;

  const _RiskIndicatorCard({
    required this.tag,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 155),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.shield, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
