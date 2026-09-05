import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'file_saver/save_file.dart';

class PdfExportService {
  /// Generates and downloads/saves a professional Legal Risk Assessment PDF Report
  static Future<void> exportAnalysisPdf({
    required String documentTitle,
    required String originalText,
    required List<dynamic> analysis,
  }) async {
    // 1. Create a PDF document
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 36; // 0.5 inch margins

    // 2. Count risk categories
    int redCount = 0;
    int yellowCount = 0;
    int greenCount = 0;
    for (final item in analysis) {
      final cat = (item['category'] ?? '').toString().toLowerCase();
      if (cat.contains('red')) {
        redCount++;
      } else if (cat.contains('yellow')) {
        yellowCount++;
      } else if (cat.contains('green')) {
        greenCount++;
      }
    }

    String overallRisk = 'Low Risk';
    PdfColor overallColor = PdfColor(22, 163, 74); // Green
    if (redCount > 0) {
      overallRisk = 'High Risk';
      overallColor = PdfColor(220, 38, 38); // Red
    } else if (yellowCount > 0) {
      overallRisk = 'Medium Risk';
      overallColor = PdfColor(217, 119, 6); // Orange/Amber
    }

    final now = DateTime.now();
    final dateFormatted = '${now.day}/${now.month}/${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 3. Add first page
    PdfPage page = document.pages.add();
    final Size pageSize = page.getClientSize();
    double currentY = 0;

    // --- Header Section ---
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final PdfFont subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont sectionTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
    final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5);
    final PdfFont italicFont = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.italic);

    // Top Brand Bar
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(15, 23, 42)), // Slate 900
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 42),
    );
    page.graphics.drawString(
      'LEGALTECH REAL ESTATE AI ASSISTANT',
      PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(12, currentY + 14, pageSize.width - 24, 20),
    );
    page.graphics.drawString(
      'CONFIDENTIAL REPORT',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(148, 163, 184)),
      bounds: Rect.fromLTWH(pageSize.width - 160, currentY + 16, 150, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    currentY += 56;

    // Report Title
    page.graphics.drawString(
      'Legal Risk Assessment Report',
      headerFont,
      brush: PdfSolidBrush(PdfColor(15, 23, 42)),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 24),
    );
    currentY += 26;

    // Document Metadata Subtitle
    final cleanTitle = documentTitle.isNotEmpty ? documentTitle : 'Property Agreement';
    page.graphics.drawString(
      'Document: $cleanTitle   |   Generated: $dateFormatted',
      subHeaderFont,
      brush: PdfSolidBrush(PdfColor(100, 116, 139)),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 16),
    );
    currentY += 24;

    // Divider
    page.graphics.drawLine(
      PdfPen(PdfColor(226, 232, 240), width: 1),
      Offset(0, currentY),
      Offset(pageSize.width, currentY),
    );
    currentY += 16;

    // --- Executive Summary Box ---
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 250, 252)),
      pen: PdfPen(PdfColor(203, 213, 225), width: 1),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 68),
    );

    // Overall Risk Badge
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(overallColor),
      bounds: Rect.fromLTWH(12, currentY + 14, 110, 24),
    );
    page.graphics.drawString(
      overallRisk.toUpperCase(),
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(12, currentY + 20, 110, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Summary Stats
    final summaryText = 'Total Clauses Analyzed: ${analysis.length}   |   '
        'High Risk (Red): $redCount   |   '
        'Warnings (Yellow): $yellowCount   |   '
        'Standard (Green): $greenCount';

    page.graphics.drawString(
      'Executive Assessment',
      PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(15, 23, 42)),
      bounds: Rect.fromLTWH(134, currentY + 12, pageSize.width - 146, 16),
    );
    page.graphics.drawString(
      summaryText,
      bodyFont,
      brush: PdfSolidBrush(PdfColor(71, 85, 105)),
      bounds: Rect.fromLTWH(134, currentY + 34, pageSize.width - 146, 20),
    );

    currentY += 84;

    // Section Header: Detailed Clause Analysis
    page.graphics.drawString(
      'Detailed Clause Analysis & RERA Compliance Breakdown',
      sectionTitleFont,
      brush: PdfSolidBrush(PdfColor(15, 23, 42)),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20),
    );
    currentY += 24;

    // --- Dynamic Clause Elements with Layout Pagination ---
    final PdfLayoutFormat layoutFormat = PdfLayoutFormat(
      layoutType: PdfLayoutType.paginate,
    );

    for (int i = 0; i < analysis.length; i++) {
      final item = analysis[i];
      final String category = (item['category'] ?? 'Standard').toString();
      final String clauseText = (item['text'] ?? '').toString().trim();
      final String reason = (item['reason'] ?? '').toString().trim();

      String label = 'STANDARD CLAUSE';
      if (category.toLowerCase().contains('red')) {
        label = 'HIGH RISK / NON-COMPLIANT';
      } else if (category.toLowerCase().contains('yellow')) {
        label = 'CAUTION / MISSING SAFEGUARD';
      }

      // Clause Title & Badge String
      final String blockText = 'Clause ${i + 1}: [$label]\n'
          'Original Text:\n"$clauseText"\n\n'
          'AI Assessment & Risk Rationale:\n$reason\n';

      final PdfTextElement element = PdfTextElement(
        text: blockText,
        font: bodyFont,
        brush: PdfSolidBrush(PdfColor(30, 41, 59)),
        format: PdfStringFormat(lineSpacing: 3),
      );

      // Render block
      final PdfLayoutResult? result = element.draw(
        page: page,
        bounds: Rect.fromLTWH(8, currentY, pageSize.width - 16, pageSize.height - currentY - 40),
        format: layoutFormat,
      );

      if (result != null) {
        page = result.page;
        currentY = result.bounds.bottom + 16;
      } else {
        currentY += 60;
      }
    }

    // --- Footer / Disclaimer Section ---
    const String disclaimer =
        'Disclaimer: This report is generated by an Artificial Intelligence model for preliminary advisory & negotiation guidance only. '
        'It does not constitute formal legal representation under the Advocates Act, 1961. Always consult a registered property advocate for legal execution.';

    final PdfTextElement disclaimerElement = PdfTextElement(
      text: disclaimer,
      font: italicFont,
      brush: PdfSolidBrush(PdfColor(148, 163, 184)),
      format: PdfStringFormat(lineSpacing: 2),
    );

    disclaimerElement.draw(
      page: page,
      bounds: Rect.fromLTWH(0, page.getClientSize().height - 35, page.getClientSize().width, 35),
    );

    // 4. Save and export file
    final List<int> bytes = await document.save();
    document.dispose();

    final safeFileName = 'Legal_Risk_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await saveAndLaunchPdf(bytes, safeFileName);
  }
}
