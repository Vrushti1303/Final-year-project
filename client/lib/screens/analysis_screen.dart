import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/user_profile_button.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String originalText;
  final List<dynamic> analysis;
  final String? documentTitle;
  final String? sourceType;
  final String? fileData;
  final String? mimeType;

  const AnalysisScreen({
    super.key,
    required this.originalText,
    required this.analysis,
    this.documentTitle,
    this.sourceType,
    this.fileData,
    this.mimeType,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isExplaining = false;
  bool _isExportingPdf = false;

  Uint8List? _getCleanBytes(String? rawBase64) {
    if (rawBase64 == null || rawBase64.trim().isEmpty) return null;
    try {
      String clean = rawBase64.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last.trim();
      }
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (e) {
      debugPrint('Error decoding base64 data: $e');
      return null;
    }
  }

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
    final tr = ref.read(localeProvider.notifier).translate;
    setState(() => _isExportingPdf = true);
    try {
      final docTitle = widget.documentTitle ??
          (widget.originalText.trim().split('\n').first.replaceAll(RegExp(r'[#*_-]'), '').trim());

      await PdfExportService.exportAnalysisPdf(
        documentTitle: docTitle.isNotEmpty ? docTitle : 'Property Legal Analysis',
        originalText: widget.originalText,
        analysis: widget.analysis,
        sourceType: widget.sourceType ?? 'Document Analysis',
        fileData: widget.fileData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('analysis.pdfSuccess'))),
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
          content: Text(tr('analysis.pdfFailed', {'error': '$e'})),
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
    final tr = ref.read(localeProvider.notifier).translate;
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
                    tr('analysis.plainEnglish'),
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
                  label: Text(tr('analysis.gotIt')),
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
    ref.watch(localeProvider);
    final tr = ref.read(localeProvider.notifier).translate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate breakdown strictly from the analysis array
    int redCount = 0;
    int yellowCount = 0;
    int greenCount = 0;
    for (final item in widget.analysis) {
      final risk = (item['riskLevel'] ?? '').toString().toUpperCase();
      final cat = (item['category'] ?? '').toString().toLowerCase();
      if (risk == 'HIGH_RISK' || cat.contains('red')) {
        redCount++;
      } else if (risk == 'CAUTION' || cat.contains('yellow')) {
        yellowCount++;
      } else if (risk == 'COMPLIANT' || cat.contains('green')) {
        greenCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('analysis.reportTitle'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          UserProfileButton(),
          SizedBox(width: 8),
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
                                  ? tr('analysis.highRiskDetected')
                                  : (yellowCount > 0 ? tr('analysis.moderateCaution') : tr('analysis.standardLowRisk')),
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
                          label: Text(tr('analysis.exportPdf')),
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
                        _buildStatPill(tr('analysis.highRiskCount', {'count': '$redCount'}), const Color(0xFFFEF2F2), const Color(0xFFDC2626), isDark),
                        _buildStatPill(tr('analysis.cautionCount', {'count': '$yellowCount'}), const Color(0xFFFFFBEB), const Color(0xFFD97706), isDark),
                        _buildStatPill(tr('analysis.compliantCount', {'count': '$greenCount'}), const Color(0xFFECFDF5), const Color(0xFF16A34A), isDark),
                        _buildStatPill(tr('analysis.clausesTotal', {'count': '${widget.analysis.length}'}), const Color(0xFFF1F5F9), const Color(0xFF64748B), isDark),
                      ],
                    ),
                  ],
                ),
              ),

              // Source Document & Text Card (Rendered directly on the report page)
              if (widget.originalText.trim().isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _effectiveSourceType == 'Photo Scan'
                                  ? Icons.image_rounded
                                  : (_effectiveSourceType == 'Text Description' ? Icons.notes_rounded : Icons.picture_as_pdf_rounded),
                              color: const Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.documentTitle ?? tr('analysis.sourceDocTitle'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _effectiveSourceType,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr('analysis.originalUploaded'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showDocumentViewerModal(context),
                            icon: const Icon(Icons.open_in_full_rounded, size: 14),
                            label: Text(tr('analysis.expandWindow')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 14),

                      // Inline Photo Preview (if Photo Scan & fileData present)
                      if (widget.fileData != null && widget.fileData!.isNotEmpty && _effectiveSourceType == 'Photo Scan') ...[
                        Builder(builder: (context) {
                          final imgBytes = _getCleanBytes(widget.fileData);
                          if (imgBytes == null) return const SizedBox.shrink();
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 320),
                                  width: double.infinity,
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  child: Image.memory(
                                    imgBytes,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          );
                        }),
                      ],

                      // Inline PDF Document Viewer Preview (if PDF Document & fileData present)
                      if (widget.fileData != null && widget.fileData!.isNotEmpty && _effectiveSourceType == 'PDF Document') ...[
                        Builder(builder: (context) {
                          final pdfBytes = _getCleanBytes(widget.fileData);
                          if (pdfBytes == null) return const SizedBox.shrink();
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 380,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SfPdfViewer.memory(
                                    pdfBytes,
                                    canShowScrollHead: true,
                                    canShowScrollStatus: true,
                                    enableDoubleTapZooming: true,
                                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                      debugPrint('PDF viewer load error: ${details.error}');
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          );
                        }),
                      ],

                      // Show text box only for pure text input scans without an uploaded file/image
                      if (widget.fileData == null || widget.fileData!.isEmpty) ...[
                        Text(
                          tr('analysis.originalContractText'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 220),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              widget.originalText,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                fontFamily: 'monospace',
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Clause Analysis Section Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.rule_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      tr('analysis.analyzedClauses'),
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
                final clauseId = (item['clauseId'] ?? '').toString();
                final category = (item['category'] ?? (item['riskLevel'] == 'HIGH_RISK' ? 'Red' : (item['riskLevel'] == 'CAUTION' ? 'Yellow' : 'Green'))).toString();
                final text = (item['text'] ?? '').toString();
                final reason = (item['reason'] ?? '').toString();
                final reraRefs = (item['reraReferences'] is List) ? (item['reraReferences'] as List).join(', ') : '';

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
                              Row(
                                children: [
                                  if (clauseId.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        clauseId,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.touch_app_outlined,
                                      size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    tr('analysis.tapToExplain'),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('analysis.riskRationale', {'reason': reason}),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (reraRefs.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'RERA Citations: $reraRefs',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ],
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
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(tr('analysis.simplifyingJargon')),
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
          color: textColor,
        ),
      ),
    );
  }

  String get _effectiveSourceType {
    final title = (widget.documentTitle ?? '').toLowerCase();
    final mime = (widget.mimeType ?? '').toLowerCase();
    final type = (widget.sourceType ?? '').toLowerCase();

    if (title.endsWith('.png') || title.endsWith('.jpg') || title.endsWith('.jpeg') || title.endsWith('.webp') || mime.contains('image') || type.contains('photo') || type.contains('image')) {
      return 'Photo Scan';
    }
    if (title.endsWith('.pdf') || mime.contains('pdf') || type.contains('pdf')) {
      return 'PDF Document';
    }
    return widget.sourceType ?? 'Text Description';
  }

  void _showDocumentViewerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.documentTitle ?? 'Property Legal Document';
    final sourceType = _effectiveSourceType;

    Uint8List? rawBytes = _getCleanBytes(widget.fileData);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 920,
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162B43) : const Color(0xFFFBF8EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334356) : const Color(0xFFE4DDD0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // --- Modal Header Bar ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            sourceType == 'Photo Scan'
                                ? Icons.image_rounded
                                : (sourceType == 'Text Description' ? Icons.description_rounded : Icons.picture_as_pdf_rounded),
                            color: const Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      sourceType,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'In-App Document Viewer',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                          tooltip: 'Close Modal',
                        ),
                      ],
                    ),
                  ),

                  // --- In-Modal Tab Bar ---
                  Container(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    child: TabBar(
                      labelColor: const Color(0xFF2563EB),
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: const Color(0xFF2563EB),
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          icon: Icon(
                            sourceType == 'Photo Scan' ? Icons.photo_library_outlined : Icons.picture_as_pdf_outlined,
                            size: 18,
                          ),
                          text: sourceType == 'Photo Scan'
                              ? 'Uploaded Photo View'
                              : (sourceType == 'PDF Document' ? 'Uploaded PDF Document' : 'Document Layout'),
                        ),
                        const Tab(
                          icon: Icon(Icons.text_snippet_outlined, size: 18),
                          text: 'Extracted Original Text',
                        ),
                      ],
                    ),
                  ),

                  // --- Tab View Contents ---
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Uploaded File / PDF / Image Viewer
                        _buildFileViewerTab(context, isDark, sourceType, rawBytes),

                        // Tab 2: Extracted Original Text
                        _buildExtractedTextTab(context, isDark, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileViewerTab(BuildContext context, bool isDark, String sourceType, Uint8List? rawBytes) {
    if (rawBytes != null && rawBytes.isNotEmpty) {
      if (sourceType == 'PDF Document') {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SfPdfViewer.memory(
                rawBytes,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                onDocumentLoadFailed: (details) {
                  debugPrint('PDF viewer load error: ${details.error}');
                },
              ),
            ),
          ),
        );
      } else if (sourceType == 'Photo Scan') {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              width: double.infinity,
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              child: Image.memory(
                rawBytes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      }
    }

    // Interactive Digital Page Layout View (for PDF or Photo documents without base64 or Text Description)
    final bool isPdf = sourceType == 'PDF Document';
    final bool isPhoto = sourceType == 'Photo Scan';

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : (isPhoto ? Icons.camera_alt_rounded : Icons.description_rounded),
                          color: const Color(0xFF2563EB),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPdf ? 'OFFICIAL PDF DOCUMENT RECORD' : (isPhoto ? 'SCANNED PHOTO DOCUMENT RECORD' : 'LEGAL TEXT DOCUMENT RECORD'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              widget.documentTitle ?? 'Property Sale Deed Contract',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_outlined, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text('PAGE 1 OF 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),

                // Formatted Page Body Text
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.originalText,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.65,
                          fontFamily: 'serif',
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtractedTextTab(BuildContext context, bool isDark, ColorScheme colorScheme) {
    final tr = ref.read(localeProvider.notifier).translate;
    final wordCount = widget.originalText.trim().isEmpty ? 0 : widget.originalText.trim().split(RegExp(r'\s+')).length;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Sub-header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('analysis.extractedWords', {'count': '$wordCount'}),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.originalText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('analysis.copySuccess')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: Text(tr('analysis.copyText')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162B43) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334356) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.originalText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurface,
                    ),
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


