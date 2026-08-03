import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checklist_screen.dart';

const _bgColor = Color(0xFF171218);
const _surfaceColor = Color(0xFF211A24);
const _primaryColor = Color(0xFF564C63);
const _secondaryColor = Color(0xFF7D84A6);
const _textPrimary = Color(0xFFF5F5F5);
const _textSecondary = Color(0xFFB8B8B8);
const _errorColor = Color(0xFFD76C6C);

class ChecklistsListScreen extends StatefulWidget {
  const ChecklistsListScreen({super.key});

  @override
  State<ChecklistsListScreen> createState() => _ChecklistsListScreenState();
}

class _ChecklistsListScreenState extends State<ChecklistsListScreen> {
  List<dynamic> _checklists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final checklists = await ApiService.fetchAllChecklists();
      setState(() {
        _checklists = checklists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
    ).then((_) => _loadChecklists()); // Reload when coming back
  }

  void _showChecklistDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    bool isGenerating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              title: const Text('New Checklist', style: TextStyle(color: _textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What kind of transaction are you doing?',
                    style: TextStyle(color: _textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Selling a flat in Mumbai',
                      hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: _bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                    enabled: !isGenerating,
                  ),
                  if (isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                    ),
                ],
              ),
              actions: [
                if (!isGenerating)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
                  ),
                if (!isGenerating)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      setState(() => isGenerating = true);
                      try {
                        final result = await ApiService.generateChecklist(controller.text.trim());
                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          _navigateTo(ChecklistScreen(type: result['type']));
                        }
                      } catch (e) {
                        setState(() => isGenerating = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Generate', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Checklists',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChecklistDialog(context),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: _errorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChecklists,
                        style: ElevatedButton.styleFrom(backgroundColor: _surfaceColor),
                        child: const Text('Retry', style: TextStyle(color: _textPrimary)),
                      )
                    ],
                  ),
                )
              : _checklists.isEmpty
                  ? Center(
                      child: Text(
                        'No checklists found.\nTap "New" to generate one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _textSecondary.withValues(alpha: 0.7), fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _checklists.length,
                      itemBuilder: (context, index) {
                        final checklist = _checklists[index];
                        final items = checklist['items'] as List<dynamic>? ?? [];
                        final completedCount = items.where((item) => item['isCompleted'] == true).length;
                        final totalCount = items.length;
                        
                        return Card(
                          color: _surfaceColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _navigateTo(ChecklistScreen(type: checklist['type'])),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.checklist_rounded,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          checklist['title'] ?? 'Untitled Checklist',
                                          style: const TextStyle(
                                            color: _textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$completedCount of $totalCount completed',
                                          style: const TextStyle(
                                            color: _textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: _textSecondary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
