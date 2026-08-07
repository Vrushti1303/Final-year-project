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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rate limit reached. Please wait a moment.'),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
          )
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
    final surfaceColor = colorScheme.surface;
    final borderColor = colorScheme.outline;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.balance, size: 64, color: primaryAccent),
              const SizedBox(height: 24),
              Text('How can I help today?', textAlign: TextAlign.center, style: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Ask a legal question or select one of the suggested prompts below.', textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 16)),
              const SizedBox(height: 32),
              
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👋 Welcome to your Legal AI Assistant', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('I can assist you with property laws, reviewing legal documents, and generating drafts. Here is what I can do:', style: TextStyle(color: textSecondary, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildCapability(Icons.edit_document, 'Draft legal agreements', bgColor, borderColor, primaryAccent, textPrimary),
                        _buildCapability(Icons.gavel, 'Explain RERA and property laws', bgColor, borderColor, primaryAccent, textPrimary),
                        _buildCapability(Icons.plagiarism_outlined, 'Review clauses', bgColor, borderColor, primaryAccent, textPrimary),
                        _buildCapability(Icons.lightbulb_outline, 'Provide legal guidance', bgColor, borderColor, primaryAccent, textPrimary),
                        _buildCapability(Icons.description_outlined, 'Generate contract templates', bgColor, borderColor, primaryAccent, textPrimary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  'Draft an Agreement to Sell',
                  'Explain RERA Rights',
                  'Draft a Rent Agreement',
                  'Property Registration Guide',
                  'Stamp Duty Information',
                  'Review Contract Clauses',
                ].map((s) => _HoverableChip(label: s, onTap: () => _sendMessage(textOverride: s))).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapability(IconData icon, String title, Color bgColor, Color borderColor, Color primaryAccent, Color textPrimary) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: textPrimary, fontSize: 14))),
        ],
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
    final surfaceColor = colorScheme.surface;
    final borderColor = colorScheme.outline;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final primaryAccent = colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 32, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.attach_file, color: textSecondary),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: TextStyle(color: textPrimary, fontSize: 16),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ask about property laws, legal clauses, RERA, or request a legal draft...',
                hintStyle: TextStyle(color: textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic, color: textSecondary),
            onPressed: () {},
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isHovered ? primaryAccent.withValues(alpha: 0.8) : primaryAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
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
