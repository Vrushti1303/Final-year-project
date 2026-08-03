import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _bgColor = Color(0xFF171218);
const _surfaceColor = Color(0xFF211A24);
const _primaryColor = Color(0xFF564C63);
const _secondaryColor = Color(0xFF7D84A6);
const _textPrimary = Color(0xFFF5F5F5);
const _textSecondary = Color(0xFFB8B8B8);
const _errorColor = Color(0xFFD76C6C);

class ChecklistScreen extends StatefulWidget {
  final String type;
  const ChecklistScreen({super.key, required this.type});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  Map<String, dynamic>? _checklistData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      final data = await ApiService.fetchChecklist(widget.type);
      setState(() {
        _checklistData = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(int index, bool? value) async {
    final bool isCompleted = value ?? false;
    final item = _checklistData!['items'][index];
    final String itemId = item['id'];
    
    // Optimistic update
    setState(() {
      item['isCompleted'] = isCompleted;
    });

    try {
      await ApiService.updateChecklistItem(widget.type, itemId, isCompleted);
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          item['isCompleted'] = !isCompleted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final TextEditingController controller = TextEditingController();
    bool isAdding = false;

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
              title: const Text('Add New Item', style: TextStyle(color: _textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the title of the new task',
                    style: TextStyle(color: _textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Verify Title Deed',
                      hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: _bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    enabled: !isAdding,
                    autofocus: true,
                  ),
                  if (isAdding)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                    ),
                ],
              ),
              actions: [
                if (!isAdding)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
                  ),
                if (!isAdding)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      setState(() => isAdding = true);
                      try {
                        await ApiService.addChecklistItem(widget.type, controller.text.trim());
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadChecklist(); // Reload to fetch the new item
                        }
                      } catch (e) {
                        setState(() => isAdding = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
                              backgroundColor: _errorColor,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Add', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
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
        title: Text(
          _checklistData?['title'] ?? 'Checklist',
          style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: _checklistData != null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _showAddItemDialog,
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
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
                        onPressed: _loadChecklist,
                        style: ElevatedButton.styleFrom(backgroundColor: _surfaceColor),
                        child: const Text('Retry', style: TextStyle(color: _textPrimary)),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Padding for FAB
                  itemCount: _checklistData!['items'].length,
                  itemBuilder: (context, index) {
                    final item = _checklistData!['items'][index];
                    return Card(
                      color: _surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            color: item['isCompleted'] ? _textSecondary : _textPrimary,
                            decoration: item['isCompleted'] ? TextDecoration.lineThrough : null,
                            fontSize: 16,
                          ),
                        ),
                        value: item['isCompleted'],
                        onChanged: (val) => _toggleItem(index, val),
                        activeColor: const Color(0xFF10B981),
                        checkColor: Colors.white,
                        side: const BorderSide(color: _secondaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
