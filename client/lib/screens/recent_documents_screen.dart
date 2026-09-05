import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'analysis_screen.dart';
import 'scan_screen.dart';
import '../widgets/theme_toggle_button.dart';

class RecentDocumentsScreen extends StatefulWidget {
  final List<dynamic>? initialDocs;

  const RecentDocumentsScreen({super.key, this.initialDocs});

  @override
  State<RecentDocumentsScreen> createState() => _RecentDocumentsScreenState();
}

class _RecentDocumentsScreenState extends State<RecentDocumentsScreen> {
  List<dynamic> _allDocs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All'; // All, High Risk, Caution, Compliant

  @override
  void initState() {
    super.initState();
    if (widget.initialDocs != null && widget.initialDocs!.isNotEmpty) {
      _allDocs = widget.initialDocs!;
      _isLoading = false;
    }
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      if (_allDocs.isEmpty) {
        setState(() => _isLoading = true);
      }
      final docs = await ApiService.fetchRecentDocuments();
      if (mounted) {
        setState(() {
          _allDocs = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent documents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredDocs {
    return _allDocs.where((doc) {
      final title = (doc['title'] ?? '').toString().toLowerCase();
      final riskLevel = (doc['riskLevel'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          riskLevel.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedCategory == 'High Risk') {
        return riskLevel.contains('high') || riskLevel.contains('red');
      } else if (_selectedCategory == 'Caution') {
        return riskLevel.contains('medium') || riskLevel.contains('yellow') || riskLevel.contains('caution');
      } else if (_selectedCategory == 'Compliant') {
        return riskLevel.contains('low') || riskLevel.contains('green') || riskLevel.contains('compliant');
      }

      return true;
    }).toList();
  }

  int get _redCount => _allDocs.where((d) {
        final r = (d['riskLevel'] ?? '').toString().toLowerCase();
        return r.contains('high') || r.contains('red');
      }).length;

  int get _yellowCount => _allDocs.where((d) {
        final r = (d['riskLevel'] ?? '').toString().toLowerCase();
        return r.contains('medium') || r.contains('yellow') || r.contains('caution');
      }).length;

  int get _greenCount => _allDocs.where((d) {
        final r = (d['riskLevel'] ?? '').toString().toLowerCase();
        return r.contains('low') || r.contains('green') || r.contains('compliant');
      }).length;

  String _formatRelativeTime(dynamic dateVal) {
    if (dateVal == null) return 'Recently';
    try {
      final date = DateTime.parse(dateVal.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  void _openAnalysis(Map<String, dynamic> doc) {
    final title = (doc['title'] ?? 'Scanned Agreement').toString();
    final originalText = (doc['originalText'] ?? '').toString();
    final analysis = (doc['analysis'] as List<dynamic>?) ?? [];
    final sourceType = (doc['sourceType'] as String?) ?? 'PDF Document';
    final fileData = doc['fileData'] as String?;
    final mimeType = doc['mimeType'] as String?;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AnalysisScreen(
          documentTitle: title,
          originalText: originalText,
          analysis: analysis,
          sourceType: sourceType,
          fileData: fileData,
          mimeType: mimeType,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final displayDocs = _filteredDocs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ScanScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan New Document'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDocuments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Summary Card Banner ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_copy_rounded, color: Color(0xFF2563EB), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Legal Repository',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_allDocs.length} total property agreements analyzed',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStatPill('Total', '${_allDocs.length}', const Color(0xFF3B82F6), isDark),
                      _buildSummaryStatPill('High Risk', '$_redCount', const Color(0xFFEF4444), isDark),
                      _buildSummaryStatPill('Caution', '$_yellowCount', const Color(0xFFF59E0B), isDark),
                      _buildSummaryStatPill('Compliant', '$_greenCount', const Color(0xFF10B981), isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Search Bar ---
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search documents by title or risk...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ),
            ),
            const SizedBox(height: 12),

            // --- Category Filter Chips ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', _allDocs.length, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('High Risk', _redCount, isDark, activeColor: const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Caution', _yellowCount, isDark, activeColor: const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Compliant', _greenCount, isDark, activeColor: const Color(0xFF10B981)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Documents List ---
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayDocs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No documents matching "$_searchQuery"'
                          : 'No documents in this category',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan a new agreement or document to get an instant AI legal risk report.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayDocs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = displayDocs[index] as Map<String, dynamic>;
                  final title = (doc['title'] ?? 'Scanned Agreement').toString();
                  final riskLevel = (doc['riskLevel'] ?? 'Low Risk').toString();
                  final docSize = (doc['docSize'] ?? '1.2 MB').toString();
                  final createdAt = doc['createdAt'];
                  final dateText = 'Scanned ${_formatRelativeTime(createdAt)}';
                  final sourceType = (doc['sourceType'] as String?) ?? (title.toLowerCase().endsWith('.pdf') ? 'PDF Document' : 'Document');

                  Color badgeColor = const Color(0xFF10B981);
                  IconData badgeIcon = Icons.check_circle_rounded;
                  final rLower = riskLevel.toLowerCase();

                  if (rLower.contains('high') || rLower.contains('red')) {
                    badgeColor = const Color(0xFFEF4444);
                    badgeIcon = Icons.error_outline_rounded;
                  } else if (rLower.contains('medium') || rLower.contains('yellow') || rLower.contains('caution')) {
                    badgeColor = const Color(0xFFF59E0B);
                    badgeIcon = Icons.warning_amber_rounded;
                  }

                  IconData formatIcon = Icons.article_rounded;
                  Color formatColor = const Color(0xFF2563EB);

                  final sLower = sourceType.toLowerCase();
                  if (sLower.contains('photo') || sLower.contains('image')) {
                    formatIcon = Icons.image_rounded;
                    formatColor = const Color(0xFF8B5CF6);
                  } else if (sLower.contains('text')) {
                    formatIcon = Icons.notes_rounded;
                    formatColor = const Color(0xFF0EA5E9);
                  } else if (sLower.contains('pdf')) {
                    formatIcon = Icons.picture_as_pdf_rounded;
                    formatColor = const Color(0xFFEF4444);
                  }

                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openAnalysis(doc),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: formatColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                formatIcon,
                                color: formatColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: formatColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sourceType,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: formatColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        '• $docSize',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon, size: 12, color: badgeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    riskLevel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatPill(String label, String count, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int count, bool isDark, {Color activeColor = const Color(0xFF2563EB)}) {
    final isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = label);
        }
      },
      selectedColor: activeColor.withValues(alpha: 0.2),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? activeColor
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? activeColor
            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
    );
  }
}
