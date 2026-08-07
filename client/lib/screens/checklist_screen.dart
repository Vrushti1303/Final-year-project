import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/theme_toggle_button.dart';



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
            content: Text('Failed to update: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController controller = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outline),
              ),
              title: Text('Add New Item', style: TextStyle(color: colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the title of the new task',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'e.g. Verify Title Deed',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    enabled: !isAdding,
                    autofocus: true,
                  ),
                  if (isAdding)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                    ),
                ],
              ),
              actions: [
                if (!isAdding)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                if (!isAdding)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
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
                              content: Text('Error: $e', style: TextStyle(color: colorScheme.onError)),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('Add', style: TextStyle(color: colorScheme.onPrimary)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _checklistData?['title'] ?? 'Checklist',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      floatingActionButton: _checklistData != null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _showAddItemDialog,
              backgroundColor: colorScheme.primary,
              icon: Icon(Icons.add, color: colorScheme.onPrimary),
              label: Text('Add Item', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
            )
          : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChecklist,
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.surface),
                        child: Text('Retry', style: TextStyle(color: colorScheme.onSurface)),
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
                      color: colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            color: item['isCompleted'] ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                            decoration: item['isCompleted'] ? TextDecoration.lineThrough : null,
                            fontSize: 16,
                          ),
                        ),
                        value: item['isCompleted'],
                        onChanged: (val) => _toggleItem(index, val),
                        activeColor: colorScheme.primary,
                        checkColor: colorScheme.onPrimary,
                        side: BorderSide(color: colorScheme.secondary),
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
