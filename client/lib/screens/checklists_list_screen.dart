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

class _ChecklistsListScreenState extends ConsumerState<ChecklistsListScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _checklists = [];
  bool _isLoading = true;
  String? _error;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _loadChecklists();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklists() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final checklists = await ApiService.fetchAllChecklists();
      if (mounted) {
        setState(() {
          _checklists = checklists;
          _isLoading = false;
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

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) => _loadChecklists());
  }

  Future<void> _deleteChecklist(String type, String title) async {
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tr('checklists.deleteChecklist')),
          content: Text('${tr('checklists.deleteConfirm')}\n\n"$title"'),
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
      final success = await ApiService.deleteChecklist(type);
      if (success && mounted) {
        setState(() {
          _checklists.removeWhere((c) => c['type'] == type);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('checklists.deletedSuccess')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  void _showRenameDialog(String type, String currentTitle) {
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            await ApiService.renameChecklist(type, newTitle);
                            if (mounted) {
                              setState(() {
                                final index = _checklists.indexWhere((c) => c['type'] == type);
                                if (index != -1) {
                                  _checklists[index]['title'] = newTitle;
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

  void _showCreateChecklistDialog(BuildContext context, [String? presetPrompt]) {
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController controller = TextEditingController(text: presetPrompt ?? '');
    bool isGenerating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr('checklists.newChecklist'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('checklists.question'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isGenerating,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: tr('checklists.hint'),
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
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('checklists.starterTitle'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip(tr('checklists.template1'), controller, isDark),
                      _buildPresetChip(tr('checklists.template2'), controller, isDark),
                      _buildPresetChip(tr('checklists.template3'), controller, isDark),
                      _buildPresetChip(tr('checklists.template4'), controller, isDark),
                    ],
                  ),
                  if (isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'AI is generating legal due-diligence steps...',
                              style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                if (!isGenerating)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(tr('common.cancel')),
                  ),
                if (!isGenerating)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    ),
                    onPressed: () async {
                      final promptText = controller.text.trim();
                      if (promptText.isEmpty) return;
                      setDialogState(() => isGenerating = true);
                      try {
                        final result = await ApiService.generateChecklist(promptText);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          _navigateTo(ChecklistScreen(
                            type: result['type'],
                            initialTitle: result['title'],
                          ));
                        }
                      } catch (e) {
                        setDialogState(() => isGenerating = false);
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
                    child: Text(tr('checklists.generateBtn')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(String text, TextEditingController controller, bool isDark) {
    return InkWell(
      onTap: () => controller.text = text,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildHeader(tr, isDark, colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChecklistDialog(context),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 3,
        hoverElevation: 6,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          tr('checklists.newBtn'),
          style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: _isLoading
              ? _buildLoadingSkeleton(isDark)
              : _error != null
                  ? _buildErrorState(tr, isDark)
                  : _checklists.isEmpty
                      ? _buildEmptyState(tr, isDark, colorScheme)
                      : _buildChecklistCollection(tr, isDark, colorScheme),
        ),
      ),
    );
  }

  // ==========================================
  // 1. APP BAR / HEADER
  // ==========================================
  PreferredSizeWidget _buildHeader(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('checklists.title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('checklists.subtitle'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: const [
        UserProfileButton(),
        SizedBox(width: 14),
      ],
    );
  }

  // ==========================================
  // 2. HERO / INTRO SECTION
  // ==========================================
  Widget _buildHeroIntro(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF162B43)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tactical Document Motif Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tr('checklists.heroTitle'),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  tr('checklists.heroHeadline'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('checklists.heroSub'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. CHECKLIST COLLECTION (WHEN ITEMS EXIST)
  // ==========================================
  Widget _buildChecklistCollection(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
      children: [
        _buildHeroIntro(tr, isDark, colorScheme),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  tr('checklists.casesHeading'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_checklists.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._checklists.map((checklist) {
          return _DueDiligenceCaseCard(
            checklist: checklist,
            isDark: isDark,
            colorScheme: colorScheme,
            tr: tr,
            onTap: () => _navigateTo(ChecklistScreen(
              type: (checklist['type'] ?? '').toString(),
              initialTitle: (checklist['title'] ?? '').toString(),
            )),
            onRename: () => _showRenameDialog(
              (checklist['type'] ?? '').toString(),
              (checklist['title'] ?? tr('checklists.untitled')).toString(),
            ),
            onDelete: () => _deleteChecklist(
              (checklist['type'] ?? '').toString(),
              (checklist['title'] ?? tr('checklists.untitled')).toString(),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // 4. ONBOARDING EMPTY STATE
  // ==========================================
  Widget _buildEmptyState(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeroIntro(tr, isDark, colorScheme),
          const SizedBox(height: 8),

          // Layered Document Motif
          _buildLayeredDocumentMotif(isDark),
          const SizedBox(height: 18),

          Text(
            tr('checklists.emptyTitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              tr('checklists.emptySub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary Create CTA
          ElevatedButton.icon(
            onPressed: () => _showCreateChecklistDialog(context),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              tr('checklists.newChecklist'),
              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            ),
          ),
          const SizedBox(height: 36),

          // Quick Start Section
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('checklists.starterTitle'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('checklists.quickStartSub'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildStarterCard(
            title: tr('checklists.template1'),
            subtitle: 'Title deed chain, society NOC, Khata extract & encumbrance check',
            icon: Icons.apartment_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Buying a resale apartment in a co-operative housing society'),
          ),
          const SizedBox(height: 9),
          _buildStarterCard(
            title: tr('checklists.template2'),
            subtitle: 'RERA registration, builder-buyer agreement, milestone approvals & CC',
            icon: Icons.domain_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Buying an under-construction flat from a RERA registered builder'),
          ),
          const SizedBox(height: 9),
          _buildStarterCard(
            title: tr('checklists.template3'),
            subtitle: 'Lock-in period, security deposit, stamp duty, sub-letting & usage clauses',
            icon: Icons.store_mall_directory_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Commercial property lease due diligence and agreement clauses'),
          ),
          const SizedBox(height: 9),
          _buildStarterCard(
            title: tr('checklists.template4'),
            subtitle: 'Title clearance, 7/12 extract, zoning & mutation entries',
            icon: Icons.landscape_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Agricultural or open plot land purchase due diligence and title verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildLayeredDocumentMotif(bool isDark) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.16 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 36,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
            Container(
              width: 38,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.checklist_rounded,
                  size: 24,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 5. LOADING SKELETON
  // ==========================================
  Widget _buildLoadingSkeleton(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final opacity = 0.4 + (_pulseAnimation.value * 0.4);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)).withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < 3; i++) ...[
              Container(
                height: 140,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)).withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ==========================================
  // 6. ERROR RECOVERY STATE
  // ==========================================
  Widget _buildErrorState(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Checklists',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadChecklists,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr('common.retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. LEGAL CASE FILE CARD WIDGET
// ==========================================
class _DueDiligenceCaseCard extends StatefulWidget {
  final Map<String, dynamic> checklist;
  final bool isDark;
  final ColorScheme colorScheme;
  final String Function(String, [Map<String, String>?]) tr;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _DueDiligenceCaseCard({
    required this.checklist,
    required this.isDark,
    required this.colorScheme,
    required this.tr,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_DueDiligenceCaseCard> createState() => _DueDiligenceCaseCardState();
}

class _DueDiligenceCaseCardState extends State<_DueDiligenceCaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final title = (widget.checklist['title'] ?? widget.tr('checklists.untitled')).toString();
    final items = widget.checklist['items'] as List<dynamic>? ?? [];
    final totalCount = items.length;
    final completedCount = items.where((i) => i['isCompleted'] == true).length;
    final ratio = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final percent = (ratio * 100).toInt();
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    final accentColor = isAllDone ? const Color(0xFF10B981) : const Color(0xFF2563EB);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 14),
          transform: Matrix4.translationValues(0, _isHovered ? -2.5 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.6)
                  : (isAllDone
                      ? const Color(0xFF10B981).withValues(alpha: widget.isDark ? 0.35 : 0.25)
                      : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              width: _isHovered || isAllDone ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? (widget.isDark ? 0.3 : 0.08) : (widget.isDark ? 0.12 : 0.02)),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Legal dossier icon, Case type & Title, Actions Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: widget.isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAllDone ? Icons.verified_user_rounded : Icons.folder_shared_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tr('checklists.verificationBadge'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: widget.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'rename') {
                          widget.onRename();
                        } else if (val == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF2563EB)),
                              const SizedBox(width: 10),
                              Text(widget.tr('checklists.renameChecklist'), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Text(widget.tr('checklists.deleteChecklist'), style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Fine Divider
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 12),

                // Progress Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.tr('checklists.dueDiligenceProgress'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Smooth Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Row: Completion Count & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of $totalCount completed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: widget.isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAllDone ? Icons.check_circle_rounded : Icons.pending_outlined,
                            size: 11,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAllDone
                                ? widget.tr('checklists.completed')
                                : widget.tr('checklists.inProgress'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
