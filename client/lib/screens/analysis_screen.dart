import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/theme_toggle_button.dart';

class AnalysisScreen extends StatefulWidget {
  final String originalText;
  final List<dynamic> analysis;
  final String? documentTitle;

  const AnalysisScreen({
    super.key,
    required this.originalText,
    required this.analysis,
    this.documentTitle,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isExplaining = false;
  bool _isExportingPdf = false;

  Color _getColorForCategory(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (category.toLowerCase().trim()) {
      case 'green':
        return isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFECFDF5);
      case 'yellow':
        return isDark ? Colors.orange.withValues(alpha: 0.15) : const Color(0xFFFFFBEB);
      case 'red':
        return isDark ? Colors.red.withValues(alpha: 0.15) : const Color(0xFFFEF2F2);
      default:
        return isDark ? Colors.grey.withValues(alpha: 0.15) : const Color(0xFFF1F5F9);
    }
  }

  Color _getBorderColor(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (category.toLowerCase().trim()) {
      case 'green':
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      case 'yellow':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case 'red':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      final docTitle = widget.documentTitle ??
          (widget.originalText.trim().split('\n').first.replaceAll(RegExp(r'[#*_-]'), '').trim());

      await PdfExportService.exportAnalysisPdf(
        documentTitle: docTitle.isNotEmpty ? docTitle : 'Property Legal Analysis',
        originalText: widget.originalText,
        analysis: widget.analysis,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Legal Risk Assessment Report exported successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExplaining = false);
    }
  }

  void _showExplanationModal(String snippet, String explanation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Plain English Translation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '"$snippet"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                explanation,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Got it'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate breakdown
    int redCount = 0;
    int yellowCount = 0;
    int greenCount = 0;
    for (final item in widget.analysis) {
      final cat = (item['category'] ?? '').toString().toLowerCase();
      if (cat.contains('red')) {
        redCount++;
      } else if (cat.contains('yellow')) {
        yellowCount++;
      } else if (cat.contains('green')) {
        greenCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Export PDF Report',
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF2563EB)),
            onPressed: _isExportingPdf ? null : _exportPdf,
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Executive Summary Banner
              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              redCount > 0
                                  ? Icons.warning_amber_rounded
                                  : (yellowCount > 0 ? Icons.info_outline : Icons.verified_user_outlined),
                              color: redCount > 0
                                  ? const Color(0xFFDC2626)
                                  : (yellowCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              redCount > 0
                                  ? 'High Legal Risk Detected'
                                  : (yellowCount > 0 ? 'Moderate Caution Advised' : 'Standard / Low Risk'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: redCount > 0
                                    ? const Color(0xFFDC2626)
                                    : (yellowCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isExportingPdf ? null : _exportPdf,
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Stats Pill Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatPill('🔴 $redCount High Risk', const Color(0xFFFEF2F2), const Color(0xFFDC2626), isDark),
                        _buildStatPill('🟡 $yellowCount Caution', const Color(0xFFFFFBEB), const Color(0xFFD97706), isDark),
                        _buildStatPill('🟢 $greenCount Compliant', const Color(0xFFECFDF5), const Color(0xFF16A34A), isDark),
                        _buildStatPill('${widget.analysis.length} Clauses Total', const Color(0xFFF1F5F9), const Color(0xFF64748B), isDark),
                      ],
                    ),
                  ],
                ),
              ),

              // Clause Analysis Section Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.rule_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Analyzed Clauses & Explanations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Clauses List
              ...List.generate(widget.analysis.length, (index) {
                final item = widget.analysis[index];
                final category = (item['category'] ?? 'Standard').toString();
                final text = (item['text'] ?? '').toString();
                final reason = (item['reason'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: _getBorderColor(context, category), width: 1.5),
                  ),
                  color: _getColorForCategory(context, category),
                  child: InkWell(
                    onTap: () => _explainSnippet(text),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getBorderColor(context, category).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _getBorderColor(context, category),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.touch_app_outlined,
                                      size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap to explain',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Risk Rationale: $reason',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
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
              }),
            ],
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
                        Text('Simplifying legal jargon with AI...'),
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

  Widget _buildStatPill(String label, Color lightBg, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? textColor.withValues(alpha: 0.15) : lightBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? textColor : textColor,
        ),
      ),
    );
  }
}

