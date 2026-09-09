import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  late AnimationController _floatingController;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String? _currentSessionId;
  List<dynamic> _sessions = [];
  bool _isLoadingSessions = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

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
          SnackBar(content: Text('Failed to load conversation: $e')),
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
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E334D) : colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Color(0xFFC94A4A), size: 22),
              const SizedBox(width: 8),
              Text(loc.translate('chat.deleteTitle'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            loc.translate('chat.deleteContent'),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.translate('common.cancel'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC94A4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.translate('common.delete')),
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
              Text(loc.translate('chat.deletedToast')),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
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
      _loadSessions(); // Refresh history list in background
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primaryAccent = colorScheme.primary;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      endDrawer: _buildHistoryDrawer(context, isDark, textPrimary, textSecondary, primaryAccent, loc),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF162B43).withValues(alpha: 0.85) : bgColor.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryAccent.withValues(alpha: 0.25),
                    primaryAccent.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.balance_rounded, size: 16, color: primaryAccent),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.translate('chat.title'),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  loc.translate('chat.subtitle'),
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: textPrimary),
            tooltip: loc.translate('chat.chatHistory'),
            onPressed: () {
              _loadSessions();
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.add_comment_outlined, color: textSecondary),
              tooltip: loc.translate('chat.newChat'),
              onPressed: _clearChat,
            ),
          const UserProfileButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Subtle Ambient Animated Background
          Positioned.fill(
            child: _AmbientLegalBackground(isDark: isDark),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 32,
                                vertical: 20,
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
    );
  }

  Widget _buildHistoryDrawer(BuildContext context, bool isDark, Color textPrimary, Color textSecondary, Color primaryAccent, LocaleNotifier loc) {
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
                    color: isDark ? Colors.white10 : const Color(0xFFE4DDD0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.history_edu_rounded, size: 20, color: primaryAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('chat.savedConsultations'),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          loc.translate('chat.sessionsStored', {'count': _sessions.length.toString()}),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
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
                    color: isDark ? Colors.white10 : const Color(0xFFE4DDD0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textPrimary, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: loc.translate('chat.searchConsultations'),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 12),
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
                        child: Icon(Icons.cancel, size: 14, color: textSecondary),
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
                    color: primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryAccent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: primaryAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('chat.startNewConsultation'),
                        style: TextStyle(
                          color: primaryAccent,
                          fontWeight: FontWeight.w600,
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
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 36, color: textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 10),
                                Text(
                                  _searchQuery.isNotEmpty ? loc.translate('chat.noMatchingConversations') : loc.translate('chat.noSavedConversations'),
                                  style: TextStyle(color: textSecondary, fontSize: 13),
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
                                      ? primaryAccent.withValues(alpha: 0.16)
                                      : (isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryAccent
                                        : (isDark ? Colors.white10 : const Color(0xFFE4DDD0)),
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
                                        color: isSelected ? primaryAccent : Colors.transparent,
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
                                            style: TextStyle(
                                              color: textPrimary,
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
                                              style: TextStyle(
                                                color: textSecondary,
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
                                                  style: TextStyle(
                                                    color: textSecondary,
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
                                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: textSecondary.withValues(alpha: 0.7)),
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

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryAccent = colorScheme.primary;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 750;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final promptCards = [
      {
        'category': loc.translate('chat.card1Cat'),
        'icon': Icons.description_outlined,
        'color': const Color(0xFF3B82F6),
        'title': loc.translate('chat.card1Title'),
        'desc': loc.translate('chat.card1Desc'),
        'prompt': 'Can you review the key clauses in a residential property agreement and highlight standard red flags?',
      },
      {
        'category': loc.translate('chat.card2Cat'),
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFF59E0B),
        'title': loc.translate('chat.card2Title'),
        'desc': loc.translate('chat.card2Desc'),
        'prompt': 'What are my legal rights and compensation rules under RERA if a builder delays possession?',
      },
      {
        'category': loc.translate('chat.card3Cat'),
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFF10B981),
        'title': loc.translate('chat.card3Title'),
        'desc': loc.translate('chat.card3Desc'),
        'prompt': 'Please draft a standard 11-month residential rental agreement with essential tenant and landlord clauses.',
      },
      {
        'category': loc.translate('chat.card4Cat'),
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF8B5CF6),
        'title': loc.translate('chat.card4Title'),
        'desc': loc.translate('chat.card4Desc'),
        'prompt': 'What documents and procedures are mandatory for property registration and stamp duty payment in India?',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Animated Floating Levitation Emblem Badge with Layered Rings
              AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  final floatVal = math.sin(_floatingController.value * math.pi * 2) * 5.0;
                  return Transform.translate(
                    offset: Offset(0, floatVal),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Glow Ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 88 + (_pulseController.value * 8),
                          height: 88 + (_pulseController.value * 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryAccent.withValues(
                              alpha: 0.06 + (_pulseController.value * 0.08),
                            ),
                          ),
                        );
                      },
                    ),

                    // Inner Glassmorphic Emblem Card
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryAccent.withValues(alpha: isDark ? 0.22 : 0.15),
                            primaryAccent.withValues(alpha: isDark ? 0.08 : 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: isDark ? 0.4 : 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryAccent.withValues(alpha: isDark ? 0.25 : 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.balance_rounded,
                          size: 38,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Prominent Headline
              Text(
                loc.translate('chat.heroHeadline'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                loc.translate('chat.heroSubtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              // Legal Badges Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegalTag(Icons.shield_outlined, loc.translate('chat.tagRera'), const Color(0xFF3B82F6), isDark),
                  _buildLegalTag(Icons.description_outlined, loc.translate('chat.tagTenancy'), const Color(0xFF10B981), isDark),
                  _buildLegalTag(Icons.balance_rounded, loc.translate('chat.tagTransfer'), const Color(0xFFF59E0B), isDark),
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
                    color: isDark ? Colors.white10 : const Color(0xFFE4DDD0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        loc.translate('chat.disclaimer'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 11),
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
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
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
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMessageBubble extends StatefulWidget {
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
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble> {
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

    // Pacing calibrated to approximately 35–45 words/second
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
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
    
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = colorScheme.primary;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final errorColor = colorScheme.error;

    final userBgColor = isDark ? const Color(0xFF244A78) : const Color(0xFF244A78);
    final aiBgColor = isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0);
    final borderColor = isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0);

    final rawContent = isUser ? (widget.message['text'] ?? '') : _displayedText;
    final contentToRender = (_isRevealing && _showCursor) ? '$rawContent ▌' : rawContent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
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
                      ? errorColor.withValues(alpha: 0.1)
                      : (isUser ? userBgColor : aiBgColor),
                  border: Border.all(
                    color: isError
                        ? errorColor.withValues(alpha: 0.5)
                        : (isUser ? primaryAccent.withValues(alpha: 0.4) : borderColor),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : null,
                    bottomLeft: !isUser ? const Radius.circular(4) : null,
                  ),
                  boxShadow: isUser ? [
                    BoxShadow(
                      color: userBgColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : [
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
                                const Text(
                                  'You',
                                  style: TextStyle(
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
                                    color: primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isRevealing ? Icons.auto_awesome : Icons.gavel_rounded,
                                    size: 14,
                                    color: primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Legal AI Advisor',
                                  style: TextStyle(
                                    color: primaryAccent,
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
                                      color: primaryAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 8,
                                          height: 8,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'GENERATING',
                                          style: TextStyle(
                                            color: primaryAccent,
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
                                      color: primaryAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'PROPERTY LAW',
                                      style: TextStyle(
                                        color: primaryAccent,
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
                                            color: primaryAccent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: primaryAccent.withValues(alpha: 0.35),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.fast_forward_rounded, size: 12, color: primaryAccent),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Show full answer',
                                                style: TextStyle(
                                                  color: primaryAccent,
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
                                      color: _copied ? const Color(0xFF10B981) : textSecondary,
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
                        p: TextStyle(
                          color: isUser ? Colors.white : textPrimary,
                          fontSize: 14.5,
                          height: 1.65,
                          letterSpacing: -0.1,
                        ),
                        pPadding: const EdgeInsets.only(bottom: 10),
                        h1: TextStyle(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          height: 1.4,
                          letterSpacing: -0.4,
                        ),
                        h1Padding: const EdgeInsets.only(top: 14, bottom: 8),
                        h2: TextStyle(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
                        h2Padding: const EdgeInsets.only(top: 12, bottom: 6),
                        h3: TextStyle(
                          color: isUser ? Colors.white : primaryAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.35,
                        ),
                        h3Padding: const EdgeInsets.only(top: 10, bottom: 4),
                        strong: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w700,
                        ),
                        em: TextStyle(
                          color: isUser ? Colors.white70 : textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: isUser ? Colors.white70 : primaryAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        listBulletPadding: const EdgeInsets.only(right: 6),
                        listIndent: 22,
                        blockquote: TextStyle(
                          color: isUser ? Colors.white70 : textPrimary,
                          fontSize: 13.5,
                          height: 1.55,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        blockquoteDecoration: BoxDecoration(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.1)
                              : primaryAccent.withValues(alpha: isDark ? 0.10 : 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isUser ? Colors.white70 : primaryAccent,
                              width: 3.5,
                            ),
                          ),
                        ),
                        code: TextStyle(
                          backgroundColor: isUser
                              ? Colors.white.withValues(alpha: 0.2)
                              : primaryAccent.withValues(alpha: isDark ? 0.20 : 0.10),
                          color: isUser
                              ? Colors.white
                              : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontFamily: 'monospace',
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
                            color: isDark ? Colors.white12 : const Color(0xFFE4DDD0),
                          ),
                        ),
                        tableBorder: TableBorder.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE4DDD0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tableHead: TextStyle(
                          color: isUser ? Colors.white : (isDark ? const Color(0xFFFFDF8C) : const Color(0xFF244A78)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                        tableBody: TextStyle(
                          color: isUser ? Colors.white : textPrimary,
                          fontSize: 13,
                        ),
                        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark ? Colors.white12 : const Color(0xFFE4DDD0),
                              width: 1.2,
                            ),
                          ),
                        ),
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
                    style: TextStyle(color: textSecondary, fontSize: 11),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primaryAccent = colorScheme.primary;

    final dockBg = isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0);
    final dockBorder = isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 32, vertical: 12),
      decoration: BoxDecoration(
        color: dockBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused ? primaryAccent : dockBorder,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? primaryAccent.withValues(alpha: isDark ? 0.25 : 0.15)
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: _isFocused ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.balance_rounded,
              color: _isFocused ? primaryAccent : textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: TextStyle(color: textPrimary, fontSize: 14),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: ref.watch(localeProvider.notifier).translate('chat.inputHint'),
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 13.5),
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
                  gradient: LinearGradient(
                    colors: [
                      primaryAccent,
                      primaryAccent.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.35),
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
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);
    final cardBg = widget.isDark
        ? (_isHovered ? const Color(0xFF243E5E) : const Color(0xFF1E334D))
        : (_isHovered ? const Color(0xFFFFFFFF) : const Color(0xFFF7F1D0));
    final borderColor = widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(top: _isHovered ? 0 : 3, bottom: _isHovered ? 3 : 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.7)
                  : borderColor,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: _isHovered ? (widget.isDark ? 0.22 : 0.12) : 0.0),
                blurRadius: _isHovered ? 16 : 0,
                offset: Offset(0, _isHovered ? 6 : 2),
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
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withValues(alpha: 0.2),
                          widget.accentColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, size: 20, color: widget.accentColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.category,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    loc.translate('chat.askLegalAi'),
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSlide(
                    offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: widget.accentColor,
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

class _HoverableChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HoverableChip({required this.label, required this.onTap});

  @override
  State<_HoverableChip> createState() => _HoverableChipState();
}

class _HoverableChipState extends State<_HoverableChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryAccent = colorScheme.primary;
    final textPrimary = colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                ? primaryAccent.withValues(alpha: isDark ? 0.2 : 0.12)
                : (isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isHovered ? primaryAccent : (isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gavel_rounded, size: 12, color: primaryAccent),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primaryAccent = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(localeProvider);
    final loc = ref.read(localeProvider.notifier);

    final cardBg = isDark ? const Color(0xFF1E334D) : const Color(0xFFF7F1D0);
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
                color: primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.auto_awesome, size: 13, color: primaryAccent),
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
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
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
                                  decoration: BoxDecoration(color: primaryAccent, shape: BoxShape.circle),
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
                  style: TextStyle(color: textSecondary, fontSize: 10.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientLegalBackground extends StatefulWidget {
  final bool isDark;
  const _AmbientLegalBackground({required this.isDark});

  @override
  State<_AmbientLegalBackground> createState() => _AmbientLegalBackgroundState();
}

class _AmbientLegalBackgroundState extends State<_AmbientLegalBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final tertiaryColor = colorScheme.tertiary;

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return IgnorePointer(
        child: CustomPaint(
          painter: _AmbientCanvasPainter(
            progress: 0.5,
            isDark: widget.isDark,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            tertiaryColor: tertiaryColor,
          ),
          size: Size.infinite,
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return CustomPaint(
            painter: _AmbientCanvasPainter(
              progress: _ambientController.value,
              isDark: widget.isDark,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              tertiaryColor: tertiaryColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _AmbientCanvasPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  _AmbientCanvasPainter({
    required this.progress,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = progress * math.pi * 2;

    // 1. Top-Left Floating Primary Ambient Orb
    final orb1Center = Offset(
      size.width * 0.2 + math.sin(t) * 40,
      size.height * 0.15 + math.cos(t) * 30,
    );
    final orb1Radius = math.min(size.width, size.height) * 0.45;
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
          Colors.transparent,
        ],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, orb1Paint);

    // 2. Top-Right Floating Tertiary/Warm Ambient Orb
    final orb2Center = Offset(
      size.width * 0.82 + math.cos(t * 0.8) * 35,
      size.height * 0.28 + math.sin(t * 0.8) * 35,
    );
    final orb2Radius = math.min(size.width, size.height) * 0.40;
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          tertiaryColor.withValues(alpha: isDark ? 0.05 : 0.04),
          Colors.transparent,
        ],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, orb2Paint);

    // 3. Bottom-Center Secondary Ambient Orb
    final orb3Center = Offset(
      size.width * 0.5 + math.sin(t * 1.2) * 50,
      size.height * 0.85 + math.cos(t * 1.2) * 25,
    );
    final orb3Radius = math.min(size.width, size.height) * 0.50;
    final orb3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryColor.withValues(alpha: isDark ? 0.06 : 0.035),
          Colors.transparent,
        ],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
    canvas.drawCircle(orb3Center, orb3Radius, orb3Paint);

    // 4. Subtle Ambient Floating Micro-Particles (Legal Tech Geometry)
    final particles = [
      {'x': 0.12, 'y': 0.35, 'radius': 2.0, 'speed': 1.0, 'phase': 0.0},
      {'x': 0.88, 'y': 0.18, 'radius': 2.5, 'speed': 0.7, 'phase': 1.5},
      {'x': 0.25, 'y': 0.72, 'radius': 1.8, 'speed': 1.3, 'phase': 3.0},
      {'x': 0.78, 'y': 0.65, 'radius': 2.2, 'speed': 0.9, 'phase': 4.5},
      {'x': 0.52, 'y': 0.22, 'radius': 1.5, 'speed': 1.1, 'phase': 2.2},
      {'x': 0.38, 'y': 0.90, 'radius': 2.0, 'speed': 0.8, 'phase': 5.1},
    ];

    for (final p in particles) {
      final px = (p['x'] as double) * size.width + math.sin(t * (p['speed'] as double) + (p['phase'] as double)) * 14;
      final py = (p['y'] as double) * size.height + math.cos(t * (p['speed'] as double) + (p['phase'] as double)) * 14;
      final r = p['radius'] as double;
      final alpha = (0.04 + 0.04 * math.sin(t + (p['phase'] as double))).clamp(0.02, 0.08);

      final pPaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), r, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}
