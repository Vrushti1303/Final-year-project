import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/theme_toggle_button.dart';

class AnalysisScreen extends StatefulWidget {
  final String originalText;
  final List<dynamic> analysis;

  const AnalysisScreen({super.key, required this.originalText, required this.analysis});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isExplaining = false;
  
  Color _getColorForCategory(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (category.toLowerCase().trim()) {
      case 'green': return isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green[100]!;
      case 'yellow': return isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.yellow[100]!;
      case 'red': return isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red[100]!;
      default: return isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey[200]!;
    }
  }
  
  Color _getBorderColor(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (category.toLowerCase().trim()) {
      case 'green': return isDark ? Colors.green[400]! : Colors.green;
      case 'yellow': return isDark ? Colors.orange[400]! : Colors.orange;
      case 'red': return isDark ? Colors.red[400]! : Colors.red;
      default: return isDark ? Colors.grey[400]! : Colors.grey;
    }
  }

  Future<void> _explainSnippet(String snippet) async {
    setState(() => _isExplaining = true);
    try {
      final explanation = await ApiService.explainSnippet(widget.originalText, snippet);
      if (!mounted) return;
      _showExplanationModal(snippet, explanation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isExplaining = false);
    }
  }

  void _showExplanationModal(String snippet, String explanation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plain English Explanation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: Text('"$snippet"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 16),
              Text(explanation, style: TextStyle(fontSize: 16, height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.analysis.length,
            itemBuilder: (context, index) {
              final item = widget.analysis[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _getBorderColor(context, item['category']), width: 2),
                ),
                color: _getColorForCategory(context, item['category']),
                child: InkWell(
                  onTap: () => _explainSnippet(item['text']),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['category'].toUpperCase(), 
                                style: TextStyle(fontWeight: FontWeight.bold, color: _getBorderColor(context, item['category']))),
                            Icon(Icons.touch_app, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['text'], style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text('Risk Reason: ${item['reason']}', 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isExplaining)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Simplifying legal jargon...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
