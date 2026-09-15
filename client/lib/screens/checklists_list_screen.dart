import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';
import 'checklist_screen.dart';
import '../widgets/user_profile_button.dart';

class ChecklistsListScreen extends ConsumerStatefulWidget {
  const ChecklistsListScreen({super.key});

  @override
  ConsumerState<ChecklistsListScreen> createState() => _ChecklistsListScreenState();
}

class _ChecklistsListScreenState extends ConsumerState<ChecklistsListScreen> with TickerProviderStateMixin {
  List<dynamic> _checklists = [];
  bool _isLoading = true;
  String? _error;
  Offset _mousePos = const Offset(600, 300);

  // Animation Controllers
  AnimationController? _ambientController;
  Animation<double>? _pulseAnimation;
  AnimationController? _entryController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  void _initControllers() {
    if (_entryController == null) {
      _entryController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
      );
      _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController!, curve: Curves.easeOutCubic),
      );
      _entryController!.forward();
    }

    _ambientController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    _pulseAnimation ??= Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ambientController!, curve: Curves.easeInOutSine),
    );
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadChecklists();
  }

  @override
  void dispose() {
    _entryController?.dispose();
    _ambientController?.dispose();
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
          backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          title: Text(
            tr('checklists.deleteChecklist'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text(
            '${tr('checklists.deleteConfirm')}\n\n"$title"',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                tr('common.cancel'),
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                tr('common.delete'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
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
              backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                ),
              ),
              title: Text(
                tr('checklists.renameChecklist'),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                enabled: !isSaving,
                style: GoogleFonts.inter(fontSize: 14, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: tr('checklists.enterNewName'),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF101F31) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC5A85E), width: 1.5),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    tr('common.cancel'),
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A85E),
                    foregroundColor: const Color(0xFF101F31),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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
                  child: Text(
                    tr('recentDocs.save'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
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
              backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: isDark ? const Color(0xFFC5A85E).withValues(alpha: 0.35) : const Color(0xFFC5A85E).withValues(alpha: 0.25),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC5A85E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC5A85E), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('checklists.newChecklist'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF101F31),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('checklists.question'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      enabled: !isGenerating,
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: tr('checklists.hint'),
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF101F31) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFC5A85E), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('checklists.starterTitle'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(tr('checklists.template1'), controller, isDark),
                        _buildPresetChip(tr('checklists.template2'), controller, isDark),
                        _buildPresetChip(tr('checklists.template3'), controller, isDark),
                        _buildPresetChip(tr('checklists.template4'), controller, isDark),
                      ],
                    ),
                    if (isGenerating)
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.8, color: Color(0xFFC5A85E)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'AI is generating custom legal due-diligence steps...',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC5A85E), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!isGenerating)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      tr('common.cancel'),
                      style: GoogleFonts.inter(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!isGenerating)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A85E),
                      foregroundColor: const Color(0xFF101F31),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      elevation: 2,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          tr('checklists.generateBtn'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101F31) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    ref.watch(localeProvider);
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    final bgGradientColors = isDark
        ? const [
            Color(0xFF162B43),
            Color(0xFF13253A),
            Color(0xFF101F31),
          ]
        : const [
            Color(0xFFFBF8EE),
            Color(0xFFF7F1D0),
            Color(0xFFF4EFE0),
          ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateChecklistDialog(context),
        backgroundColor: const Color(0xFFC5A85E),
        foregroundColor: const Color(0xFF101F31),
        elevation: 4,
        hoverElevation: 8,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          tr('checklists.newBtn'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      body: MouseRegion(
        onHover: (event) {
          if (isDesktop) {
            setState(() => _mousePos = event.position);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgGradientColors,
            ),
          ),
          child: Stack(
            children: [
              // ==========================================
              // AMBIENT LIGHTING (MATCHING DASHBOARD)
              // ==========================================
              AnimatedBuilder(
                animation: _ambientController!,
                builder: (context, child) {
                  final pulse = _pulseAnimation?.value ?? 1.0;
                  return Stack(
                    children: [
                      // Orb 1: Top-Left Gold Ambient Aurora
                      Positioned(
                        top: -140 + (25 * _ambientController!.value),
                        left: -120 + (20 * _ambientController!.value),
                        child: IgnorePointer(
                          child: Container(
                            width: 580 * pulse,
                            height: 580 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.13 : 0.08),
                                  const Color(0xFFB38938).withValues(alpha: isDark ? 0.06 : 0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 2: Bottom-Right Cyan Ambient Aurora
                      Positioned(
                        bottom: -100 + (30 * (1.0 - _ambientController!.value)),
                        right: -140,
                        child: IgnorePointer(
                          child: Container(
                            width: 620 * (2.0 - pulse),
                            height: 620 * (2.0 - pulse),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.09 : 0.05),
                                  const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.04 : 0.02),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Orb 3: Mouse-responsive Interactive Spotlight (Desktop)
                      if (isDesktop)
                        Positioned(
                          left: _mousePos.dx - 350,
                          top: _mousePos.dy - 350,
                          child: IgnorePointer(
                            child: Container(
                              width: 700,
                              height: 700,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.045 : 0.025),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // ==========================================
              // MAIN CONTENT
              // ==========================================
              SafeArea(
                child: Column(
                  children: [
                    // TOP BAR
                    _buildTopBar(context, isDark, tr),

                    // BODY CONTENT
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                        child: SlideTransition(
                          position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 920),
                              child: _isLoading
                                  ? _buildLoadingSkeleton(isDark)
                                  : _error != null
                                      ? _buildErrorState(tr, isDark)
                                      : _checklists.isEmpty
                                          ? _buildEmptyState(tr, isDark, isDesktop)
                                          : _buildChecklistCollection(tr, isDark, isDesktop),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, bool isDark, String Function(String, [Map<String, String>?]) tr) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: Back button
          Align(
            alignment: Alignment.centerLeft,
            child: _HoverGlassButton(
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('common.back'),
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFE8E1D0) : const Color(0xFF244A78),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Exact dead-center badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.35 : 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFC5A85E),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFC5A85E),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PROPERTY DUE DILIGENCE ENGINE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC5A85E),
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Profile Button
          const Align(
            alignment: Alignment.centerRight,
            child: UserProfileButton(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HERO INTRO BANNER
  // ==========================================
  Widget _buildHeroIntro(String Function(String, [Map<String, String>?]) tr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.95) : const Color(0xFFFBF8EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC5A85E).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFFC5A85E),
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A85E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tr('checklists.heroTitle'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFFC5A85E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr('checklists.heroHeadline'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF101F31),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr('checklists.heroSub'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
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
  // CHECKLIST COLLECTION
  // ==========================================
  Widget _buildChecklistCollection(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    bool isDesktop,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 16.0,
      ),
      children: [
        _buildHeroIntro(tr, isDark),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  tr('checklists.casesHeading'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF101F31),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_checklists.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC5A85E),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._checklists.map((checklist) {
          return _DueDiligenceCaseCard(
            checklist: checklist,
            isDark: isDark,
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
        const SizedBox(height: 80),
      ],
    );
  }

  // ==========================================
  // ONBOARDING EMPTY STATE
  // ==========================================
  Widget _buildEmptyState(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeroIntro(tr, isDark),
          const SizedBox(height: 12),

          // Layered Document Motif
          _buildLayeredDocumentMotif(isDark),
          const SizedBox(height: 22),

          Text(
            tr('checklists.emptyTitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF101F31),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              tr('checklists.emptySub'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Create CTA
          ElevatedButton.icon(
            onPressed: () => _showCreateChecklistDialog(context),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              tr('checklists.newChecklist'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A85E),
              foregroundColor: const Color(0xFF101F31),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            ),
          ),
          const SizedBox(height: 40),

          // Quick Start Section
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('checklists.starterTitle'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF101F31),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr('checklists.quickStartSub'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildStarterCard(
            title: tr('checklists.template1'),
            subtitle: 'Title deed chain, society NOC, Khata extract & encumbrance check',
            icon: Icons.apartment_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Buying a resale apartment in a co-operative housing society'),
          ),
          const SizedBox(height: 10),
          _buildStarterCard(
            title: tr('checklists.template2'),
            subtitle: 'RERA registration, builder-buyer agreement, milestone approvals & CC',
            icon: Icons.domain_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Buying an under-construction flat from a RERA registered builder'),
          ),
          const SizedBox(height: 10),
          _buildStarterCard(
            title: tr('checklists.template3'),
            subtitle: 'Lock-in period, security deposit, stamp duty, sub-letting & usage clauses',
            icon: Icons.store_mall_directory_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Commercial property lease due diligence and agreement clauses'),
          ),
          const SizedBox(height: 10),
          _buildStarterCard(
            title: tr('checklists.template4'),
            subtitle: 'Title clearance, 7/12 extract, zoning & mutation entries',
            icon: Icons.landscape_rounded,
            isDark: isDark,
            onTap: () => _showCreateChecklistDialog(context, 'Agricultural or open plot land purchase due diligence and title verification'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLayeredDocumentMotif(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFC5A85E).withValues(alpha: isDark ? 0.16 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC5A85E).withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 38,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2F48) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334356) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
            Container(
              width: 42,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101F31) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFC5A85E).withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC5A85E).withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.checklist_rounded,
                  size: 26,
                  color: Color(0xFFC5A85E),
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
    return _HoverStarterCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isDark: isDark,
      onTap: onTap,
    );
  }

  // ==========================================
  // LOADING SKELETON
  // ==========================================
  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1B2F48) : const Color(0xFFE2E8F0)).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < 3; i++) ...[
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1B2F48) : const Color(0xFFE2E8F0)).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // ERROR RECOVERY STATE
  // ==========================================
  Widget _buildErrorState(
    String Function(String, [Map<String, String>?]) tr,
    bool isDark,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2F48) : Colors.white,
          borderRadius: BorderRadius.circular(22),
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
            Text(
              'Unable to Load Checklists',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadChecklists,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr('common.retry'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A85E),
                foregroundColor: const Color(0xFF101F31),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// LEGAL CASE FILE CARD WIDGET
// ==========================================
class _DueDiligenceCaseCard extends StatefulWidget {
  final Map<String, dynamic> checklist;
  final bool isDark;
  final String Function(String, [Map<String, String>?]) tr;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _DueDiligenceCaseCard({
    required this.checklist,
    required this.isDark,
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

    final accentColor = isAllDone ? const Color(0xFF10B981) : const Color(0xFFC5A85E);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 16),
          transform: Matrix4.translationValues(0, _isHovered ? -3.0 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.95) : const Color(0xFFFBF8EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.8)
                  : (isAllDone
                      ? const Color(0xFF10B981).withValues(alpha: widget.isDark ? 0.45 : 0.35)
                      : (widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0))),
              width: _isHovered || isAllDone ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? accentColor.withValues(alpha: widget.isDark ? 0.2 : 0.1)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.03),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Legal dossier icon, Case type & Title, Actions Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: widget.isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        isAllDone ? Icons.verified_user_rounded : Icons.folder_shared_rounded,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tr('checklists.verificationBadge'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: widget.isDark ? Colors.white : const Color(0xFF101F31),
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
                      color: widget.isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                        ),
                      ),
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
                              const Icon(Icons.edit_outlined, size: 17, color: Color(0xFFC5A85E)),
                              const SizedBox(width: 10),
                              Text(
                                widget.tr('checklists.renameChecklist'),
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
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
                              Text(
                                widget.tr('checklists.deleteChecklist'),
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fine Divider
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                ),
                const SizedBox(height: 14),

                // Progress Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.tr('checklists.dueDiligenceProgress'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Smooth Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: widget.isDark ? const Color(0xFF101F31) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Row: Completion Count & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of $totalCount completed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: widget.isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAllDone ? Icons.check_circle_rounded : Icons.pending_outlined,
                            size: 12,
                            color: accentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isAllDone
                                ? widget.tr('checklists.completed')
                                : widget.tr('checklists.inProgress'),
                            style: GoogleFonts.inter(
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

// ==========================================
// STARTER TEMPLATE CARD
// ==========================================
class _HoverStarterCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverStarterCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverStarterCard> createState() => _HoverStarterCardState();
}

class _HoverStarterCardState extends State<_HoverStarterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.95) : const Color(0xFFFBF8EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFC5A85E).withValues(alpha: 0.8)
                  : (widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? const Color(0xFFC5A85E).withValues(alpha: widget.isDark ? 0.15 : 0.08)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.1 : 0.02),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A85E).withValues(alpha: widget.isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC5A85E).withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(widget.icon, color: const Color(0xFFC5A85E), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : const Color(0xFF101F31),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: _isHovered ? const Color(0xFFC5A85E) : (widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOVER GLASS BUTTON
// ==========================================
class _HoverGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;

  const _HoverGlassButton({
    required this.child,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_HoverGlassButton> createState() => _HoverGlassButtonState();
}

class _HoverGlassButtonState extends State<_HoverGlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark ? const Color(0xFFC5A85E).withValues(alpha: 0.22) : const Color(0xFFC5A85E).withValues(alpha: 0.18))
                : (widget.isDark ? const Color(0xFF1B2F48).withValues(alpha: 0.7) : const Color(0xFFFBF8EE).withValues(alpha: 0.9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFC5A85E).withValues(alpha: 0.6)
                  : (widget.isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0)),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFC5A85E).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
