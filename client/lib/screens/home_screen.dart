import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/user_profile_button.dart';
import '../services/api_service.dart';
import 'scan_screen.dart';
import 'chat_screen.dart';
import 'checklists_list_screen.dart';
import 'analysis_screen.dart';
import 'stamp_duty_calculator_screen.dart';
import 'recent_documents_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _ambientController;
  late Animation<double> _pulseAnimation;

  List<_RecentDocItem> _recentDocs = [];
  List<dynamic> _checklists = [];
  List<dynamic> _legalNews = [];
  bool _isLoadingDocs = false;
  bool _isLoadingNews = false;
  Offset _mousePos = const Offset(600, 300);

  @override
  void initState() {
    super.initState();
    // Entrance animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Continuous ambient breathing animation
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _animationController.forward();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _loadRecentDocuments();
    _loadChecklists();
    _loadLegalNews();
  }

  Future<void> _loadRecentDocuments() async {
    if (!mounted) return;
    setState(() => _isLoadingDocs = true);
    try {
      final rawDocs = await ApiService.fetchRecentDocuments();
      if (mounted) {
        setState(() {
          _recentDocs = rawDocs
              .map((d) => _RecentDocItem.fromJson(d as Map<String, dynamic>))
              .toList();
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

  Future<void> _loadChecklists() async {
    try {
      final cls = await ApiService.fetchAllChecklists();
      if (mounted) {
        setState(() {
          _checklists = cls;
        });
      }
    } catch (e) {
      debugPrint('Error loading checklists: $e');
    }
  }

  Future<void> _loadLegalNews() async {
    if (!mounted) return;
    setState(() => _isLoadingNews = true);
    try {
      final news = await ApiService.getLegalNews();
      if (mounted) {
        setState(() {
          _legalNews = news;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading legal news: $e');
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ).then((_) {
      if (mounted) _loadDashboardData();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final loc = ref.read(localeProvider.notifier);
    if (hour < 12) {
      return loc.translate('home.goodMorning');
    } else if (hour < 17) {
      return loc.translate('home.goodAfternoon');
    } else {
      return loc.translate('home.goodEvening');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    final String greetingName = (user?.fullName != null && user!.fullName.trim().isNotEmpty)
        ? user.fullName.trim().split(' ').first
        : 'Jiya';

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
              // 6. ENHANCED CINEMATIC AMBIENT LIGHTING
              // ==========================================
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  final pulse = _pulseAnimation.value;
                  return Stack(
                    children: [
                      // Orb 1: Top-Left Cyan Ambient Aurora
                      Positioned(
                        top: -140 + (25 * _ambientController.value),
                        left: -120 + (20 * _ambientController.value),
                        child: IgnorePointer(
                          child: Container(
                            width: 580 * pulse,
                            height: 580 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.12 : 0.07),
                                  const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.06 : 0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 2: Center/Bottom-Right Gold Ambient Aurora
                      Positioned(
                        bottom: 80 + (30 * (1.0 - _ambientController.value)),
                        right: -140,
                        child: IgnorePointer(
                          child: Container(
                            width: 620 * (2.0 - pulse),
                            height: 620 * (2.0 - pulse),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.08 : 0.05),
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
                                    const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.055 : 0.035),
                                    const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.025 : 0.015),
                                    Colors.transparent,
                                  ],
                                  radius: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Sticky Top Navigation
                    _buildTopNav(context, isDark, isDesktop),

                    // Main Scrollable Dashboard Content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 32.0 : 18.0,
                              vertical: 24.0,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Editorial Welcome Hero Banner (Glassmorphic)
                                    _buildHeroSection(context, isDark, isDesktop, greetingName),
                                    const SizedBox(height: 32),

                                    // 2. Quick Actions 4-Module Suite (Shimmering Glass Cards)
                                    _buildQuickActionsSection(context, isDark, isDesktop),
                                    const SizedBox(height: 36),

                                    // 3. 2-Column Content Grid: Recent Documents & Legal Updates
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        if (constraints.maxWidth >= 900) {
                                          return IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                  child: _buildRecentDocumentsSection(context, isDark),
                                                ),
                                                const SizedBox(width: 24),
                                                Expanded(
                                                  child: _buildLegalNewsSection(context, isDark),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return Column(
                                            children: [
                                              _buildRecentDocumentsSection(context, isDark),
                                              const SizedBox(height: 28),
                                              _buildLegalNewsSection(context, isDark),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 36),

                                    // 4. Prominent RERA Advisory Alert Banner
                                    _buildReraAlertCard(context, isDark, isDesktop),
                                    const SizedBox(height: 90), // Breathing room for Floating AI Button
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

              // Floating AI Assistant Pill Button (Bottom-Right)
              Positioned(
                right: isDesktop ? 32 : 18,
                bottom: 24,
                child: _buildFloatingAiButton(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP NAVIGATION BAR
  // ==========================================
  Widget _buildTopNav(BuildContext context, bool isDark, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE)).withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo + Title
              InkWell(
                onTap: () {},
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
                            color: const Color(0xFF91ADCD).withValues(alpha: 0.35),
                            blurRadius: 10,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LawBuddy',
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'REAL ESTATE AI TECH',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF91ADCD),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Nav: User Profile Menu & Actions
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserProfileButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. EDITORIAL WELCOME HERO BANNER (FROSTED GLASS)
  // ==========================================
  Widget _buildHeroSection(BuildContext context, bool isDark, bool isDesktop, String userName) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  const Color(0xFFC5A85E).withValues(alpha: 0.15),
                  const Color(0xFF334356).withValues(alpha: 0.3),
                ]
              : [
                  const Color(0xFFE4DDD0),
                  const Color(0xFFD4AF37).withValues(alpha: 0.25),
                  const Color(0xFFE4DDD0),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF0F172A) : const Color(0xFF91ADCD)).withValues(alpha: isDark ? 0.45 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2), // Gradient border container
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.94)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20.8),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32.0 : 20.0,
          vertical: isDesktop ? 26.0 : 20.0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showIllustration = constraints.maxWidth >= 720;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Eyebrow Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF91ADCD).withValues(alpha: isDark ? 0.35 : 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B)).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'YOUR PROPERTY • YOUR RIGHTS • YOUR CONFIDENCE',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF244A78),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Greeting Headline
                      Text(
                        loc.translate('home.greeting', {'greeting': _getGreeting(), 'name': userName}),
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 26 : 21,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Supporting Narrative
                      Text(
                        'Review your agreements, check RERA risks, and make informed property decisions with AI built for Indian real estate.',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 13.5 : 12.5,
                          height: 1.45,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        ),
                      ),
                    ],
                  ),
                ),

                if (showIllustration) ...[
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 210,
                    height: 90,
                    child: CustomPaint(
                      painter: _LegalPropertyIllustrationPainter(
                        accentBlue: const Color(0xFF91ADCD),
                        accentGold: const Color(0xFFC5A85E),
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // 2. QUICK ACTIONS SECTION (4 FEATURE MODULES)
  // ==========================================
  Widget _buildQuickActionsSection(BuildContext context, bool isDark, bool isDesktop) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    // Compute real dynamic checklist metrics from MongoDB data
    int checklistCount = _checklists.length;
    int totalTasks = 0;
    int completedTasks = 0;
    for (final cl in _checklists) {
      final items = (cl['items'] as List<dynamic>?) ?? [];
      totalTasks += items.length;
      completedTasks += items.where((it) => it['isCompleted'] == true).length;
    }
    double checklistProgress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    final String checklistBadge = checklistCount == 0
        ? loc.translate('home.activeChecklistsZero')
        : loc.translate('home.activeChecklistsBadge', {
            'count': checklistCount.toString(),
            'unit': loc.translate(checklistCount == 1 ? 'home.checklistUnitSingular' : 'home.checklistUnitPlural'),
          });

    final String checklistDesc = totalTasks == 0
        ? (checklistCount == 0 ? loc.translate('home.checklistZeroTasks') : loc.translate('home.checklistZeroCompleted'))
        : loc.translate('home.checklistTasksProgress', {
            'completed': completedTasks.toString(),
            'total': totalTasks.toString(),
            'count': checklistCount.toString(),
            'unit': loc.translate(checklistCount == 1 ? 'home.guideUnitSingular' : 'home.guideUnitPlural'),
          });

    final String exploreBtn = loc.translate('common.explore').replaceAll('→', '').trim();

    final cards = [
      _QuickActionItem(
        category: 'DOCUMENT SCAN',
        title: loc.translate('home.scanAgreement'),
        description: loc.translate('home.scanAgreementDesc'),
        ctaText: exploreBtn.isNotEmpty ? exploreBtn : 'Explore',
        icon: Icons.document_scanner_rounded,
        accentColor: const Color(0xFF38BDF8), // Cyan / Blue Accent
        onTap: () => _navigateTo(const ScanScreen()),
      ),
      _QuickActionItem(
        category: '24/7 AI ASSISTANT',
        title: loc.translate('home.legalChatbot'),
        description: loc.translate('home.legalChatbotDesc'),
        ctaText: exploreBtn.isNotEmpty ? exploreBtn : 'Explore',
        icon: Icons.forum_outlined,
        accentColor: const Color(0xFFC5A85E), // Gold Accent
        onTap: () => _navigateTo(const ChatScreen()),
      ),
      _QuickActionItem(
        category: 'DUE DILIGENCE',
        title: loc.translate('home.propertyChecklist'),
        description: checklistDesc,
        ctaText: exploreBtn.isNotEmpty ? exploreBtn : 'Explore',
        icon: Icons.checklist_rounded,
        accentColor: const Color(0xFFC5A85E), // Gold Accent (matching AI Chatbot)
        badgeText: checklistBadge,
        showProgress: true,
        progress: checklistProgress,
        onTap: () => _navigateTo(const ChecklistsListScreen()),
      ),
      _QuickActionItem(
        category: 'STATE-WISE TAXES',
        title: loc.translate('home.stampDutyCalculator'),
        description: loc.translate('home.stampDutyCalculatorDesc'),
        ctaText: exploreBtn.isNotEmpty ? exploreBtn : 'Explore',
        icon: Icons.calculate_rounded,
        accentColor: const Color(0xFF38BDF8), // Blue Accent (matching Scan Agreement)
        onTap: () => _navigateTo(const StampDutyCalculatorScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESSENTIAL LEGAL TOOLS',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF91ADCD),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.translate('home.quickActions'),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 720;

            if (isMultiCol) {
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _QuickActionCard(item: cards[0], isDark: isDark)),
                        const SizedBox(width: 18),
                        Expanded(child: _QuickActionCard(item: cards[1], isDark: isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _QuickActionCard(item: cards[2], isDark: isDark)),
                        const SizedBox(width: 18),
                        Expanded(child: _QuickActionCard(item: cards[3], isDark: isDark)),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: cards.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _QuickActionCard(item: item, isDark: isDark),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  // ==========================================
  // 3. RECENT DOCUMENTS SECTION (SHIMMERING GLASS)
  // ==========================================
  Widget _buildRecentDocumentsSection(BuildContext context, bool isDark) {
    final docs = _recentDocs;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  const Color(0xFF334356).withValues(alpha: 0.4),
                  const Color(0xFF16263B).withValues(alpha: 0.2),
                ]
              : [
                  const Color(0xFFE4DDD0),
                  const Color(0xFF91ADCD).withValues(alpha: 0.2),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.94)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20.8),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF91ADCD).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF91ADCD).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          size: 18,
                          color: Color(0xFF91ADCD),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          loc.translate('home.recentDocuments'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _navigateTo(const RecentDocumentsScreen()),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF91ADCD),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.translate('home.viewAll', {'count': _recentDocs.length.toString()}),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF91ADCD) : const Color(0xFF244A78),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF91ADCD) : const Color(0xFF244A78),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingDocs && _recentDocs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF91ADCD)),
                  ),
                ),
              )
            else if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF91ADCD).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 26,
                          color: Color(0xFF91ADCD),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.translate('home.noAgreementsScanned'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.translate('home.uploadOrScanAgreement'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateTo(const ScanScreen()),
                        icon: const Icon(Icons.document_scanner_rounded, size: 14),
                        label: Text(
                          loc.translate('home.scanOrUploadAgreementBtn'),
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF5F7895) : const Color(0xFF244A78),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              for (int i = 0; i < docs.take(3).length; i++) ...[
                if (i > 0)
                  Divider(
                    color: isDark ? const Color(0xFF334356).withValues(alpha: 0.6) : const Color(0xFFE4DDD0),
                    height: 1,
                  ),
                _HoverDocumentRow(
                  doc: docs[i],
                  isDark: isDark,
                  onTap: () {
                    if (docs[i].analysis.isNotEmpty && docs[i].originalText.isNotEmpty) {
                      _navigateTo(
                        AnalysisScreen(
                          originalText: docs[i].originalText,
                          analysis: docs[i].analysis,
                          documentTitle: docs[i].title,
                          sourceType: docs[i].sourceType,
                          fileData: docs[i].fileData,
                          mimeType: docs[i].mimeType,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${docs[i].title}...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. LATEST LEGAL UPDATES SECTION (SHIMMERING GLASS)
  // ==========================================
  Widget _buildLegalNewsSection(BuildContext context, bool isDark) {
    final news = _legalNews;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  const Color(0xFF334356).withValues(alpha: 0.4),
                  const Color(0xFF16263B).withValues(alpha: 0.2),
                ]
              : [
                  const Color(0xFFE4DDD0),
                  const Color(0xFF91ADCD).withValues(alpha: 0.2),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.94)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20.8),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF91ADCD).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF91ADCD).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.feed_outlined,
                          size: 18,
                          color: Color(0xFF91ADCD),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          loc.translate('home.latestLegalUpdates'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        loc.translate('common.live'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingNews && _legalNews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF91ADCD)),
                  ),
                ),
              )
            else if (news.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    loc.translate('home.noLegalUpdates'),
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else ...[
              for (int i = 0; i < news.take(3).length; i++) ...[
                if (i > 0)
                  Divider(
                    color: isDark ? const Color(0xFF334356).withValues(alpha: 0.6) : const Color(0xFFE4DDD0),
                    height: 1,
                  ),
                _HoverNewsRow(
                  title: (news[i]['title'] ?? 'Legal Notice').toString(),
                  source: (news[i]['source'] ?? 'Legal News').toString(),
                  time: _formatRelativeTime(news[i]['pubDate']),
                  isNew: i == 0 || (news[i]['isWarning'] == true),
                  link: (news[i]['link'] ?? '').toString(),
                  isDark: isDark,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. PROMINENT RERA ADVISORY ALERT CARD (GOLD SHIMMER)
  // ==========================================
  Widget _buildReraAlertCard(BuildContext context, bool isDark, bool isDesktop) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final reraAlert = _legalNews.firstWhere(
      (n) => (n['isWarning'] == true || (n['title'] ?? '').toString().toLowerCase().contains('rera')),
      orElse: () => null,
    );

    final String alertTitle = reraAlert != null
        ? (reraAlert['title'] ?? 'RERA: The regulator that was supposed to protect homebuyers — but has it become part of the problem?')
        : 'RERA: The regulator that was supposed to protect homebuyers — but has it become part of the problem?';

    final String alertSource = reraAlert != null
        ? (reraAlert['source'] ?? 'inventiva.co.in')
        : 'inventiva.co.in';

    final String alertDate = reraAlert != null
        ? 'Latest: ${_formatRelativeTime(reraAlert['pubDate'])}'
        : 'Latest: 26 Aug 2026';

    final String alertDesc = reraAlert != null
        ? 'Regulatory update via $alertSource. Mandatory adherence required for real estate transactions, promoter disclosures, and escrow accounting.'
        : 'Regulatory update via $alertSource. Mandatory adherence required for real estate transactions, promoter disclosures, and escrow accounting.';

    final String alertLink = reraAlert != null ? (reraAlert['link'] ?? '') : '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.45 : 0.35),
            const Color(0xFFFFDF8C).withValues(alpha: isDark ? 0.25 : 0.15),
            const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.15 : 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.3),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.95)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20.7),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 26 : 18,
          vertical: isDesktop ? 22 : 18,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFC5A85E).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 12, color: Color(0xFFC5A85E)),
                            const SizedBox(width: 5),
                            Text(
                              loc.translate('home.reraAlert'),
                              style: GoogleFonts.inter(
                                color: const Color(0xFFC5A85E),
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        alertDate,
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alertTitle,
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alertDesc,
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => _handleReraDetails(context, alertLink, alertTitle, alertDesc),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loc.translate('common.viewDetails'),
                          style: GoogleFonts.inter(
                            color: const Color(0xFFC5A85E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFFC5A85E), size: 14),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A85E).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFC5A85E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFC5A85E).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 12, color: Color(0xFFC5A85E)),
                                const SizedBox(width: 4),
                                Text(
                                  loc.translate('home.reraAlert'),
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC5A85E),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              alertDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alertTitle,
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alertDesc,
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                OutlinedButton(
                  onPressed: () => _handleReraDetails(context, alertLink, alertTitle, alertDesc),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.6),
                    ),
                    foregroundColor: const Color(0xFFC5A85E),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.translate('common.viewDetails'),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC5A85E),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFC5A85E)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleReraDetails(
    BuildContext context,
    String alertLink,
    String alertTitle,
    String alertDesc,
  ) async {
    if (alertLink.isNotEmpty) {
      final Uri url = Uri.parse(alertLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (dialogContext) {
          final loc = ref.read(localeProvider.notifier);
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
              ),
            ),
            title: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFC5A85E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.translate('home.reraAdvisoryDetails'),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              '$alertTitle\n\n$alertDesc\n\n${loc.translate('home.reraStatutoryNote')}',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF5F7895) : const Color(0xFF244A78),
                  foregroundColor: Colors.white,
                ),
                child: Text(loc.translate('common.understood')),
              ),
            ],
          );
        },
      );
    }
  }

  // ==========================================
  // FLOATING AI ASSISTANT BUTTON
  // ==========================================
  Widget _buildFloatingAiButton(BuildContext context, bool isDark) {
    return _FloatingLegalAiButton(
      onTap: () => _navigateTo(const ChatScreen()),
      isDark: isDark,
    );
  }
}

// ==========================================
// CUSTOM ILLUSTRATION PAINTER (EDITORIAL LINE ART)
// ==========================================
class _LegalPropertyIllustrationPainter extends CustomPainter {
  final Color accentBlue;
  final Color accentGold;
  final bool isDark;

  _LegalPropertyIllustrationPainter({
    required this.accentBlue,
    required this.accentGold,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = accentBlue.withValues(alpha: isDark ? 0.38 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldStroke = Paint()
      ..color = accentGold.withValues(alpha: isDark ? 0.45 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final subtlePaint = Paint()
      ..color = accentBlue.withValues(alpha: isDark ? 0.2 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = accentBlue.withValues(alpha: isDark ? 0.06 : 0.03)
      ..style = PaintingStyle.fill;

    // 1. Property / Building Outline (Left portion, x: 10 to 80)
    final b1Rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 32, 22, 48),
      const Radius.circular(2),
    );
    canvas.drawRRect(b1Rect, fillPaint);
    canvas.drawRRect(b1Rect, strokePaint);
    for (double y = 40; y <= 70; y += 10) {
      canvas.drawLine(Offset(18, y), Offset(22, y), subtlePaint);
      canvas.drawLine(Offset(25, y), Offset(29, y), subtlePaint);
    }

    final b2Path = Path()
      ..moveTo(34, 80)
      ..lineTo(34, 24)
      ..lineTo(48, 12)
      ..lineTo(62, 24)
      ..lineTo(62, 80);
    canvas.drawPath(b2Path, fillPaint);
    canvas.drawPath(b2Path, strokePaint);
    canvas.drawLine(const Offset(48, 12), const Offset(48, 80), subtlePaint);

    final b3Path = Path()
      ..moveTo(62, 80)
      ..lineTo(62, 42)
      ..lineTo(76, 42)
      ..lineTo(76, 80);
    canvas.drawPath(b3Path, fillPaint);
    canvas.drawPath(b3Path, strokePaint);
    canvas.drawLine(const Offset(8, 80), const Offset(82, 80), subtlePaint);

    // 2. Scale of Justice (Center portion, x: 88 to 134)
    canvas.drawLine(const Offset(108, 22), const Offset(108, 72), strokePaint);
    canvas.drawLine(const Offset(98, 72), const Offset(118, 72), strokePaint);
    canvas.drawCircle(const Offset(108, 20), 2.5, goldStroke);
    canvas.drawLine(const Offset(90, 28), const Offset(126, 28), goldStroke);

    final leftStrings = Path()
      ..moveTo(90, 28)
      ..lineTo(83, 44)
      ..moveTo(90, 28)
      ..lineTo(97, 44);
    canvas.drawPath(leftStrings, subtlePaint);
    final leftPan = Path()
      ..moveTo(81, 44)
      ..quadraticBezierTo(90, 49, 99, 44);
    canvas.drawPath(leftPan, strokePaint);

    final rightStrings = Path()
      ..moveTo(126, 28)
      ..lineTo(119, 44)
      ..moveTo(126, 28)
      ..lineTo(133, 44);
    canvas.drawPath(rightStrings, subtlePaint);
    final rightPan = Path()
      ..moveTo(117, 44)
      ..quadraticBezierTo(126, 49, 135, 44);
    canvas.drawPath(rightPan, strokePaint);

    // 3. Legal Document & Verified Shield (Right portion, x: 140 to 200)
    final docPath = Path()
      ..moveTo(146, 76)
      ..lineTo(146, 18)
      ..lineTo(170, 18)
      ..lineTo(182, 30)
      ..lineTo(182, 76)
      ..close();
    canvas.drawPath(docPath, fillPaint);
    canvas.drawPath(docPath, strokePaint);

    final foldPath = Path()
      ..moveTo(170, 18)
      ..lineTo(170, 30)
      ..lineTo(182, 30);
    canvas.drawPath(foldPath, strokePaint);

    canvas.drawLine(const Offset(152, 32), const Offset(166, 32), subtlePaint);
    canvas.drawLine(const Offset(152, 40), const Offset(176, 40), subtlePaint);
    canvas.drawLine(const Offset(152, 48), const Offset(176, 48), subtlePaint);
    canvas.drawLine(const Offset(152, 56), const Offset(168, 56), subtlePaint);

    // AI Checkmark circle badge
    canvas.drawCircle(const Offset(172, 64), 5.5, goldStroke);
    final checkPath = Path()
      ..moveTo(169.5, 64)
      ..lineTo(171.5, 66)
      ..lineTo(175, 62);
    canvas.drawPath(checkPath, goldStroke);
  }

  @override
  bool shouldRepaint(covariant _LegalPropertyIllustrationPainter oldDelegate) {
    return oldDelegate.accentBlue != accentBlue ||
        oldDelegate.accentGold != accentGold ||
        oldDelegate.isDark != isDark;
  }
}

// ==========================================
// QUICK ACTION CARD DATA & SHIMMERING GLASS COMPONENT
// ==========================================
class _QuickActionItem {
  final String category;
  final String title;
  final String description;
  final String ctaText;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badgeText;
  final bool showProgress;
  final double progress;

  _QuickActionItem({
    required this.category,
    required this.title,
    required this.description,
    required this.ctaText,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.badgeText,
    this.showProgress = false,
    this.progress = 0.0,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickActionItem item;
  final bool isDark;

  const _QuickActionCard({
    required this.item,
    required this.isDark,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(1.3), // Gradient border padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                      item.accentColor.withValues(alpha: 0.85),
                      const Color(0xFFC5A85E).withValues(alpha: 0.65),
                      item.accentColor.withValues(alpha: 0.3),
                    ]
                  : (isDark
                      ? [
                          item.accentColor.withValues(alpha: 0.22),
                          const Color(0xFF334356).withValues(alpha: 0.45),
                          const Color(0xFF16263B).withValues(alpha: 0.2),
                        ]
                      : [
                          const Color(0xFFE4DDD0),
                          item.accentColor.withValues(alpha: 0.25),
                          const Color(0xFFE4DDD0),
                        ]),
            ),
            boxShadow: [
              BoxShadow(
                color: item.accentColor.withValues(alpha: _isHovered ? (isDark ? 0.28 : 0.12) : 0.0),
                blurRadius: _isHovered ? 24 : 0,
                spreadRadius: _isHovered ? 1 : 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? (_isHovered ? 0.4 : 0.22) : (_isHovered ? 0.08 : 0.03)),
                blurRadius: _isHovered ? 18 : 8,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark
                  ? (_isHovered ? const Color(0xFF1E3552).withValues(alpha: 0.96) : const Color(0xFF182A40).withValues(alpha: 0.94))
                  : (_isHovered ? const Color(0xFFFAF6EB).withValues(alpha: 0.98) : const Color(0xFFFDFBF7).withValues(alpha: 0.96)),
              borderRadius: BorderRadius.circular(18.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Icon Container + Category Tag / Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: _isHovered ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: _isHovered ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: item.accentColor.withValues(alpha: _isHovered ? 0.55 : 0.25),
                              ),
                              boxShadow: [
                                if (_isHovered)
                                  BoxShadow(
                                    color: item.accentColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                            child: Icon(item.icon, color: item.accentColor, size: 20),
                          ),
                        ),
                        if (item.badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: item.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.badgeText!,
                                  style: GoogleFonts.inter(
                                    color: item.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            item.category,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: item.accentColor.withValues(alpha: 0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Description
                    SizedBox(
                      height: 40,
                      child: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        ),
                      ),
                    ),

                    // Optional Progress Bar for checklist
                    if (item.showProgress) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 3.5,
                          width: double.infinity,
                          color: item.accentColor.withValues(alpha: 0.15),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: item.progress > 0 ? item.progress : 0.0,
                            child: Container(
                              color: item.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom CTA Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.ctaText.replaceAll('→', '').trim(),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: item.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedSlide(
                      offset: _isHovered ? const Offset(0.3, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: item.accentColor,
                        size: 14,
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
}

// ==========================================
// RECENT DOCUMENT MODEL & HOVER ROW
// ==========================================
class _RecentDocItem {
  final String id;
  final String title;
  final String dateText;
  final String riskLabel;
  final IconData riskIcon;
  final Color riskColor;
  final String docSize;
  final String originalText;
  final List<dynamic> analysis;
  final String sourceType;
  final String? fileData;
  final String? mimeType;

  _RecentDocItem({
    required this.id,
    required this.title,
    required this.dateText,
    required this.riskLabel,
    required this.riskIcon,
    required this.riskColor,
    required this.docSize,
    this.originalText = '',
    this.analysis = const [],
    this.sourceType = 'PDF Document',
    this.fileData,
    this.mimeType,
  });

  factory _RecentDocItem.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?) ?? 'Legal Document';
    final riskLevel = (json['riskLevel'] as String?) ?? 'Low Risk';
    final docSize = (json['docSize'] as String?) ?? '1.2 MB';
    final createdAt = json['createdAt'];
    final dateText = 'Scanned ${_formatRelativeTime(createdAt)}';
    final originalText = (json['originalText'] as String?) ?? '';
    final analysis = (json['analysis'] as List<dynamic>?) ?? [];
    final sourceType = (json['sourceType'] as String?) ?? 'PDF Document';
    final fileData = json['fileData'] as String?;
    final mimeType = json['mimeType'] as String?;

    Color riskColor = const Color(0xFF10B981);
    IconData riskIcon = Icons.check_circle_outline_rounded;
    final rLower = riskLevel.toLowerCase();
    if (rLower.contains('high') || rLower.contains('red')) {
      riskColor = const Color(0xFFEF4444);
      riskIcon = Icons.error_outline_rounded;
    } else if (rLower.contains('medium') || rLower.contains('yellow')) {
      riskColor = const Color(0xFFF59E0B);
      riskIcon = Icons.warning_amber_rounded;
    }

    return _RecentDocItem(
      id: (json['_id'] as String?) ?? '',
      title: title,
      dateText: dateText,
      riskLabel: riskLevel,
      riskIcon: riskIcon,
      riskColor: riskColor,
      docSize: docSize,
      originalText: originalText,
      analysis: analysis,
      sourceType: sourceType,
      fileData: fileData,
      mimeType: mimeType,
    );
  }
}

String _formatRelativeTime(dynamic dateValue) {
  if (dateValue == null) return 'Recent';
  try {
    DateTime? dt;
    if (dateValue is DateTime) {
      dt = dateValue;
    } else {
      dt = DateTime.tryParse(dateValue.toString());
      if (dt == null) {
        final raw = dateValue.toString();
        final parts = raw.split(' ');
        if (parts.length >= 4) {
          return '${parts[1]} ${parts[2]} ${parts[3]}';
        }
      }
    }
    if (dt != null) {
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60 && diff.inSeconds >= 0) {
        return 'Just now';
      } else if (diff.inMinutes < 60 && diff.inMinutes >= 0) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24 && diff.inHours >= 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7 && diff.inDays > 1) {
        return '${diff.inDays}d ago';
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthName = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
        return '${dt.day} $monthName ${dt.year}';
      }
    }
  } catch (_) {}
  return dateValue.toString();
}

class _HoverDocumentRow extends StatefulWidget {
  final _RecentDocItem doc;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverDocumentRow({
    required this.doc,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverDocumentRow> createState() => _HoverDocumentRowState();
}

class _HoverDocumentRowState extends State<_HoverDocumentRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    IconData formatIcon = Icons.article_rounded;
    Color formatColor = const Color(0xFF91ADCD);

    final sLower = widget.doc.sourceType.toLowerCase();
    if (sLower.contains('photo') || sLower.contains('image')) {
      formatIcon = Icons.image_rounded;
      formatColor = const Color(0xFFC5A85E);
    } else if (sLower.contains('text')) {
      formatIcon = Icons.notes_rounded;
      formatColor = const Color(0xFF38BDF8);
    } else if (sLower.contains('pdf')) {
      formatIcon = Icons.picture_as_pdf_rounded;
      formatColor = const Color(0xFFEF4444);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF223A58) : const Color(0xFFF4EFE0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: formatColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(formatIcon, color: formatColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.doc.sourceType} • ${widget.doc.dateText} • ${widget.doc.docSize}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge (Transparent bg + fine colored border)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: widget.doc.riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.doc.riskColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.doc.riskIcon, size: 12, color: widget.doc.riskColor),
                    const SizedBox(width: 4),
                    Text(
                      widget.doc.riskLabel,
                      style: GoogleFonts.inter(
                        color: widget.doc.riskColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              AnimatedSlide(
                offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _isHovered
                      ? const Color(0xFF91ADCD)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  size: 19,
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
// LEGAL NEWS HOVER ROW
// ==========================================
class _HoverNewsRow extends StatefulWidget {
  final String title;
  final String source;
  final String time;
  final bool isNew;
  final String link;
  final bool isDark;

  const _HoverNewsRow({
    required this.title,
    required this.source,
    required this.time,
    required this.isNew,
    required this.link,
    required this.isDark,
  });

  @override
  State<_HoverNewsRow> createState() => _HoverNewsRowState();
}

class _HoverNewsRowState extends State<_HoverNewsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          if (widget.link.isNotEmpty) {
            final Uri url = Uri.parse(widget.link);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF223A58) : const Color(0xFFF4EFE0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF91ADCD).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.feed_outlined, color: Color(0xFF91ADCD), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.source} • ${widget.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isNew) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFC5A85E),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              AnimatedSlide(
                offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: _isHovered
                      ? const Color(0xFF91ADCD)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
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
// FLOATING AI ASSISTANT BUTTON
// ==========================================
class _FloatingLegalAiButton extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _FloatingLegalAiButton({
    required this.onTap,
    required this.isDark,
  });

  @override
  ConsumerState<_FloatingLegalAiButton> createState() => _FloatingLegalAiButtonState();
}

class _FloatingLegalAiButtonState extends ConsumerState<_FloatingLegalAiButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF244A78), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: _isHovered ? 0.7 : 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: _isHovered ? 0.45 : 0.3),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 17),
              const SizedBox(width: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Text(
                  _isHovered ? loc.translate('home.needLegalHelp') : loc.translate('home.askLegalAi'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.2,
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
