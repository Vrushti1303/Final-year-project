import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/theme_toggle_button.dart';
import '../services/api_service.dart';
import 'scan_screen.dart';
import 'chat_screen.dart';
import 'checklists_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          title: Text('Logout', style: TextStyle(color: colorScheme.onSurface)),
          content: Text('Are you sure you want to log out?', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
              child: Text('Logout', style: TextStyle(color: colorScheme.error)),
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
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: GestureDetector(
              onTap: _handleLogout,
              child: CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded, color: colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Greeting Section
                        Text(
                          '${_getGreeting()},',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              return Row(
                                children: [
                                  Expanded(child: _buildQuickActionCard(context, 'Scan Agreement', 'Analyze documents', Icons.document_scanner_rounded, colorScheme.primary, () => _navigateTo(const ScanScreen()))),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildQuickActionCard(context, 'Legal Chatbot', 'Ask legal questions', Icons.chat_bubble_rounded, colorScheme.tertiary, () => _navigateTo(const ChatScreen()))),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildQuickActionCard(context, 'Property Checklist', 'Transaction guides', Icons.checklist_rounded, colorScheme.secondary, () => _navigateTo(const ChecklistsListScreen()))),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildQuickActionCard(context, 'Scan Agreement', 'Analyze documents for risk', Icons.document_scanner_rounded, colorScheme.primary, () => _navigateTo(const ScanScreen())),
                                  const SizedBox(height: 16),
                                  _buildQuickActionCard(context, 'Legal Chatbot', 'Ask legal questions', Icons.chat_bubble_rounded, colorScheme.tertiary, () => _navigateTo(const ChatScreen())),
                                  const SizedBox(height: 16),
                                  _buildQuickActionCard(context, 'Property Checklist', 'Transaction guides', Icons.checklist_rounded, colorScheme.secondary, () => _navigateTo(const ChecklistsListScreen())),
                                ],
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 48),

                        // Bottom Layout (Recent Docs & Alerts)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: _buildRecentDocuments(context)),
                                  const SizedBox(width: 32),
                                  Expanded(flex: 1, child: _buildLiveNewsSection(context)),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildRecentDocuments(context),
                                  const SizedBox(height: 32),
                                  _buildLiveNewsSection(context),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    return _HoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocuments(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Documents',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _HoverCard(
          onTap: () {},
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => Divider(color: colorScheme.outline, height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_rounded, color: colorScheme.primary),
                ),
                title: Text('Sale Agreement - Unit ${101 + index}', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
                subtitle: Text('Scanned 2 days ago', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveNewsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<dynamic>>(
      future: ApiService.getLegalNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final articles = snapshot.data ?? [];
        if (articles.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayArticles = articles.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Legal & RERA News',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: colorScheme.primary, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HoverCard(
              onTap: () {},
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayArticles.length,
                separatorBuilder: (context, index) => Divider(color: colorScheme.outline, height: 1),
                itemBuilder: (context, index) {
                  final item = displayArticles[index];
                  final String itemTitle = item['title'] ?? 'Legal Update';
                  final String itemSource = item['source'] ?? 'Legal News';
                  final String itemLink = item['link'] ?? '';
                  final bool isWarning = item['isWarning'] ?? (index % 2 == 1);
                  final IconData icon = isWarning ? Icons.warning_rounded : Icons.gavel_rounded;
                  final Color iconColor = isWarning ? colorScheme.tertiary : colorScheme.primary;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    onTap: () async {
                      if (itemLink.isNotEmpty) {
                        final Uri url = Uri.parse(itemLink);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor),
                    ),
                    title: Text(
                      itemTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '$itemSource • Tap to read',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverCard({required this.child, this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.diagonal3Values(
            _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
            _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
            1.0,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outline,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: Offset(0, _isHovered ? 6 : 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

