import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/theme_toggle_button.dart';
import '../services/api_service.dart';
import 'scan_screen.dart';
import 'chat_screen.dart';
import 'checklists_list_screen.dart';
import 'analysis_screen.dart';
import 'stamp_duty_calculator_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<_RecentDocItem> _recentDocs = [];
  List<dynamic> _checklists = [];
  List<dynamic> _legalNews = [];
  bool _isLoadingDocs = false;
  bool _isLoadingNews = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    _searchController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to sign out of your LawBuddy session?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 42),
              ),
              onPressed: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
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
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String greetingName = (user?.fullName != null && user!.fullName.trim().isNotEmpty)
        ? user.fullName.trim().split(' ').first
        : 'Vrushti';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0F172A),
                    Color(0xFF101827),
                    Color(0xFF0B1120),
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                    Color(0xFFEEF2F6),
                  ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTopNav(context, isDark, colorScheme, greetingName),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1140),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 1. Compact Welcome Banner
                                  _buildHeroSection(context, colorScheme, isDark, greetingName),
                                  const SizedBox(height: 24),

                                  // 2. Quick Actions Section
                                  _buildQuickActionsSection(context, colorScheme, isDark),
                                  const SizedBox(height: 32),

                                  // 3. Main Content Grid (Recent Documents + Latest Legal Updates)
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth > 860) {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: _buildRecentDocumentsSection(context, colorScheme, isDark),
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(
                                              flex: 2,
                                              child: _buildLegalNewsSection(context, colorScheme, isDark),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            _buildRecentDocumentsSection(context, colorScheme, isDark),
                                            const SizedBox(height: 28),
                                            _buildLegalNewsSection(context, colorScheme, isDark),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // 4. Prominent RERA Alert Banner
                                  _buildReraAlertCard(context, colorScheme, isDark),
                                  const SizedBox(height: 80), // Extra space for floating AI button
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

            // Floating AI Assistant Button (Bottom Right)
            Positioned(
              right: 24,
              bottom: 24,
              child: _buildFloatingAiButton(context, colorScheme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP NAVIGATION
  // ==========================================
  Widget _buildTopNav(BuildContext context, bool isDark, ColorScheme colorScheme, String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              final isNarrow = constraints.maxWidth < 650;
              return Row(
                children: [
                  // App Brand / Logo
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(Icons.gavel_rounded, color: colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'LawBuddy',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (!isMobile) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'LEGALTECH AI',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: isMobile ? 8 : 20),

                  // Center Search Bar
                  if (!isNarrow)
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E1),
                                width: 1.0,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search documents, agreements, laws...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),

                  // Right Nav Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ThemeToggleButton(),
                      const SizedBox(width: 8),

                      // User Profile Avatar with Hover Effect
                      _InteractiveProfileAvatar(
                        userName: userName,
                        onTap: _handleLogout,
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. COMPACT WELCOME BANNER
  // ==========================================
  Widget _buildHeroSection(BuildContext context, ColorScheme colorScheme, bool isDark, String userName) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIllustration = constraints.maxWidth > 540;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_getGreeting()}, $userName 👋',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: constraints.maxWidth < 420 ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (showIllustration) ...[
                const SizedBox(width: 20),
                SizedBox(
                  width: 236,
                  height: 80,
                  child: CustomPaint(
                    painter: _LegalPropertyIllustrationPainter(
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 2. QUICK ACTIONS SECTION
  // ==========================================
  Widget _buildQuickActionsSection(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a tool to manage your property legal workflow',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth > 800;

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
                ? '0 Active Checklists'
                : '$checklistCount Active ${checklistCount == 1 ? 'Checklist' : 'Checklists'}';

            final String checklistDesc = totalTasks == 0
                ? (checklistCount == 0 ? '0 tasks • Tap to generate property guides' : '0 tasks completed • Tap to view guides')
                : '$completedTasks of $totalTasks tasks completed across $checklistCount ${checklistCount == 1 ? 'guide' : 'guides'}';

            final cards = [
              _QuickActionItem(
                title: 'Scan Agreement',
                description: 'Analyze documents for legal risk',
                ctaText: 'Explore →',
                icon: Icons.document_scanner_rounded,
                accentColor: const Color(0xFF3B82F6), // Royal Blue
                onTap: () => _navigateTo(const ScanScreen()),
              ),
              _QuickActionItem(
                title: 'Legal Chatbot',
                description: 'Ask property & RERA questions',
                ctaText: 'Explore →',
                icon: Icons.forum_outlined,
                accentColor: const Color(0xFFF59E0B), // Amber / Gold
                onTap: () => _navigateTo(const ChatScreen()),
              ),
              _QuickActionItem(
                title: 'Property Checklist',
                description: checklistDesc,
                ctaText: 'Explore →',
                icon: Icons.checklist_rounded,
                accentColor: const Color(0xFF10B981), // Emerald / Teal
                badgeText: checklistBadge,
                showProgress: true,
                progress: checklistProgress,
                onTap: () => _navigateTo(const ChecklistsListScreen()),
              ),
              _QuickActionItem(
                title: 'Stamp Duty Calculator',
                description: 'Calculate stamp duty & registration charges',
                ctaText: 'Explore →',
                icon: Icons.calculate_rounded,
                accentColor: const Color(0xFF8B5CF6), // Purple / Violet
                badgeText: 'New',
                onTap: () => _navigateTo(const StampDutyCalculatorScreen()),
              ),
            ];

            if (isMultiCol) {
              // 2x2 Grid Layout for Desktop & Tablet
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _QuickActionCard(item: cards[0], isDark: isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _QuickActionCard(item: cards[1], isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _QuickActionCard(item: cards[2], isDark: isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _QuickActionCard(item: cards[3], isDark: isDark)),
                    ],
                  ),
                ],
              );
            } else {
              // Single column for mobile screens
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
  // 4. PROMINENT RERA ALERT CARD
  // ==========================================
  Widget _buildReraAlertCard(BuildContext context, ColorScheme colorScheme, bool isDark) {
    // Find live RERA regulatory advisory if available in live feed
    final reraAlert = _legalNews.firstWhere(
      (n) => (n['isWarning'] == true || (n['title'] ?? '').toString().toLowerCase().contains('rera')),
      orElse: () => null,
    );

    final String alertTitle = reraAlert != null
        ? (reraAlert['title'] ?? 'New RERA Guidelines on Builder Escrow & Delivery Norms')
        : 'New RERA Guidelines on Builder Escrow & Delivery Norms';

    final String alertSource = reraAlert != null
        ? (reraAlert['source'] ?? 'RERA Authority Update')
        : 'State RERA Circular';

    final String alertDate = reraAlert != null
        ? 'Latest: ${_formatRelativeTime(reraAlert['pubDate'])}'
        : 'Effective: 1 August 2026';

    final String alertDesc = reraAlert != null
        ? 'Regulatory update via $alertSource. Mandatory adherence required for real estate transactions, promoter disclosures, and escrow accounting.'
        : 'Mandatory 70% escrow realization norms and strict penal interest for handover delays over 90 days. Ensure verification before agreement execution.';

    final String alertLink = reraAlert != null ? (reraAlert['link'] ?? '') : '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: isDark ? 0.35 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: colorScheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            'RERA ALERT',
                            style: TextStyle(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          alertDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alertTitle,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alertDesc,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _handleReraDetails(context, alertLink, alertTitle, alertDesc, colorScheme),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: colorScheme.tertiary, size: 14),
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
                  color: colorScheme.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary, size: 26),
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
                            color: colorScheme.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 12, color: colorScheme.tertiary),
                              const SizedBox(width: 4),
                              Text(
                                'RERA ALERT',
                                style: TextStyle(
                                  color: colorScheme.tertiary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            alertDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alertTitle,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alertDesc,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _handleReraDetails(context, alertLink, alertTitle, alertDesc, colorScheme),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: colorScheme.tertiary, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleReraDetails(
    BuildContext context,
    String alertLink,
    String alertTitle,
    String alertDesc,
    ColorScheme colorScheme,
  ) async {
    if (alertLink.isNotEmpty) {
      final Uri url = Uri.parse(alertLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outline),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.tertiary),
                const SizedBox(width: 10),
                const Text('RERA Advisory Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            content: Text(
              '$alertTitle\n\n$alertDesc\n\nUnder Section 18 of the RERA Act, promoter default in handover or escrow accounting mandates strict statutory interest compensation at SBI MCLR + 2%.',
              style: const TextStyle(height: 1.4, fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Understood'),
              ),
            ],
          );
        },
      );
    }
  }

  // ==========================================
  // 5. RECENT DOCUMENTS SECTION
  // ==========================================
  Widget _buildRecentDocumentsSection(BuildContext context, ColorScheme colorScheme, bool isDark) {
    // Filter documents if search query is active
    final filteredDocs = _searchQuery.isEmpty
        ? _recentDocs
        : _recentDocs.where((d) => d.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Recent Documents',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _navigateTo(const ScanScreen()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All (${_recentDocs.length})',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingDocs && _recentDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (filteredDocs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: 32,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No matching documents found'
                          : 'No agreements scanned yet',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Try searching with another keyword'
                          : 'Upload or scan your property sale deed, lease, or builder agreement for AI risk assessment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => _navigateTo(const ScanScreen()),
                        icon: const Icon(Icons.document_scanner_rounded, size: 16),
                        label: const Text('Scan or Upload Agreement'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.take(3).length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                return _HoverDocumentRow(
                  doc: doc,
                  isDark: isDark,
                  onTap: () {
                    if (doc.analysis.isNotEmpty && doc.originalText.isNotEmpty) {
                      _navigateTo(
                        AnalysisScreen(
                          originalText: doc.originalText,
                          analysis: doc.analysis,
                          documentTitle: doc.title,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${doc.title}...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 14),

            // Quick Upload / Scan Action to balance card heights with news section
            InkWell(
              onTap: () => _navigateTo(const ScanScreen()),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.add_circle_outline_rounded, size: 16, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Scan or Upload New Document',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Instant AI risk assessment & clause breakdown',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 6. LATEST LEGAL UPDATES SECTION
  // ==========================================
  Widget _buildLegalNewsSection(BuildContext context, ColorScheme colorScheme, bool isDark) {
    // Filter news if search query is active
    final filteredNews = _searchQuery.isEmpty
        ? _legalNews
        : _legalNews.where((n) {
            final title = (n['title'] ?? '').toString().toLowerCase();
            final source = (n['source'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery.toLowerCase()) || source.contains(_searchQuery.toLowerCase());
          }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.feed_outlined, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Latest Legal Updates',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
              padding: EdgeInsets.all(28.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (filteredNews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'No updates matching "$_searchQuery"'
                      : 'No legal updates available at this moment',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredNews.take(3).length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = filteredNews[index];
                final title = (item['title'] ?? 'Legal Notice').toString();
                final source = (item['source'] ?? 'Legal News').toString();
                final pubDate = item['pubDate'];
                final timeStr = _formatRelativeTime(pubDate);
                final isNew = index == 0 || (item['isWarning'] == true);
                final link = (item['link'] ?? '').toString();

                return _HoverNewsRow(
                  title: title,
                  source: source,
                  time: timeStr,
                  isNew: isNew,
                  link: link,
                  isDark: isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. FLOATING AI ASSISTANT BUTTON
  // ==========================================
  Widget _buildFloatingAiButton(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return _FloatingLegalAiButton(
      onTap: () => _navigateTo(const ChatScreen()),
      colorScheme: colorScheme,
      isDark: isDark,
    );
  }
}

// ==========================================
// CUSTOM HELPER WIDGETS & HOVER COMPONENTS
// ==========================================

class _LegalPropertyIllustrationPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _LegalPropertyIllustrationPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.32 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final subtlePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.18 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.05 : 0.03)
      ..style = PaintingStyle.fill;

    // 1. Property / Building Outline (Left portion, x: 10 to 86)
    final b1Rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 28, 24, 48),
      const Radius.circular(2),
    );
    canvas.drawRRect(b1Rect, fillPaint);
    canvas.drawRRect(b1Rect, strokePaint);
    for (double y = 36; y <= 66; y += 10) {
      canvas.drawLine(Offset(18, y), Offset(22, y), subtlePaint);
      canvas.drawLine(Offset(26, y), Offset(30, y), subtlePaint);
    }

    final b2Path = Path()
      ..moveTo(36, 76)
      ..lineTo(36, 22)
      ..lineTo(50, 10)
      ..lineTo(64, 22)
      ..lineTo(64, 76);
    canvas.drawPath(b2Path, fillPaint);
    canvas.drawPath(b2Path, strokePaint);
    canvas.drawLine(const Offset(50, 10), const Offset(50, 76), subtlePaint);

    final b3Path = Path()
      ..moveTo(64, 76)
      ..lineTo(64, 40)
      ..lineTo(76, 40)
      ..lineTo(76, 48)
      ..lineTo(86, 48)
      ..lineTo(86, 76);
    canvas.drawPath(b3Path, fillPaint);
    canvas.drawPath(b3Path, strokePaint);

    canvas.drawLine(const Offset(8, 76), const Offset(90, 76), subtlePaint);

    // 2. Scale of Justice (Center-left portion, x: 88 to 134)
    canvas.drawLine(const Offset(110, 20), const Offset(110, 68), strokePaint);
    canvas.drawLine(const Offset(100, 68), const Offset(120, 68), strokePaint);
    canvas.drawCircle(const Offset(110, 18), 2.5, strokePaint);
    canvas.drawLine(const Offset(92, 26), const Offset(128, 26), strokePaint);

    final leftStrings = Path()
      ..moveTo(92, 26)
      ..lineTo(85, 42)
      ..moveTo(92, 26)
      ..lineTo(99, 42);
    canvas.drawPath(leftStrings, subtlePaint);
    final leftPan = Path()
      ..moveTo(83, 42)
      ..quadraticBezierTo(92, 47, 101, 42);
    canvas.drawPath(leftPan, strokePaint);

    final rightStrings = Path()
      ..moveTo(128, 26)
      ..lineTo(121, 42)
      ..moveTo(128, 26)
      ..lineTo(135, 42);
    canvas.drawPath(rightStrings, subtlePaint);
    final rightPan = Path()
      ..moveTo(119, 42)
      ..quadraticBezierTo(128, 47, 137, 42);
    canvas.drawPath(rightPan, strokePaint);

    // 3. Legal Document (Center-right portion, x: 140 to 184)
    final docPath = Path()
      ..moveTo(142, 72)
      ..lineTo(142, 16)
      ..lineTo(168, 16)
      ..lineTo(180, 28)
      ..lineTo(180, 72)
      ..close();
    canvas.drawPath(docPath, fillPaint);
    canvas.drawPath(docPath, strokePaint);

    final foldPath = Path()
      ..moveTo(168, 16)
      ..lineTo(168, 28)
      ..lineTo(180, 28);
    canvas.drawPath(foldPath, strokePaint);

    canvas.drawLine(const Offset(148, 28), const Offset(164, 28), subtlePaint);
    canvas.drawLine(const Offset(148, 36), const Offset(174, 36), subtlePaint);
    canvas.drawLine(const Offset(148, 44), const Offset(174, 44), subtlePaint);
    canvas.drawLine(const Offset(148, 52), const Offset(168, 52), subtlePaint);

    canvas.drawCircle(const Offset(170, 62), 4.5, strokePaint);
    canvas.drawCircle(const Offset(170, 62), 2.0, subtlePaint);

    // 4. Magnifying Glass (Right portion, x: 182 to 230)
    const lensCenter = Offset(198, 40);
    const lensRadius = 14.0;
    canvas.drawCircle(lensCenter, lensRadius, fillPaint);
    canvas.drawCircle(lensCenter, lensRadius, strokePaint);

    final glintPath = Path()
      ..addArc(
        Rect.fromCircle(center: lensCenter, radius: 10),
        -2.4,
        1.1,
      );
    canvas.drawPath(glintPath, subtlePaint);

    final handlePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.35 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(208, 50), const Offset(224, 66), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _LegalPropertyIllustrationPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}

class _QuickActionItem {
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
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(top: _isHovered ? 0 : 4, bottom: _isHovered ? 4 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isHovered ? const Color(0xFF263549) : const Color(0xFF1E293B))
                : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.item.accentColor.withValues(alpha: 0.5)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? (widget.isDark ? 0.28 : 0.06) : (widget.isDark ? 0.18 : 0.02)),
                blurRadius: _isHovered ? 10 : 4,
                offset: Offset(0, _isHovered ? 3 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon on left, optional Badge on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.item.accentColor.withValues(alpha: _isHovered ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: widget.item.accentColor.withValues(alpha: _isHovered ? 0.35 : 0.2),
                        ),
                      ),
                      child: Icon(widget.item.icon, color: widget.item.accentColor, size: 19),
                    ),
                  ),
                  if (widget.item.badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.item.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.item.accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.item.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.item.badgeText!,
                            style: TextStyle(
                              color: widget.item.accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.item.title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),

              // Description with consistent fixed height for perfect CTA baseline alignment
              SizedBox(
                height: 32,
                child: Text(
                  widget.item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),

              // Optional Progress Bar (consistent section for all cards)
              if (widget.item.showProgress) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 3,
                    width: double.infinity,
                    color: widget.item.accentColor.withValues(alpha: 0.15),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.item.progress > 0 ? widget.item.progress : 0.0,
                      child: Container(
                        color: widget.item.accentColor,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 9),
              ],

              const SizedBox(height: 10),

              // CTA link
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      color: _isHovered ? widget.item.accentColor : widget.item.accentColor.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSlide(
                    offset: _isHovered ? const Offset(0.25, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _isHovered ? widget.item.accentColor : widget.item.accentColor.withValues(alpha: 0.9),
                      size: 13,
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
}

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
  });

  factory _RecentDocItem.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?) ?? 'Legal Document';
    final riskLevel = (json['riskLevel'] as String?) ?? 'Low Risk';
    final docSize = (json['docSize'] as String?) ?? '1.2 MB';
    final createdAt = json['createdAt'];
    final dateText = 'Scanned ${_formatRelativeTime(createdAt)}';
    final originalText = (json['originalText'] as String?) ?? '';
    final analysis = (json['analysis'] as List<dynamic>?) ?? [];

    Color riskColor = const Color(0xFF10B981);
    IconData riskIcon = Icons.check_circle_rounded;
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
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark ? const Color(0xFF263549) : const Color(0xFFF1F5F9))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_outlined, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doc.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.doc.dateText} • ${widget.doc.docSize}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.doc.riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.doc.riskColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.doc.riskIcon, size: 13, color: widget.doc.riskColor),
                    const SizedBox(width: 5),
                    Text(
                      widget.doc.riskLabel,
                      style: TextStyle(
                        color: widget.doc.riskColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              AnimatedSlide(
                offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _isHovered ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;

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
                ? (widget.isDark ? const Color(0xFF263549) : const Color(0xFFF1F5F9))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.article_outlined, color: colorScheme.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.source,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                color: colorScheme.tertiary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.time,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSlide(
                offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: _isHovered ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveProfileAvatar extends StatefulWidget {
  final String userName;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _InteractiveProfileAvatar({
    required this.userName,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  State<_InteractiveProfileAvatar> createState() => _InteractiveProfileAvatarState();
}

class _InteractiveProfileAvatarState extends State<_InteractiveProfileAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final String initial = widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: '${widget.userName} (Click to Sign Out)',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered ? widget.colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: widget.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: TextStyle(
                  color: widget.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingLegalAiButton extends StatefulWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _FloatingLegalAiButton({
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  State<_FloatingLegalAiButton> createState() => _FloatingLegalAiButtonState();
}

class _FloatingLegalAiButtonState extends State<_FloatingLegalAiButton> {
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB), // Grounded Professional Blue
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.25 : 0.15),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 3 : 2),
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
                  _isHovered ? 'Need Legal Help? Ask LawBuddy' : 'Ask Legal AI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
