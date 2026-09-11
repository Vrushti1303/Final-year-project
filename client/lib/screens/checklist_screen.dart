import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../widgets/user_profile_button.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  final String type;
  final String? initialTitle;

  const ChecklistScreen({
    super.key,
    required this.type,
    this.initialTitle,
  });

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  Map<String, dynamic>? _checklistData;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All'; // All, Pending, Completed

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      final data = await ApiService.fetchChecklist(widget.type);
      if (mounted) {
        setState(() {
          _checklistData = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleItem(int index, bool? value) async {
    final bool isCompleted = value ?? false;
    final items = _checklistData?['items'] as List<dynamic>? ?? [];
    if (index < 0 || index >= items.length) return;

    final item = items[index];
    final String itemId = (item['id'] ?? item['_id'] ?? '').toString();

    // Optimistic UI update
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
            content: Text('Failed to update: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final tr = ref.read(localeProvider.notifier).translate;
    final items = _checklistData?['items'] as List<dynamic>? ?? [];
    if (index < 0 || index >= items.length) return;

    final item = items[index];
    final String itemId = (item['id'] ?? item['_id'] ?? '').toString();
    final itemTitle = (item['title'] ?? 'Task').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tr('checklists.deleteItem')),
          content: Text('${tr('checklists.deleteItemConfirm')}\n\n"$itemTitle"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('common.delete')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Optimistic deletion
    final removedItem = items.removeAt(index);
    setState(() {});

    try {
      await ApiService.deleteChecklistItem(widget.type, itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('checklists.itemDeleted')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          items.insert(index, removedItem);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete item: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController controller = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr('checklists.addNewItem'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('checklists.enterTitle'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isAdding,
                    decoration: InputDecoration(
                      hintText: tr('checklists.verifyTitleDeed'),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => isAdding = true);
                      try {
                        await ApiService.addChecklistItem(widget.type, controller.text.trim());
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          _loadChecklist();
                        }
                      } catch (e) {
                        setDialogState(() => isAdding = false);
                      }
                    },
                  ),
                  if (isAdding)
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                if (!isAdding)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(tr('common.cancel')),
                  ),
                if (!isAdding)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => isAdding = true);
                      try {
                        await ApiService.addChecklistItem(widget.type, controller.text.trim());
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          _loadChecklist();
                        }
                      } catch (e) {
                        setDialogState(() => isAdding = false);
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(tr('common.add')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog() {
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTitle = (_checklistData?['title'] ?? widget.initialTitle ?? 'Property Checklist').toString();
    final controller = TextEditingController(text: currentTitle);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(tr('checklists.renameChecklist')),
              content: TextField(
                controller: controller,
                autofocus: true,
                enabled: !isSaving,
                decoration: InputDecoration(
                  hintText: tr('checklists.enterNewName'),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(tr('common.cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newTitle = controller.text.trim();
                          if (newTitle.isEmpty) return;
                          setDialogState(() => isSaving = true);
                          try {
                            await ApiService.renameChecklist(widget.type, newTitle);
                            if (mounted) {
                              setState(() {
                                if (_checklistData != null) {
                                  _checklistData!['title'] = newTitle;
                                }
                              });
                            }
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tr('checklists.renamedSuccess')),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: Text(tr('recentDocs.save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEntireChecklist() async {
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tr('checklists.deleteChecklist')),
          content: Text(tr('checklists.deleteConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('common.delete')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteChecklist(widget.type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('checklists.deletedSuccess')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete checklist: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final title = _checklistData?['title'] ?? widget.initialTitle ?? tr('checklists.title');
    final allItems = (_checklistData?['items'] as List<dynamic>?) ?? [];
    final totalCount = allItems.length;
    final completedCount = allItems.where((i) => i['isCompleted'] == true).length;
    final pendingCount = totalCount - completedCount;
    final progressRatio = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    // Filter items based on selected tab
    final filteredItems = <Map<String, dynamic>>[];
    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i] as Map<String, dynamic>;
      final isComp = item['isCompleted'] == true;
      if (_selectedFilter == 'Pending' && isComp) continue;
      if (_selectedFilter == 'Completed' && !isComp) continue;
      filteredItems.add({...item, '_originalIndex': i});
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'rename') {
                _showRenameDialog();
              } else if (val == 'delete') {
                _deleteEntireChecklist();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Text(tr('checklists.renameChecklist'), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Text(tr('checklists.deleteChecklist'), style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
          const UserProfileButton(),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: _checklistData != null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _showAddItemDialog,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_task_rounded, size: 20),
              label: Text(
                tr('checklists.addItem'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadChecklist,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(tr('common.retry')),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
                      children: [
                        // Progress Summary Card
                        _buildProgressCard(tr, isDark, colorScheme, completedCount, totalCount, progressRatio),
                        const SizedBox(height: 16),

                        // Filter Segment
                        _buildFilterRow(tr, isDark, totalCount, pendingCount, completedCount),
                        const SizedBox(height: 16),

                        // Tasks list
                        if (filteredItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedFilter == 'Completed' ? Icons.check_circle_outline_rounded : Icons.task_alt_rounded,
                                  size: 40,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedFilter == 'Completed'
                                      ? 'No completed tasks yet.'
                                      : (_selectedFilter == 'Pending'
                                          ? tr('checklists.allDone')
                                          : 'No tasks found in this checklist.'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...filteredItems.map((item) {
                            final origIndex = item['_originalIndex'] as int;
                            final isComp = item['isCompleted'] == true;
                            final itemTitle = (item['title'] ?? '').toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isComp
                                      ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  width: isComp ? 1.2 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: Checkbox(
                                  value: isComp,
                                  activeColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  onChanged: (val) => _toggleItem(origIndex, val),
                                ),
                                title: Text(
                                  itemTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isComp ? FontWeight.w500 : FontWeight.w600,
                                    decoration: isComp ? TextDecoration.lineThrough : null,
                                    color: isComp
                                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  hoverColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  tooltip: tr('checklists.deleteItem'),
                                  onPressed: () => _deleteItem(origIndex),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressCard(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    ColorScheme colorScheme,
    int completed,
    int total,
    double ratio,
  ) {
    final percent = (ratio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF172554)]
              : [const Color(0xFFF0FDF4), const Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.task_alt_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tr('checklists.progress'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (percent == 100 ? const Color(0xFF10B981) : const Color(0xFF2563EB)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: percent == 100 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent == 100 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr('checklists.completedRatio', {'completed': completed.toString(), 'total': total.toString()}),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    int total,
    int pending,
    int completed,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip('All', '${tr('checklists.filterAll')} ($total)', isDark),
          const SizedBox(width: 8),
          _buildChip('Pending', '${tr('checklists.filterPending')} ($pending)', isDark, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildChip('Completed', '${tr('checklists.filterCompleted')} ($completed)', isDark, color: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label, bool isDark, {Color color = const Color(0xFF2563EB)}) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
