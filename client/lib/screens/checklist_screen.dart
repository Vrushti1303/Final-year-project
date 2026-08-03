import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_checklistData?['title'] ?? 'Checklist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _checklistData!['items'].length,
                  itemBuilder: (context, index) {
                    final item = _checklistData!['items'][index];
                    return CheckboxListTile(
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          decoration: item['isCompleted'] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      value: item['isCompleted'],
                      onChanged: (val) => _toggleItem(index, val),
                      activeColor: Colors.green,
                    );
                  },
                ),
    );
  }
}
