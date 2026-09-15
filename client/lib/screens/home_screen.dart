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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Ambient breathing animation
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
        : 'User';

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
      key: _scaffoldKey,
      drawer: !isDesktop ? _buildSidebarDrawer(context, isDark, user) : null,
      backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // 1. PRIMARY PERSISTENT SIDEBAR NAVIGATION
          // ==========================================
          if (isDesktop)
            _buildDesktopSidebar(context, isDark, user),

          // ==========================================
          // 2. INTELLIGENT WORKSPACE / DASHBOARD
          // ==========================================
          Expanded(
            child: MouseRegion(
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
                    // Subtle Ambient Aurora
                    AnimatedBuilder(
                      animation: _ambientController,
                      builder: (context, child) {
                        final pulse = _pulseAnimation.value;
                        return Stack(
                          children: [
                            Positioned(
                              top: -120 + (20 * _ambientController.value),
                              left: -100 + (15 * _ambientController.value),
                              child: IgnorePointer(
                                child: Container(
                                  width: 520 * pulse,
                                  height: 520 * pulse,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.10 : 0.06),
                                        const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.05 : 0.02),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 60 + (25 * (1.0 - _ambientController.value)),
                              right: -120,
                              child: IgnorePointer(
                                child: Container(
                                  width: 560 * (2.0 - pulse),
                                  height: 560 * (2.0 - pulse),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.07 : 0.04),
                                        const Color(0xFFFFDF8C).withValues(alpha: isDark ? 0.03 : 0.015),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isDesktop)
                              Positioned(
                                left: _mousePos.dx - 300,
                                top: _mousePos.dy - 300,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 600,
                                    height: 600,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.045 : 0.025),
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
                          // Top Navigation Bar (Mobile / Drawer only)
                          if (!isDesktop) _buildTopNav(context, isDark, isDesktop),

                          // Scrollable Workspace Content
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
                                          // A. Workspace Greeting & Hero
                                          _buildHeaderGreeting(context, isDark, isDesktop, greetingName),
                                          const SizedBox(height: 24),

                                          // B. High-Level Real-Data Summary Metrics Row
                                          _buildSummaryMetricsRow(context, isDark, isDesktop),
                                          const SizedBox(height: 28),

                                          // C. Main Workspace Feature: Latest Document Analysis Review
                                          _buildLatestDocumentReview(context, isDark, isDesktop),
                                          const SizedBox(height: 28),

                                          // D & E & F. 2-Column Intelligence Grid
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              if (constraints.maxWidth >= 900) {
                                                return IntrinsicHeight(
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      Expanded(
                                                        flex: 6,
                                                        child: Column(
                                                          children: [
                                                            _buildRiskBreakdownCard(context, isDark),
                                                            const SizedBox(height: 24),
                                                            _buildChecklistProgressCard(context, isDark),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 24),
                                                      Expanded(
                                                        flex: 5,
                                                        child: Column(
                                                          children: [
                                                            _buildRecentActivityCard(context, isDark),
                                                            const SizedBox(height: 24),
                                                            _buildLegalUpdatesCard(context, isDark),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } else {
                                                return Column(
                                                  children: [
                                                    _buildRiskBreakdownCard(context, isDark),
                                                    const SizedBox(height: 24),
                                                    _buildChecklistProgressCard(context, isDark),
                                                    const SizedBox(height: 24),
                                                    _buildRecentActivityCard(context, isDark),
                                                    const SizedBox(height: 24),
                                                    _buildLegalUpdatesCard(context, isDark),
                                                  ],
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 28),

                                          // G. RERA Statutory Advisory Notice
                                          _buildReraAwarenessCard(context, isDark, isDesktop),
                                          const SizedBox(height: 40),
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
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DESKTOP SIDEBAR WIDGET
  // ==========================================
  Widget _buildDesktopSidebar(BuildContext context, bool isDark, dynamic user) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13253A) : const Color(0xFFF7F1D0),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: _buildSidebarContent(context, isDark, user, isDrawer: false),
      ),
    );
  }

  // ==========================================
  // MOBILE SIDEBAR DRAWER
  // ==========================================
  Widget _buildSidebarDrawer(BuildContext context, bool isDark, dynamic user) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF13253A) : const Color(0xFFF7F1D0),
      child: SafeArea(
        child: _buildSidebarContent(context, isDark, user, isDrawer: true),
      ),
    );
  }

  // ==========================================
  // SHARED SIDEBAR CONTENT (PRIMARY NAVIGATION)
  // ==========================================
  Widget _buildSidebarContent(BuildContext context, bool isDark, dynamic user, {required bool isDrawer}) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final String userName = (user?.fullName != null && user!.fullName.trim().isNotEmpty)
        ? user.fullName.trim()
        : 'User';
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Brand Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                        fontSize: 8,
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

        Divider(
          color: isDark ? const Color(0xFF334356).withValues(alpha: 0.6) : const Color(0xFFE4DDD0),
          height: 1,
        ),

        // Navigation Menu List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            children: [
              // SECTION: OVERVIEW
              _buildSidebarSectionLabel(loc.translate('sidebar.overview'), isDark),
              _SidebarNavItem(
                icon: Icons.dashboard_rounded,
                label: loc.translate('sidebar.dashboard'),
                isActive: true,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 14),

              // SECTION: WORKSPACE
              _buildSidebarSectionLabel(loc.translate('sidebar.workspace'), isDark),
              _SidebarNavItem(
                icon: Icons.folder_open_rounded,
                label: loc.translate('sidebar.documents'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  _navigateTo(const RecentDocumentsScreen());
                },
              ),
              _SidebarNavItem(
                icon: Icons.document_scanner_rounded,
                label: loc.translate('sidebar.riskAnalysis'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  _navigateTo(const ScanScreen());
                },
              ),
              _SidebarNavItem(
                icon: Icons.checklist_rounded,
                label: loc.translate('sidebar.checklists'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  _navigateTo(const ChecklistsListScreen());
                },
              ),
              const SizedBox(height: 14),

              // SECTION: LEGAL TOOLS
              _buildSidebarSectionLabel(loc.translate('sidebar.legalTools'), isDark),
              _SidebarNavItem(
                icon: Icons.auto_awesome_rounded,
                label: loc.translate('sidebar.legalAi'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  _navigateTo(const ChatScreen());
                },
              ),
              _SidebarNavItem(
                icon: Icons.calculate_rounded,
                label: loc.translate('sidebar.stampDuty'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  _navigateTo(const StampDutyCalculatorScreen());
                },
              ),
              const SizedBox(height: 14),

              // SECTION: LEGAL INFORMATION
              _buildSidebarSectionLabel(loc.translate('sidebar.legalInfo'), isDark),
              _SidebarNavItem(
                icon: Icons.shield_outlined,
                label: loc.translate('sidebar.reraCompliance'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  _openReraDetailsModal();
                },
              ),
            ],
          ),
        ),

        Divider(
          color: isDark ? const Color(0xFF334356).withValues(alpha: 0.6) : const Color(0xFFE4DDD0),
          height: 1,
        ),

        // Bottom Settings & Profile Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            children: [
              _SidebarNavItem(
                icon: Icons.settings_outlined,
                label: loc.translate('sidebar.settings'),
                isActive: false,
                isDark: isDark,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  showSettingsDialog(context, ref);
                },
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  showProfileDialog(context, ref);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF91ADCD).withValues(alpha: 0.2),
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              loc.translate('sidebar.profile'),
                              style: GoogleFonts.inter(
                                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                fontSize: 10.5,
                              ),
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
      ],
    );
  }

  Widget _buildSidebarSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF91ADCD).withValues(alpha: 0.75) : const Color(0xFF63748A),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  void _openReraDetailsModal() {
    final reraAlert = _legalNews.firstWhere(
      (n) => (n['isWarning'] == true || (n['title'] ?? '').toString().toLowerCase().contains('rera')),
      orElse: () => null,
    );

    final String alertTitle = reraAlert != null
        ? (reraAlert['title'] ?? 'RERA: The regulator that was supposed to protect homebuyers — but has it become part of the problem?')
        : 'RERA: The regulator that was supposed to protect homebuyers — but has it become part of the problem?';

    final String alertDesc = reraAlert != null
        ? 'Regulatory update. Mandatory adherence required for real estate transactions, promoter disclosures, and escrow accounting.'
        : 'Regulatory update. Mandatory adherence required for real estate transactions, promoter disclosures, and escrow accounting.';

    final String alertLink = reraAlert != null ? (reraAlert['link'] ?? '') : '';

    _handleReraDetails(context, alertLink, alertTitle, alertDesc);
  }

  // ==========================================
  // TOP NAVIGATION BAR
  // ==========================================
  Widget _buildTopNav(BuildContext context, bool isDark, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE)).withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
            ),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 6),
          Text(
            'LawBuddy',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // A. WORKSPACE GREETING & HERO
  // ==========================================
  Widget _buildHeaderGreeting(BuildContext context, bool isDark, bool isDesktop, String userName) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF38BDF8).withValues(alpha: 0.22),
                  const Color(0xFFC5A85E).withValues(alpha: 0.14),
                  const Color(0xFF334356).withValues(alpha: 0.28),
                ]
              : [
                  const Color(0xFFE4DDD0),
                  const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  const Color(0xFFE4DDD0),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
          borderRadius: BorderRadius.circular(18.8),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 28.0 : 18.0,
          vertical: isDesktop ? 22.0 : 18.0,
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
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF92764B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'YOUR PROPERTY • YOUR RIGHTS • YOUR CONFIDENCE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF244A78),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Greeting Headline
                      Text(
                        loc.translate('home.greeting', {'greeting': _getGreeting(), 'name': userName}),
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 24 : 19,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Workspace Subtitle
                      Text(
                        'Review your agreements, check RERA risks, and make informed property decisions with AI built for Indian real estate.',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 13 : 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        ),
                      ),
                    ],
                  ),
                ),

                if (showIllustration) ...[
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 190,
                    height: 80,
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
  // B. SUMMARY METRICS ROW (REAL DATA ONLY)
  // ==========================================
  Widget _buildSummaryMetricsRow(BuildContext context, bool isDark, bool isDesktop) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final int analyzedDocsCount = _recentDocs
        .where((d) => d.analysisStatus == 'completed' || d.analysis.isNotEmpty)
        .length;

    int highRiskFlags = 0;
    for (final doc in _recentDocs) {
      if (doc.analysis.isNotEmpty) {
        for (final item in doc.analysis) {
          if (item is Map) {
            final rLevel = (item['riskLevel'] ?? item['category'] ?? '').toString().toLowerCase();
            if (rLevel.contains('high') || rLevel.contains('red')) {
              highRiskFlags++;
            }
          }
        }
      } else if (doc.riskLabel.toLowerCase().contains('high')) {
        highRiskFlags++;
      }
    }

    final int checklistCount = _checklists.length;

    int totalTasks = 0;
    int completedTasks = 0;
    for (final cl in _checklists) {
      final items = (cl['items'] as List<dynamic>?) ?? [];
      totalTasks += items.length;
      completedTasks += items.where((it) => it['isCompleted'] == true).length;
    }
    final double checklistProgress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    final cards = [
      _WorkspaceMetricData(
        icon: Icons.description_outlined,
        title: loc.translate('home.totalScannedDocs'),
        value: analyzedDocsCount.toString(),
        subtitle: loc.translate('home.totalScannedDocsSub'),
        accentColor: const Color(0xFF38BDF8),
      ),
      _WorkspaceMetricData(
        icon: highRiskFlags > 0 ? Icons.warning_amber_rounded : Icons.shield_outlined,
        title: loc.translate('home.highRiskCount'),
        value: highRiskFlags.toString(),
        subtitle: highRiskFlags > 0
            ? '$highRiskFlags ${loc.translate('home.highRiskCountSub')}'
            : loc.translate('home.noHighRisks'),
        accentColor: highRiskFlags > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      ),
      _WorkspaceMetricData(
        icon: Icons.checklist_rounded,
        title: loc.translate('home.dueDiligenceProgress'),
        value: '${(checklistProgress * 100).toInt()}%',
        subtitle: totalTasks > 0 ? '$completedTasks of $totalTasks tasks done' : loc.translate('home.checklistZeroTasks'),
        accentColor: const Color(0xFFC5A85E),
      ),
      _WorkspaceMetricData(
        icon: Icons.assignment_outlined,
        title: loc.translate('home.activeChecklists'),
        value: checklistCount.toString(),
        subtitle: checklistCount == 0
            ? loc.translate('home.activeChecklistsZero')
            : loc.translate('home.activeChecklistsBadge', {
                'count': checklistCount.toString(),
                'unit': loc.translate(checklistCount == 1 ? 'home.checklistUnitSingular' : 'home.checklistUnitPlural'),
              }),
        accentColor: const Color(0xFF91ADCD),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: _WorkspaceMetricCard(data: cards[i], isDark: isDark)),
              ],
            ],
          );
        } else if (constraints.maxWidth >= 520) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _WorkspaceMetricCard(data: cards[0], isDark: isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _WorkspaceMetricCard(data: cards[1], isDark: isDark)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _WorkspaceMetricCard(data: cards[2], isDark: isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _WorkspaceMetricCard(data: cards[3], isDark: isDark)),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkspaceMetricCard(data: c, isDark: isDark),
                    ))
                .toList(),
          );
        }
      },
    );
  }

  // ==========================================
  // C. MAIN WORKSPACE: LATEST DOCUMENT REVIEW
  // ==========================================
  Widget _buildLatestDocumentReview(BuildContext context, bool isDark, bool isDesktop) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final bool hasDocs = _recentDocs.isNotEmpty;
    final _RecentDocItem? latestDoc = hasDocs ? _recentDocs.first : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF38BDF8).withValues(alpha: 0.22),
                  const Color(0xFF334356).withValues(alpha: 0.35),
                  const Color(0xFF16263B).withValues(alpha: 0.2),
                ]
              : [
                  const Color(0xFFE4DDD0),
                  const Color(0xFF91ADCD).withValues(alpha: 0.2),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.95)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(18.8),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Color(0xFF38BDF8), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('home.latestAnalysisReview'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              loc.translate('home.latestAnalysisSub'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDocs) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _navigateTo(const RecentDocumentsScreen()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
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
              ],
            ),
            const SizedBox(height: 18),

            // Content: Active Latest Document vs Empty State
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
            else if (!hasDocs || latestDoc == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
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
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16273C) : const Color(0xFFF6F1E3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334356).withValues(alpha: 0.8) : const Color(0xFFE4DDD0),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;

                    final docInfo = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: latestDoc.riskColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: latestDoc.riskColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(latestDoc.riskIcon, size: 12, color: latestDoc.riskColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    latestDoc.riskLabel,
                                    style: GoogleFonts.inter(
                                      color: latestDoc.riskColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${latestDoc.sourceType} • ${latestDoc.dateText}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          latestDoc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latestDoc.analysis.isNotEmpty
                              ? '${latestDoc.analysis.length} clauses evaluated across tenancy & title compliance'
                              : 'AI clause extraction and legal risk assessment complete',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                          ),
                        ),
                      ],
                    );

                    final actionButton = ElevatedButton.icon(
                      onPressed: () {
                        if (latestDoc.analysis.isNotEmpty && latestDoc.originalText.isNotEmpty) {
                          _navigateTo(
                            AnalysisScreen(
                              originalText: latestDoc.originalText,
                              analysis: latestDoc.analysis,
                              documentTitle: latestDoc.title,
                              sourceType: latestDoc.sourceType,
                              fileData: latestDoc.fileData,
                              mimeType: latestDoc.mimeType,
                            ),
                          );
                        } else {
                          _navigateTo(const RecentDocumentsScreen());
                        }
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: Text(
                        loc.translate('home.viewFullAnalysis'),
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF244A78) : const Color(0xFF244A78),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          docInfo,
                          const SizedBox(height: 14),
                          actionButton,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: docInfo),
                        const SizedBox(width: 16),
                        actionButton,
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // D. RISK BREAKDOWN CARD
  // ==========================================
  Widget _buildRiskBreakdownCard(BuildContext context, bool isDark) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final int total = _recentDocs.length;
    final int highRisk = _recentDocs.where((d) => d.riskLabel.toLowerCase().contains('high')).length;
    final int mediumRisk = _recentDocs.where((d) => d.riskLabel.toLowerCase().contains('medium') || d.riskLabel.toLowerCase().contains('caution')).length;
    final int lowRisk = total - highRisk - mediumRisk > 0 ? (total - highRisk - mediumRisk) : 0;

    final double highPct = total > 0 ? (highRisk / total) : 0.0;
    final double medPct = total > 0 ? (mediumRisk / total) : 0.0;
    final double lowPct = total > 0 ? (lowRisk / total) : (total == 0 ? 1.0 : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFFEF4444), size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('home.riskDistribution'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      ),
                    ),
                    Text(
                      loc.translate('home.riskDistributionSub'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Multi-Segment Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: Row(
                children: [
                  if (highPct > 0)
                    Flexible(
                      flex: (highPct * 100).toInt(),
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  if (medPct > 0)
                    Flexible(
                      flex: (medPct * 100).toInt(),
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (lowPct > 0)
                    Flexible(
                      flex: (lowPct * 100).toInt(),
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _buildRiskLegendItem(
                color: const Color(0xFFEF4444),
                label: loc.translate('home.highRiskLabel'),
                count: highRisk,
                isDark: isDark,
              ),
              _buildRiskLegendItem(
                color: const Color(0xFFF59E0B),
                label: loc.translate('home.mediumRiskLabel'),
                count: mediumRisk,
                isDark: isDark,
              ),
              _buildRiskLegendItem(
                color: const Color(0xFF10B981),
                label: loc.translate('home.lowRiskLabel'),
                count: total > 0 ? lowRisk : 0,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegendItem({
    required Color color,
    required String label,
    required int count,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // E. DUE DILIGENCE CHECKLIST PROGRESS CARD
  // ==========================================
  Widget _buildChecklistProgressCard(BuildContext context, bool isDark) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    int totalTasks = 0;
    int completedTasks = 0;
    String activeTitle = 'Property Purchase Diligence';
    List<dynamic> pendingItems = [];

    for (final cl in _checklists) {
      if (cl['title'] != null && cl['title'].toString().isNotEmpty) {
        activeTitle = cl['title'].toString();
      }
      final items = (cl['items'] as List<dynamic>?) ?? [];
      totalTasks += items.length;
      for (final it in items) {
        if (it['isCompleted'] == true) {
          completedTasks++;
        } else if (pendingItems.length < 2) {
          pendingItems.add(it);
        }
      }
    }
    final double checklistProgress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A85E).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.checklist_rounded, color: Color(0xFFC5A85E), size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('home.dueDiligenceSection'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            ),
                          ),
                          Text(
                            activeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(checklistProgress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC5A85E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              width: double.infinity,
              color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: checklistProgress > 0 ? checklistProgress : 0.0,
                child: Container(color: const Color(0xFFC5A85E)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sample Upcoming Tasks
          if (pendingItems.isNotEmpty) ...[
            for (final it in pendingItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (it['task'] ?? it['title'] ?? 'Title search & Encumbrance check').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Text(
              totalTasks > 0 ? 'All due diligence verification tasks completed' : 'No active transaction checklists',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _navigateTo(const ChecklistsListScreen()),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: Text(
                loc.translate('home.openChecklist'),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC5A85E),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // F. RECENT ACTIVITY TIMELINE CARD
  // ==========================================
  Widget _buildRecentActivityCard(BuildContext context, bool isDark) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final activities = <Map<String, dynamic>>[];

    for (final d in _recentDocs.take(3)) {
      activities.add({
        'title': 'Document scanned: ${d.title}',
        'time': d.dateText.replaceAll('Scanned ', ''),
        'icon': Icons.description_outlined,
        'color': const Color(0xFF38BDF8),
      });
    }

    if (activities.isEmpty) {
      activities.add({
        'title': 'Workspace initialized',
        'time': 'Recent',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF91ADCD).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFF91ADCD), size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('home.recentActivity'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      ),
                    ),
                    Text(
                      loc.translate('home.recentActivitySub'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          for (int i = 0; i < activities.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activities[i]['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < activities.length - 1)
                      Container(
                        width: 1.2,
                        height: 24,
                        color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activities[i]['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        ),
                      ),
                      Text(
                        activities[i]['time'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // G. LEGAL INTELLIGENCE & NEWS CARD
  // ==========================================
  Widget _buildLegalUpdatesCard(BuildContext context, bool isDark) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final news = _legalNews;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.feed_outlined, color: Color(0xFF10B981), size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('home.legalIntelligence'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            ),
                          ),
                          Text(
                            loc.translate('home.legalIntelligenceSub'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  loc.translate('common.live'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingNews && _legalNews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF91ADCD)),
                ),
              ),
            )
          else if (news.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                loc.translate('home.noLegalUpdates'),
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            for (int i = 0; i < news.take(2).length; i++) ...[
              InkWell(
                onTap: () async {
                  final link = (news[i]['link'] ?? '').toString();
                  if (link.isNotEmpty) {
                    final uri = Uri.parse(link);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (news[i]['title'] ?? 'Legal Notice').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              '${news[i]['source'] ?? 'Legal News'} • ${_formatRelativeTime(news[i]['pubDate'])}',
                              style: GoogleFonts.inter(
                                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF91ADCD) : const Color(0xFF63748A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ==========================================
  // H. RERA STATUTORY AWARENESS CARD
  // ==========================================
  Widget _buildReraAwarenessCard(BuildContext context, bool isDark, bool isDesktop) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final reraAlert = _legalNews.firstWhere(
      (n) => (n['isWarning'] == true || (n['title'] ?? '').toString().toLowerCase().contains('rera')),
      orElse: () => null,
    );

    final String alertTitle = reraAlert != null
        ? (reraAlert['title'] ?? 'RERA: Promoter Escrow & Statutory Handover Compliance Under Section 18')
        : 'RERA: Promoter Escrow & Statutory Handover Compliance Under Section 18';

    final String alertDesc = reraAlert != null
        ? 'Regulatory notice via ${reraAlert['source'] ?? 'inventiva.co.in'}. Mandatory promoter disclosures and statutory interest protections apply to all registered transactions.'
        : 'Mandatory promoter disclosures and statutory interest protections apply to all registered transactions.';

    final String alertLink = reraAlert != null ? (reraAlert['link'] ?? '') : '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.35 : 0.25),
            const Color(0xFFFFDF8C).withValues(alpha: isDark ? 0.2 : 0.12),
            const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.12 : 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B2F48).withValues(alpha: 0.95)
              : const Color(0xFFFBF8EE).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16.8),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 22 : 16,
          vertical: isDesktop ? 18 : 16,
        ),
        child: LayoutBuilder(
          builder: (context, reraConstraints) {
            final isNarrow = reraConstraints.maxWidth < 620;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFC5A85E).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFFC5A85E),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          loc.translate('home.reraAlert'),
                          style: GoogleFonts.inter(
                            color: const Color(0xFFC5A85E),
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alertTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alertDesc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => _handleReraDetails(context, alertLink, alertTitle, alertDesc),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFFC5A85E).withValues(alpha: 0.6),
                        ),
                        foregroundColor: const Color(0xFFC5A85E),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.translate('common.viewDetails'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFC5A85E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFFC5A85E)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFC5A85E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              loc.translate('home.reraAlert'),
                              style: GoogleFonts.inter(
                                color: const Color(0xFFC5A85E),
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alertTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alertDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => _handleReraDetails(context, alertLink, alertTitle, alertDesc),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.6),
                    ),
                    foregroundColor: const Color(0xFFC5A85E),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.translate('common.viewDetails'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC5A85E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFFC5A85E)),
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
}

// ==========================================
// SIDEBAR NAVIGATION ITEM WIDGET
// ==========================================
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isActive = widget.isActive;

    Color itemColor;
    if (isActive) {
      itemColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF244A78);
    } else if (_isHovered) {
      itemColor = isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78);
    } else {
      itemColor = isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A);
    }

    Color bgColor;
    if (isActive) {
      bgColor = isDark
          ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
          : const Color(0xFF244A78).withValues(alpha: 0.1);
    } else if (_isHovered) {
      bgColor = isDark
          ? const Color(0xFF91ADCD).withValues(alpha: 0.1)
          : const Color(0xFFE4DDD0).withValues(alpha: 0.4);
    } else {
      bgColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: isActive
                      ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF244A78))
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: itemColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: itemColor,
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
}

// ==========================================
// WORKSPACE METRIC DATA & CARD
// ==========================================
class _WorkspaceMetricData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  _WorkspaceMetricData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });
}

class _WorkspaceMetricCard extends StatelessWidget {
  final _WorkspaceMetricData data;
  final bool isDark;

  const _WorkspaceMetricCard({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final item = data;

    return SizedBox(
      height: 114,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.accentColor, size: 16),
              ),
              Text(
                item.value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

// ==========================================
// RECENT DOCUMENT MODEL
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
  final String analysisStatus;

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
    this.analysisStatus = 'completed',
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
    final analysisStatus = (json['analysisStatus'] as String?) ?? 'completed';

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
      analysisStatus: analysisStatus,
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

// ==========================================
// CUSTOM ILLUSTRATION PAINTER
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

    // Building Outline
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

    final b3Path = Path()
      ..moveTo(62, 80)
      ..lineTo(62, 42)
      ..lineTo(76, 42)
      ..lineTo(76, 80);
    canvas.drawPath(b3Path, fillPaint);
    canvas.drawPath(b3Path, strokePaint);

    // Scale of Justice
    canvas.drawLine(const Offset(108, 22), const Offset(108, 72), strokePaint);
    canvas.drawLine(const Offset(98, 72), const Offset(118, 72), strokePaint);
    canvas.drawCircle(const Offset(108, 20), 2.5, goldStroke);
    canvas.drawLine(const Offset(90, 28), const Offset(126, 28), goldStroke);

    // Verified Document
    final docPath = Path()
      ..moveTo(146, 76)
      ..lineTo(146, 18)
      ..lineTo(170, 18)
      ..lineTo(182, 30)
      ..lineTo(182, 76)
      ..close();
    canvas.drawPath(docPath, fillPaint);
    canvas.drawPath(docPath, strokePaint);

    canvas.drawCircle(const Offset(172, 64), 5.5, goldStroke);
  }

  @override
  bool shouldRepaint(covariant _LegalPropertyIllustrationPainter oldDelegate) {
    return oldDelegate.accentBlue != accentBlue ||
        oldDelegate.accentGold != accentGold ||
        oldDelegate.isDark != isDark;
  }
}
