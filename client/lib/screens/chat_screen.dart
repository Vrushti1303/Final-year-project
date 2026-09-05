import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../widgets/theme_toggle_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

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

    _scrollToBottom();

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

      final response = await ApiService.chat(validHistory);
      
      final replyNow = DateTime.now();
      final replyTimeStr = '${replyNow.hour > 12 ? replyNow.hour - 12 : (replyNow.hour == 0 ? 12 : replyNow.hour)}:${replyNow.minute.toString().padLeft(2, '0')} ${replyNow.hour >= 12 ? 'PM' : 'AM'}';

      setState(() {
        _messages.add({
          'role': 'ai',
          'text': response['reply'] ?? 'Empty response',
          'suggestions': response['suggestions'],
          'time': replyTimeStr,
        });
      });
    } on RateLimitException {
      final errNow = DateTime.now();
      final errTimeStr = '${errNow.hour > 12 ? errNow.hour - 12 : (errNow.hour == 0 ? 12 : errNow.hour)}:${errNow.minute.toString().padLeft(2, '0')} ${errNow.hour >= 12 ? 'PM' : 'AM'}';
      setState(() {
        _messages.add({
          'role': 'error', 
          'text': '⚠️ Our servers are currently busy due to high demand. Please wait 15 seconds before trying again.',
          'time': errTimeStr,
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rate limit reached. Please wait a moment.'),
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text('Legal AI Assistant', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            if (!isMobile)
              Text('Ask legal questions, understand property laws...', style: TextStyle(color: textSecondary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              return _AnimatedMessageBubble(
                                message: msg,
                                onSuggestionTap: (s) => _sendMessage(textOverride: s),
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
                    onSend: () => _sendMessage(),
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
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
    final isMobile = MediaQuery.of(context).size.width < 700;

    final promptCards = [
      {
        'icon': Icons.find_in_page_outlined,
        'color': const Color(0xFF3B82F6),
        'title': 'Review Agreement Clauses',
        'desc': 'Scan lease or sale deed terms for hidden liabilities and risky clauses',
        'prompt': 'Can you review the key clauses in a residential property agreement and highlight standard red flags?',
      },
      {
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFF59E0B),
        'title': 'RERA Compliance & Rights',
        'desc': 'Understand builder handover delays, interest compensation, and escrow norms',
        'prompt': 'What are my legal rights and compensation rules under RERA if a builder delays possession?',
      },
      {
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFF10B981),
        'title': 'Draft Legal Agreement',
        'desc': 'Generate standard residential lease, sale agreement, or NOC templates',
        'prompt': 'Please draft a standard 11-month residential rental agreement with essential tenant and landlord clauses.',
      },
      {
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF8B5CF6),
        'title': 'Stamp Duty & Registration',
        'desc': 'Mandatory document checklist, registration procedures, and fee guidelines',
        'prompt': 'What documents and procedures are mandatory for property registration and stamp duty payment in India?',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Legal Scales Emblem
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryAccent.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.balance_rounded, size: 32, color: primaryAccent),
              ),
              const SizedBox(height: 20),

              // Single Focused Greeting
              Text(
                'How can I help with your legal questions?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask any question about Indian property laws, or select a guided prompt below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // 2x2 Interactive Prompt Grid
              if (isMobile)
                Column(
                  children: promptCards.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PromptCard(
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

              const SizedBox(height: 28),

              // Quick question chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  'Delay penalty interest rate',
                  'Carpet vs super built-up area',
                  'Security deposit refund rules',
                  '70% builder escrow rule',
                ].map((s) => _HoverableChip(
                  label: s,
                  onTap: () => _sendMessage(textOverride: 'Explain: $s under Indian property law'),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(String) onSuggestionTap;

  const _AnimatedMessageBubble({required this.message, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    final isError = message['role'] == 'error';
    
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = colorScheme.surface;
    final primaryAccent = colorScheme.primary;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final borderColor = colorScheme.outline;
    final errorColor = colorScheme.error;

    final bgColor = isError ? errorColor.withValues(alpha: 0.1) : (isUser ? primaryAccent : surfaceColor);
    final bColor = isError ? errorColor.withValues(alpha: 0.5) : (isUser ? Colors.transparent : borderColor);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 6, top: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: bColor),
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : null,
                    bottomLeft: !isUser ? const Radius.circular(4) : null,
                  ),
                  boxShadow: isUser ? [] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MarkdownBody(
                  data: message['text']!,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
                    h1: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                    h2: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                    h3: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                    listBullet: TextStyle(color: textPrimary),
                    code: TextStyle(backgroundColor: Colors.black.withValues(alpha: 0.2), color: Colors.blueAccent.shade100),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (message['time'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    message['time'],
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ),
              if (!isUser && message['suggestions'] != null && (message['suggestions'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: (message['suggestions'] as List).map((s) => _HoverableChip(label: s.toString(), onTap: () => onSuggestionTap(s.toString()))).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isMobile;

  const _ChatInput({required this.controller, required this.onSend, required this.isMobile});

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primaryAccent = colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 32, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: textSecondary.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: TextStyle(color: textPrimary, fontSize: 14),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ask about property laws, legal clauses, RERA, or request a legal draft...',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _isHovered ? primaryAccent.withValues(alpha: 0.85) : primaryAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isDark;

  const _PromptCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(top: _isHovered ? 0 : 3, bottom: _isHovered ? 3 : 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isHovered ? const Color(0xFF243044) : const Color(0xFF1E293B))
                : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? (widget.isDark ? 0.25 : 0.06) : (widget.isDark ? 0.12 : 0.02)),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
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
                      color: widget.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 20, color: widget.accentColor),
                  ),
                  AnimatedSlide(
                    offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _isHovered ? widget.accentColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                ),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? primaryAccent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primaryAccent),
          ),
          child: Text(
            widget.label,
            style: TextStyle(color: textPrimary, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
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
    final surfaceColor = colorScheme.surface;
    final borderColor = colorScheme.outline;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AI is thinking', style: TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(width: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Container(width: 4, height: 4, decoration: BoxDecoration(color: textSecondary, shape: BoxShape.circle)),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
