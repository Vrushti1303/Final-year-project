import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'scan_screen.dart';
import 'checklist_screen.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';
import 'checklists_list_screen.dart';

const _bgColor = Color(0xFF171218);
const _surfaceColor = Color(0xFF211A24);
const _primaryColor = Color(0xFF564C63);
const _secondaryColor = Color(0xFF7D84A6);
const _textPrimary = Color(0xFFF5F5F5);
const _textSecondary = Color(0xFFB8B8B8);
const _errorColor = Color(0xFFD76C6C);

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
      duration: const Duration(milliseconds: 300),
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
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Text('Logout', style: TextStyle(color: _textPrimary)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout', style: TextStyle(color: _errorColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic user, BoxConstraints constraints) {
    final isMobile = constraints.maxWidth < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Legal Document Scanner',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: _textSecondary),
                onPressed: _handleLogout,
                splashRadius: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user != null)
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryColor.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Icon(Icons.person, color: _secondaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.displayIdentifier,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: user != null
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryColor.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.person, color: _secondaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.displayIdentifier,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Legal Document Scanner',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.logout, color: _textSecondary),
              onPressed: _handleLogout,
              splashRadius: 24,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(user, constraints),
                            
                            const SizedBox(height: 48),
                            
                            const Text(
                              'Navigate Property Laws\nwith Confidence',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Securely analyze legal documents with AI-powered insights.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            
                            const SizedBox(height: 48),
                            
                            _FeatureCard(
                              title: 'Scan Document',
                              subtitle: 'Extract text & analyze for risks',
                              icon: Icons.document_scanner_rounded,
                              iconColor: const Color(0xFF6366F1), // Soft Indigo
                              onTap: () => _navigateTo(const ScanScreen()),
                              index: 0,
                              parentAnimation: _animationController,
                            ),
                            _FeatureCard(
                              title: 'Transaction Checklists',
                              subtitle: 'Ensure safe real estate transactions',
                              icon: Icons.checklist_rounded,
                              iconColor: const Color(0xFF10B981), // Soft Emerald
                              onTap: () => _navigateTo(const ChecklistsListScreen()),
                              index: 1,
                              parentAnimation: _animationController,
                            ),
                            _FeatureCard(
                              title: 'Legal AI Chat',
                              subtitle: 'Ask queries & draft agreements',
                              icon: Icons.chat_bubble_outline_rounded,
                              iconColor: const Color(0xFFF59E0B), // Soft Amber
                              onTap: () => _navigateTo(const ChatScreen()),
                              index: 2,
                              parentAnimation: _animationController,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final int index;
  final Animation<double> parentAnimation;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.index,
    required this.parentAnimation,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final double start = (widget.index * 0.15).clamp(0.0, 1.0);
    final double end = (start + 0.5).clamp(0.0, 1.0);
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: widget.parentAnimation,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.parentAnimation,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.parentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
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
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered 
                    ? widget.iconColor.withValues(alpha: 0.5) 
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 10 : 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _isHovered ? widget.iconColor : _textSecondary,
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
