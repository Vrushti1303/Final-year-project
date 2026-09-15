import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';
import '../widgets/user_profile_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  const ChatScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  AnimationController? _ambientController;
  Animation<double>? _pulseAnimation;
  AnimationController? _floatingController;

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String? _currentSessionId;
  List<dynamic> _sessions = [];
  bool _isLoadingSessions = false;
  String _searchQuery = '';
  Offset _mousePos = const Offset(600, 300);

  void _initControllers() {
    _ambientController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    _pulseAnimation ??= Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ambientController!, curve: Curves.easeInOutSine),
    );

    _floatingController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void initState() {
    super.initState();
    _initControllers();

    _loadSessions();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(textOverride: widget.initialPrompt);
      });
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await ApiService.fetchChatSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadSessionDetails(String sessionId) async {
    try {
      final data = await ApiService.fetchChatSession(sessionId);
      if (mounted && data['messages'] != null) {
        setState(() {
          _currentSessionId = sessionId;
          _messages.clear();
          for (final msg in (data['messages'] as List)) {
            _messages.add({
              'role': msg['role'],
              'text': msg['text'],
              'time': msg['time'],
              'suggestions': msg['suggestions'],
              'isNew': false,
            });
          }
        });
        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
        _scrollToBottom(force: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversation: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final loc = ref.read(localeProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 8),
              Text(
                loc.translate('chat.deleteTitle'),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            loc.translate('chat.deleteContent'),
            style: GoogleFonts.inter(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.translate('common.cancel'), style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.translate('common.delete'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await ApiService.deleteChatSession(sessionId);
    if (success && mounted) {
      setState(() {
        _sessions.removeWhere((s) => s['id'] == sessionId);
        if (_currentSessionId == sessionId) {
          _clearChat();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(loc.translate('chat.deletedToast'), style: GoogleFonts.inter()),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ambientController?.dispose();
    _floatingController?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearChat() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _isTyping = false;
      _controller.clear();
    });
  }

  Future<void> _sendMessage({String? textOverride}) async {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'time': timeStr});
      _isTyping = true;
      if (textOverride == null) {
        _controller.clear();
      }
    });

    _scrollToBottom(force: true);

    try {
      final List<Map<String, dynamic>> validHistory = [];
      for (final m in _messages) {
        if (m['role'] == 'error') continue;
        
        if (validHistory.isEmpty) {
          if (m['role'] == 'user') {
            validHistory.add({'role': m['role'], 'text': m['text']});
          }
        } else {
          if (validHistory.last['role'] != m['role']) {
            validHistory.add({'role': m['role'], 'text': m['text']});
          } else if (m['role'] == 'user') {
            validHistory[validHistory.length - 1] = {'role': m['role'], 'text': m['text']};
          }
        }
      }

      final response = await ApiService.chat(validHistory, sessionId: _currentSessionId);
      
      final replyNow = DateTime.now();
      final replyTimeStr = '${replyNow.hour > 12 ? replyNow.hour - 12 : (replyNow.hour == 0 ? 12 : replyNow.hour)}:${replyNow.minute.toString().padLeft(2, '0')} ${replyNow.hour >= 12 ? 'PM' : 'AM'}';

      if (response['sessionId'] != null) {
        _currentSessionId = response['sessionId'];
      }

      setState(() {
        _messages.add({
          'role': 'ai',
          'text': response['reply'] ?? 'Empty response',
          'suggestions': response['suggestions'],
          'time': replyTimeStr,
          'isNew': true,
        });
      });
      _loadSessions();
    } on RateLimitException {
      final errNow = DateTime.now();
      final errTimeStr = '${errNow.hour > 12 ? errNow.hour - 12 : (errNow.hour == 0 ? 12 : errNow.hour)}:${errNow.minute.toString().padLeft(2, '0')} ${errNow.hour >= 12 ? 'PM' : 'AM'}';
      final loc = ref.read(localeProvider.notifier);
      setState(() {
        _messages.add({
          'role': 'error', 
          'text': loc.translate('chat.rateLimitMessage'),
          'time': errTimeStr,
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('chat.rateLimitToast')),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      final errNow = DateTime.now();
      final errTimeStr = '${errNow.hour > 12 ? errNow.hour - 12 : (errNow.hour == 0 ? 12 : errNow.hour)}:${errNow.minute.toString().padLeft(2, '0')} ${errNow.hour >= 12 ? 'PM' : 'AM'}';
      setState(() {
        _messages.add({'role': 'error', 'text': 'Error: $e', 'time': errTimeStr});
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        final distanceFromBottom = pos.maxScrollExtent - pos.pixels;
        if (force || distanceFromBottom < 220) {
          _scrollController.animateTo(
            pos.maxScrollExtent,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;
    final isMobile = size.width < 650;

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
      backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
      endDrawer: _buildHistoryDrawer(context, isDark, loc),
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
              // AMBIENT LIGHTING (MATCHING DASHBOARD & SCAN)
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
                                  const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.12 : 0.07),
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
                                    const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.04 : 0.02),
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
              // MAIN COLUMN CONTENT
              // ==========================================
              SafeArea(
                child: Column(
                  children: [
                    // TOP BAR (TRUE CENTER-ALIGNED)
                    _buildTopBar(context, isDark, loc),

                    // BODY STREAM / EMPTY STATE
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Column(
                            children: [
                              Expanded(
                                child: _messages.isEmpty
                                    ? _buildEmptyState(isDark, loc, isMobile, isDesktop)
                                    : ListView.builder(
                                        controller: _scrollController,
                                        physics: const BouncingScrollPhysics(),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 16 : 32,
                                          vertical: 16,
                                        ),
                                        itemCount: _messages.length,
                                        itemBuilder: (context, index) {
                                          final msg = _messages[index];
                                          return _AnimatedMessageBubble(
                                            key: ValueKey('${msg['role']}_${msg['time']}_$index'),
                                            message: msg,
                                            onSuggestionTap: (s) => _sendMessage(textOverride: s),
                                            onScrollRequest: _scrollToBottom,
                                          );
                                        },
                                      ),
                              ),
                              if (_isTyping)
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                                  child: const _TypingIndicator(),
                                ),
                              _ChatInput(
                                controller: _controller,
                                focusNode: _inputFocusNode,
                                isLoading: _isTyping,
                                onSend: () => _sendMessage(),
                                isMobile: isMobile,
                              ),
                            ],
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
  // TOP APP BAR (CENTERED BADGE + ACTIONS)
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

          // Center: True dead-center alignment
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.35 : 0.25),
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
                      color: Color(0xFFC5A85E),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFC5A85E),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '24/7 LEGAL AI ASSISTANT • RERA SPECIALIST',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC5A85E),
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Action buttons
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoverGlassIconButton(
                  icon: Icons.history_rounded,
                  tooltip: loc.translate('chat.chatHistory'),
                  isDark: isDark,
                  onTap: () {
                    _loadSessions();
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
                if (_messages.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _HoverGlassIconButton(
                    icon: Icons.add_comment_outlined,
                    tooltip: loc.translate('chat.newChat'),
                    isDark: isDark,
                    onTap: _clearChat,
                  ),
                ],
                const SizedBox(width: 8),
                const UserProfileButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE (HERO + PROMPTS + BADGES)
  // ==========================================
  Widget _buildEmptyState(bool isDark, LocaleNotifier loc, bool isMobile, bool isDesktop) {
    final promptCards = [
      {
        'category': loc.translate('chat.card1Cat'),
        'icon': Icons.description_outlined,
        'color': const Color(0xFF38BDF8),
        'title': loc.translate('chat.card1Title'),
        'desc': loc.translate('chat.card1Desc'),
        'prompt': 'Can you review the key clauses in a residential property agreement and highlight standard red flags?',
      },
      {
        'category': loc.translate('chat.card2Cat'),
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFC5A85E),
        'title': loc.translate('chat.card2Title'),
        'desc': loc.translate('chat.card2Desc'),
        'prompt': 'What are my legal rights and compensation rules under RERA if a builder delays possession?',
      },
      {
        'category': loc.translate('chat.card3Cat'),
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFFC5A85E),
        'title': loc.translate('chat.card3Title'),
        'desc': loc.translate('chat.card3Desc'),
        'prompt': 'Please draft a standard 11-month residential rental agreement with essential tenant and landlord clauses.',
      },
      {
        'category': loc.translate('chat.card4Cat'),
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF38BDF8),
        'title': loc.translate('chat.card4Title'),
        'desc': loc.translate('chat.card4Desc'),
        'prompt': 'What documents and procedures are mandatory for property registration and stamp duty payment in India?',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Animated Levitation Emblem Badge with Layered Rings
              AnimatedBuilder(
                animation: _floatingController!,
                builder: (context, child) {
                  final floatVal = math.sin(_floatingController!.value * math.pi * 2) * 5.0;
                  return Transform.translate(
                    offset: Offset(0, floatVal),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow Ring
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.08 : 0.05),
                      ),
                    ),

                    // Inner Glassmorphic Emblem Card
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.22 : 0.15),
                            const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.08 : 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.45 : 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.25 : 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.balance_rounded,
                          size: 36,
                          color: Color(0xFFC5A85E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Eyebrow Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                    const SizedBox(width: 7),
                    Text(
                      'AI CONTRACT SCRUTINY • RERA RIGHTS • INSTANT CONSULTATION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFC5A85E) : const Color(0xFF244A78),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Main Headline
              Text(
                loc.translate('chat.heroHeadline'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  loc.translate('chat.heroSubtitle'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Legal Badges Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegalTag(Icons.shield_outlined, loc.translate('chat.tagRera'), const Color(0xFF38BDF8), isDark),
                  _buildLegalTag(Icons.description_outlined, loc.translate('chat.tagTenancy'), const Color(0xFFC5A85E), isDark),
                  _buildLegalTag(Icons.balance_rounded, loc.translate('chat.tagTransfer'), const Color(0xFF38BDF8), isDark),
                ],
              ),

              const SizedBox(height: 28),

              // 2x2 High-Impact Interactive Prompt Cards Grid
              if (isMobile)
                Column(
                  children: promptCards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PromptCard(
                        index: index,
                        category: p['category'] as String,
                        icon: p['icon'] as IconData,
                        accentColor: p['color'] as Color,
                        title: p['title'] as String,
                        description: p['desc'] as String,
                        onTap: () => _sendMessage(textOverride: p['prompt'] as String),
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PromptCard(
                            index: 0,
                            category: promptCards[0]['category'] as String,
                            icon: promptCards[0]['icon'] as IconData,
                            accentColor: promptCards[0]['color'] as Color,
                            title: promptCards[0]['title'] as String,
                            description: promptCards[0]['desc'] as String,
                            onTap: () => _sendMessage(textOverride: promptCards[0]['prompt'] as String),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PromptCard(
                            index: 1,
                            category: promptCards[1]['category'] as String,
                            icon: promptCards[1]['icon'] as IconData,
                            accentColor: promptCards[1]['color'] as Color,
                            title: promptCards[1]['title'] as String,
                            description: promptCards[1]['desc'] as String,
                            onTap: () => _sendMessage(textOverride: promptCards[1]['prompt'] as String),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PromptCard(
                            index: 2,
                            category: promptCards[2]['category'] as String,
                            icon: promptCards[2]['icon'] as IconData,
                            accentColor: promptCards[2]['color'] as Color,
                            title: promptCards[2]['title'] as String,
                            description: promptCards[2]['desc'] as String,
                            onTap: () => _sendMessage(textOverride: promptCards[2]['prompt'] as String),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PromptCard(
                            index: 3,
                            category: promptCards[3]['category'] as String,
                            icon: promptCards[3]['icon'] as IconData,
                            accentColor: promptCards[3]['color'] as Color,
                            title: promptCards[3]['title'] as String,
                            description: promptCards[3]['desc'] as String,
                            onTap: () => _sendMessage(textOverride: promptCards[3]['prompt'] as String),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Quick Topic Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  loc.translate('chat.chip1'),
                  loc.translate('chat.chip2'),
                  loc.translate('chat.chip3'),
                  loc.translate('chat.chip4'),
                ].map((s) => _HoverableChip(
                  label: s,
                  isDark: isDark,
                  onTap: () => _sendMessage(textOverride: 'Explain: $s under Indian property law'),
                )).toList(),
              ),

              const SizedBox(height: 24),

              // Legal Disclaimer Capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        loc.translate('chat.disclaimer'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontSize: 11,
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

  Widget _buildLegalTag(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HISTORY DRAWER
  // ==========================================
  Widget _buildHistoryDrawer(BuildContext context, bool isDark, LocaleNotifier loc) {
    final filteredSessions = _searchQuery.trim().isEmpty
        ? _sessions
        : _sessions.where((s) {
            final title = (s['title'] ?? '').toString().toLowerCase();
            final snippet = (s['lastSnippet'] ?? '').toString().toLowerCase();
            final q = _searchQuery.trim().toLowerCase();
            return title.contains(q) || snippet.contains(q);
          }).toList();

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_edu_rounded, size: 20, color: Color(0xFFC5A85E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('chat.savedConsultations'),
                          style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          loc.translate('chat.sessionsStored', {'count': _sessions.length.toString()}),
                          style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 16, color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78), fontSize: 12),
                        decoration: InputDecoration(
                          hintText: loc.translate('chat.searchConsultations'),
                          hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(Icons.cancel, size: 14, color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A)),
                      ),
                  ],
                ),
              ),
            ),

            // Start New Chat Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pop();
                  _clearChat();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A85E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC5A85E).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Color(0xFFC5A85E), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('chat.startNewConsultation'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFC5A85E),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sessions List
            Expanded(
              child: _isLoadingSessions
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A85E)))
                  : filteredSessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 36,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _searchQuery.isNotEmpty ? loc.translate('chat.noMatchingConversations') : loc.translate('chat.noSavedConversations'),
                                  style: GoogleFonts.inter(
                                    color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          itemCount: filteredSessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final session = filteredSessions[index];
                            final sessionId = session['id']?.toString() ?? '';
                            final isSelected = _currentSessionId == sessionId;
                            final title = session['title'] ?? 'Legal Discussion';
                            final lastSnippet = session['lastSnippet'] ?? '';
                            final count = session['messageCount'] ?? 0;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _loadSessionDetails(sessionId),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFC5A85E).withValues(alpha: 0.16)
                                      : (isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFC5A85E)
                                        : (isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFC5A85E) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            ),
                                          ),
                                          if (lastSnippet.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              lastSnippet,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                                fontSize: 11,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  loc.translate('chat.turnsCount', {'count': count.toString()}),
                                                  style: GoogleFonts.inter(
                                                    color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                                      ),
                                      tooltip: 'Delete session',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _deleteSession(sessionId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PROMPT ACTION CARD WIDGET
// ==========================================
class _PromptCard extends ConsumerStatefulWidget {
  final int index;
  final String category;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isDark;

  const _PromptCard({
    required this.index,
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.onTap,
    required this.isDark,
  });

  @override
  ConsumerState<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends ConsumerState<_PromptCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);
    final itemAccent = widget.accentColor;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          offset: _isHovered ? const Offset(0.0, -0.03) : Offset.zero,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        itemAccent.withValues(alpha: 0.7),
                        itemAccent.withValues(alpha: 0.35),
                        const Color(0xFF16263B).withValues(alpha: 0.6),
                      ]
                    : (isDark
                        ? [
                            itemAccent.withValues(alpha: 0.3),
                            const Color(0xFF334356).withValues(alpha: 0.4),
                            const Color(0xFF16263B).withValues(alpha: 0.2),
                          ]
                        : [
                            const Color(0xFFE4DDD0),
                            itemAccent.withValues(alpha: 0.25),
                            const Color(0xFFE4DDD0),
                          ]),
              ),
              boxShadow: [
                BoxShadow(
                  color: itemAccent.withValues(alpha: _isHovered ? (isDark ? 0.3 : 0.12) : 0.0),
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
            padding: const EdgeInsets.all(1.2), // Gradient border
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? (_isHovered ? const Color(0xFF1E3552).withValues(alpha: 0.96) : const Color(0xFF182A40).withValues(alpha: 0.94))
                    : (_isHovered ? const Color(0xFFFAF6EB).withValues(alpha: 0.98) : const Color(0xFFFDFBF7).withValues(alpha: 0.96)),
                borderRadius: BorderRadius.circular(18.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon Container + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: _isHovered ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: itemAccent.withValues(alpha: _isHovered ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: itemAccent.withValues(alpha: _isHovered ? 0.55 : 0.25),
                                ),
                                boxShadow: [
                                  if (_isHovered)
                                    BoxShadow(
                                      color: itemAccent.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                ],
                              ),
                              child: Icon(widget.icon, color: itemAccent, size: 22),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: itemAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: itemAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              widget.category,
                              style: GoogleFonts.inter(
                                color: itemAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        widget.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Bottom Action Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.translate('chat.askLegalAi'),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: itemAccent,
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedSlide(
                        offset: _isHovered ? const Offset(0.3, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: itemAccent,
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
      ),
    );
  }
}

// ==========================================
// ANIMATED MESSAGE BUBBLE
// ==========================================
class _AnimatedMessageBubble extends ConsumerStatefulWidget {
  final Map<String, dynamic> message;
  final Function(String) onSuggestionTap;
  final VoidCallback? onScrollRequest;

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.onSuggestionTap,
    this.onScrollRequest,
  });

  @override
  ConsumerState<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends ConsumerState<_AnimatedMessageBubble> {
  bool _copied = false;
  String _fullText = '';
  String _displayedText = '';
  bool _isRevealing = false;
  bool _showCursor = true;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  List<String> _tokens = [];
  int _tokenIndex = 0;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _fullText = widget.message['text'] ?? '';
    final isAI = widget.message['role'] == 'ai' ||
        (widget.message['role'] != 'user' && widget.message['role'] != 'error');
    final isNew = widget.message['isNew'] == true;

    if (isAI && isNew && _fullText.isNotEmpty) {
      _startTypingAnimation();
    } else {
      _displayedText = _fullText;
      _isRevealing = false;
    }
  }

  void _startTypingAnimation() {
    final matches = RegExp(r'(\S+\s*)').allMatches(_fullText);
    _tokens = matches.map((m) => m.group(0)!).toList();
    if (_tokens.isEmpty) {
      _tokens = [_fullText];
    }

    _isRevealing = true;
    _tokenIndex = 0;
    _displayedText = '';
    _tickCount = 0;

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 460), (timer) {
      if (mounted) {
        setState(() => _showCursor = !_showCursor);
      }
    });

    _typingTimer = Timer.periodic(const Duration(milliseconds: 26), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_tokenIndex >= _tokens.length) {
        _finishTyping();
        return;
      }

      final int stepSize = (_tokens.length > 350 && _tickCount % 4 == 0) ? 2 : 1;
      final nextIndex = math.min(_tokenIndex + stepSize, _tokens.length);
      _tokenIndex = nextIndex;
      _tickCount++;

      setState(() {
        _displayedText = _tokens.sublist(0, _tokenIndex).join('');
      });

      if (_tickCount % 4 == 0) {
        widget.onScrollRequest?.call();
      }

      if (_tokenIndex >= _tokens.length) {
        _finishTyping();
      }
    });
  }

  void _finishTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
    _cursorTimer?.cancel();
    _cursorTimer = null;
    if (mounted) {
      setState(() {
        _isRevealing = false;
        _displayedText = _fullText;
        widget.message['isNew'] = false;
      });
    } else {
      widget.message['isNew'] = false;
    }
    widget.onScrollRequest?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _isRevealing) {
      _finishTyping();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);

    final loc = ref.read(localeProvider.notifier);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(loc.translate('chat.copiedToClipboard')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message['role'] == 'user';
    final isError = widget.message['role'] == 'error';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userBgColor = isDark ? const Color(0xFF244A78) : const Color(0xFF244A78);
    final aiBgColor = isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE);
    final borderColor = isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0);

    final rawContent = isUser ? (widget.message['text'] ?? '') : _displayedText;
    final contentToRender = (_isRevealing && _showCursor) ? '$rawContent ▌' : rawContent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 6, top: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isError
                      ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                      : (isUser ? userBgColor : aiBgColor),
                  border: Border.all(
                    color: isError
                        ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                        : (isUser ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : borderColor),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : null,
                    bottomLeft: !isUser ? const Radius.circular(4) : null,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.person_rounded, size: 13, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'You',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                                  key: ValueKey<bool>(_copied),
                                  size: 14,
                                  color: _copied ? Colors.white : Colors.white70,
                                ),
                              ),
                              tooltip: 'Copy message',
                              splashRadius: 14,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _copyToClipboard(context, widget.message['text'] ?? ''),
                            ),
                          ],
                        ),
                      ),
                    if (!isUser && !isError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isRevealing ? Icons.auto_awesome : Icons.gavel_rounded,
                                    size: 14,
                                    color: const Color(0xFFC5A85E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Legal AI Advisor',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC5A85E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isRevealing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC5A85E).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 8,
                                          height: 8,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A85E)),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'ANALYZING',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFC5A85E),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'PROPERTY LAW',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isRevealing)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Tooltip(
                                      message: 'Reveal entire answer immediately',
                                      child: InkWell(
                                        onTap: _finishTyping,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC5A85E).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFC5A85E).withValues(alpha: 0.35),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.fast_forward_rounded, size: 12, color: Color(0xFFC5A85E)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Show full answer',
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFFC5A85E),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                                      key: ValueKey<bool>(_copied),
                                      size: 15,
                                      color: _copied ? const Color(0xFF10B981) : (isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A)),
                                    ),
                                  ),
                                  tooltip: 'Copy response',
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _copyToClipboard(context, _fullText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    MarkdownBody(
                      data: contentToRender,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFE8E1D0) : const Color(0xFF1E293B)),
                          fontSize: 14.5,
                          height: 1.65,
                          letterSpacing: -0.1,
                        ),
                        pPadding: const EdgeInsets.only(bottom: 10),
                        h1: GoogleFonts.inter(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          height: 1.4,
                          letterSpacing: -0.4,
                        ),
                        h1Padding: const EdgeInsets.only(top: 14, bottom: 8),
                        h2: GoogleFonts.inter(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
                        h2Padding: const EdgeInsets.only(top: 12, bottom: 6),
                        h3: GoogleFonts.inter(
                          color: isUser ? Colors.white : const Color(0xFFC5A85E),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.35,
                        ),
                        h3Padding: const EdgeInsets.only(top: 10, bottom: 4),
                        strong: GoogleFonts.inter(
                          color: isUser
                              ? Colors.white
                              : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w700,
                        ),
                        em: GoogleFonts.inter(
                          color: isUser ? Colors.white70 : (isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A)),
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: GoogleFonts.inter(
                          color: isUser ? Colors.white70 : const Color(0xFFC5A85E),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        listBulletPadding: const EdgeInsets.only(right: 6),
                        listIndent: 22,
                        blockquote: GoogleFonts.inter(
                          color: isUser ? Colors.white70 : (isDark ? const Color(0xFFE8E1D0) : const Color(0xFF1E293B)),
                          fontSize: 13.5,
                          height: 1.55,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        blockquoteDecoration: BoxDecoration(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.10 : 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isUser ? Colors.white70 : const Color(0xFFC5A85E),
                              width: 3.5,
                            ),
                          ),
                        ),
                        code: GoogleFonts.firaCode(
                          backgroundColor: isUser
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.20 : 0.10),
                          color: isUser
                              ? Colors.white
                              : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        codeblockDecoration: BoxDecoration(
                          color: isUser
                              ? Colors.black.withValues(alpha: 0.2)
                              : (isDark ? const Color(0xFF162B43) : const Color(0xFFF4EFE0)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                          ),
                        ),
                        tableBorder: TableBorder.all(
                          color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tableHead: GoogleFonts.inter(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                        tableBody: GoogleFonts.inter(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFE8E1D0) : const Color(0xFF1E293B)),
                          fontSize: 13,
                        ),
                        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.message['time'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    widget.message['time'],
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                      fontSize: 11,
                    ),
                  ),
                ),
              if (!isUser && !_isRevealing && widget.message['suggestions'] != null && (widget.message['suggestions'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: (widget.message['suggestions'] as List).map((s) => _HoverableChip(
                      label: s.toString(),
                      isDark: isDark,
                      onTap: () => widget.onSuggestionTap(s.toString()),
                    )).toList(),
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
// CHAT DOCKED INPUT BAR
// ==========================================
class _ChatInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final bool isMobile;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.isMobile,
  });

  @override
  ConsumerState<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<_ChatInput> {
  bool _isFocused = false;
  bool _isSendHovered = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dockBg = isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE);
    final dockBorder = _isFocused
        ? const Color(0xFF38BDF8)
        : (isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 32, vertical: 12),
      decoration: BoxDecoration(
        color: dockBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dockBorder,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.25 : 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: _isFocused ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: _isFocused ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.balance_rounded,
              color: _isFocused ? const Color(0xFF38BDF8) : (isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A)),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: GoogleFonts.inter(
                color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF1E293B),
                fontSize: 14,
              ),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: ref.watch(localeProvider.notifier).translate('chat.inputHint'),
                hintStyle: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: false,
              ),
              onSubmitted: (_) {
                if (!widget.isLoading) widget.onSend();
              },
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            onEnter: (_) => setState(() => _isSendHovered = true),
            onExit: (_) => setState(() => _isSendHovered = false),
            child: GestureDetector(
              onTap: widget.isLoading ? null : widget.onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: _isSendHovered ? 0.5 : 0.3),
                      blurRadius: _isSendHovered ? 10 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HOVERABLE TOPIC CHIP
// ==========================================
class _HoverableChip extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverableChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverableChip> createState() => _HoverableChipState();
}

class _HoverableChipState extends State<_HoverableChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.2 : 0.12)
                : (isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFC5A85E)
                  : (isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gavel_rounded, size: 12, color: Color(0xFFC5A85E)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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
// TYPING INDICATOR
// ==========================================
class _TypingIndicator extends ConsumerStatefulWidget {
  const _TypingIndicator();

  @override
  ConsumerState<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends ConsumerState<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final cardBg = isDark ? const Color(0xFF1B2F48) : const Color(0xFFFBF8EE);
    final borderColor = isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome, size: 13, color: Color(0xFFC5A85E)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.translate('chat.typingTitle'),
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final progress = (_controller.value * 3 - index) % 3;
                            final offset = progress >= 0 && progress <= 1 ? -4.0 * (0.5 - (progress - 0.5).abs()) : 0.0;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC5A85E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
                Text(
                  loc.translate('chat.typingSubtitle'),
                  style: GoogleFonts.inter(
                    color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF63748A),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HOVER GLASS BUTTON HELPERS
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
                ? (widget.isDark ? const Color(0xFF223A58) : const Color(0xFFF4EFE0))
                : (widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.8) : const Color(0xFFFBF8EE).withValues(alpha: 0.9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFFC5A85E)).withValues(alpha: _isHovered ? 0.5 : 0.2),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _HoverGlassIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _HoverGlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_HoverGlassIconButton> createState() => _HoverGlassIconButtonState();
}

class _HoverGlassIconButtonState extends State<_HoverGlassIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isDark ? const Color(0xFF223A58) : const Color(0xFFF4EFE0))
                  : (widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.8) : const Color(0xFFFBF8EE).withValues(alpha: 0.9)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFFC5A85E)).withValues(alpha: _isHovered ? 0.5 : 0.2),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
            ),
          ),
        ),
      ),
    );
  }
}
