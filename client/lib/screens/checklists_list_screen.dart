import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';
import 'checklist_screen.dart';
import '../widgets/user_profile_button.dart';

class ChecklistsListScreen extends ConsumerStatefulWidget {
  const ChecklistsListScreen({super.key});

  @override
  ConsumerState<ChecklistsListScreen> createState() => _ChecklistsListScreenState();
}

class _ChecklistsListScreenState extends ConsumerState<ChecklistsListScreen> {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = ref.read(localeProvider.notifier);
    final TextEditingController controller = TextEditingController();
    bool isGenerating = false;

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
              title: Text(loc.translate('checklists.newChecklist'), style: TextStyle(color: colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('checklists.question'),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: loc.translate('checklists.hint'),
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                    enabled: !isGenerating,
                  ),
                  if (isGenerating)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                    ),
                ],
              ),
              actions: [
                if (!isGenerating)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.translate('common.cancel'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                if (!isGenerating)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
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
                            SnackBar(
                              content: Text('Error: $e', style: TextStyle(color: colorScheme.onError)),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(loc.translate('checklists.generateBtn'), style: TextStyle(color: colorScheme.onPrimary)),
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
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = ref.read(localeProvider.notifier);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          UserProfileButton(),
          SizedBox(width: 8),
        ],
        title: Text(
          loc.translate('checklists.title'),
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChecklistDialog(context),
        backgroundColor: colorScheme.primary,
        icon: Icon(Icons.add, color: colorScheme.onPrimary),
        label: Text(loc.translate('checklists.newBtn'), style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
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
                        onPressed: _loadChecklists,
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.surface),
                        child: Text(loc.translate('common.retry'), style: TextStyle(color: colorScheme.onSurface)),
                      )
                    ],
                  ),
                )
              : _checklists.isEmpty
                  ? Center(
                      child: Text(
                        loc.translate('checklists.empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 16),
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
                          color: colorScheme.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outline),
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
                                      color: colorScheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.checklist_rounded,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          checklist['title'] ?? loc.translate('checklists.untitled'),
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$completedCount of $totalCount completed',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
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
