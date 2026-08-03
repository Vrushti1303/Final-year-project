import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  Future<void> _sendMessage({String? textOverride}) async {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      if (textOverride == null) {
        _controller.clear();
      }
    });

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
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': response['reply'] ?? 'Empty response',
          'suggestions': response['suggestions']
        });
      });
    } on RateLimitException catch (e) {
      setState(() {
        _messages.add({
          'role': 'error', 
          'text': '⚠️ Our servers are currently busy due to high demand. Please wait 15 seconds before trying again.'
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
      setState(() {
        _messages.add({'role': 'error', 'text': 'Error: $e'});
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8, top: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blueAccent : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser ? const Radius.circular(0) : null,
                            bottomLeft: !isUser ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: MarkdownBody(
                          data: msg['text']!,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: isUser ? Colors.white : Colors.black87),
                            h3: TextStyle(color: isUser ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: isUser ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      if (!isUser && msg['suggestions'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: (msg['suggestions'] as List).map((suggestion) => ActionChip(
                              label: Text(suggestion),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: TextStyle(color: Colors.blue.shade900),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.blue.shade200),
                              ),
                              onPressed: () => _sendMessage(textOverride: suggestion),
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('AI is typing...', style: TextStyle(color: Colors.grey)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about RERA or request a draft...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
