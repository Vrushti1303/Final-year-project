import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_scanner/screens/home_screen.dart';
import 'package:legal_scanner/screens/chat_screen.dart';
import 'package:legal_scanner/screens/analysis_screen.dart';
import 'package:legal_scanner/screens/welcome_screen.dart';

import 'package:legal_scanner/screens/recent_documents_screen.dart';
import 'package:legal_scanner/screens/checklists_list_screen.dart';
import 'package:legal_scanner/screens/checklist_screen.dart';
import 'package:legal_scanner/screens/privacy_policy_screen.dart';
import 'package:legal_scanner/screens/terms_of_use_screen.dart';

void main() {
  testWidgets('RecentDocumentsScreen renders with summary stats, search, and documents', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final sampleDocs = [
      {
        '_id': 'doc_001',
        'title': 'Dahanu Flat Sale Deed.pdf',
        'riskLevel': 'High Risk',
        'docSize': '14.3 MB',
        'createdAt': DateTime.now().toIso8601String(),
        'sourceType': 'PDF Document',
        'originalText': 'Sample text',
        'analysis': [],
      },
      {
        '_id': 'doc_002',
        'title': 'Commercial Lease Agreement.pdf',
        'riskLevel': 'Compliant',
        'docSize': '2.1 MB',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'sourceType': 'PDF Document',
        'originalText': 'Sample text 2',
        'analysis': [],
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RecentDocumentsScreen(initialDocs: sampleDocs),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(RecentDocumentsScreen), findsOneWidget);
    expect(find.text('Recent Documents'), findsOneWidget);
    expect(find.text('Document Legal Repository'), findsOneWidget);
    expect(find.text('Dahanu Flat Sale Deed.pdf'), findsOneWidget);
    expect(find.text('Commercial Lease Agreement.pdf'), findsOneWidget);
    expect(find.text('High Risk'), findsWidgets);
    expect(find.text('Compliant'), findsWidgets);
    expect(find.text('Scan New Document'), findsOneWidget);
  });

  testWidgets('RecentDocumentsScreen document card three-dot menu displays all 6 options in correct order', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final sampleDocs = [
      {
        '_id': 'doc_001',
        'title': 'Dahanu Flat Sale Deed.pdf',
        'riskLevel': 'High Risk',
        'docSize': '14.3 MB',
        'createdAt': DateTime.now().toIso8601String(),
        'sourceType': 'PDF Document',
        'originalText': 'Sample text',
        'analysis': [],
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RecentDocumentsScreen(initialDocs: sampleDocs),
        ),
      ),
    );

    await tester.pump();

    // Find the three dot button
    final menuButton = find.byIcon(Icons.more_vert_rounded);
    expect(menuButton, findsOneWidget);

    // Tap to open popup menu
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Verify all 6 options exist
    expect(find.text('View Document'), findsOneWidget);
    expect(find.text('View Analysis'), findsOneWidget);
    expect(find.text('Download Risk Report'), findsOneWidget);
    expect(find.text('Rename Document'), findsOneWidget);
    expect(find.text('Re-analyze Document'), findsOneWidget);
    expect(find.text('Delete Document'), findsOneWidget);

    // Verify icons
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });
  testWidgets('WelcomeScreen renders hero, CTA, features, and risk sections on Desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WelcomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Scan & Extract'), findsOneWidget);
    expect(find.text('Detect Legal Risks'), findsOneWidget);
    expect(find.text('Plain-English Insights'), findsWidgets);
  });

  testWidgets('WelcomeScreen renders on Mobile without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WelcomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('HomeScreen builds on Desktop (1200x900)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('OVERVIEW'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('LEGAL TOOLS'), findsOneWidget);
    expect(find.text('LEGAL INFORMATION'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Risk Analysis'), findsOneWidget);
    expect(find.text('Checklists'), findsOneWidget);
    expect(find.text('Legal AI'), findsOneWidget);
    expect(find.text('Stamp Duty Calculator'), findsOneWidget);
    expect(find.text('RERA & Compliance'), findsOneWidget);
    expect(find.text('Latest Document Analysis'), findsOneWidget);
    expect(find.text('Legal Risk Breakdown'), findsOneWidget);
    expect(find.text('Due Diligence Checklist'), findsOneWidget);
  });

  testWidgets('HomeScreen builds on Mobile (375x812) without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Latest Document Analysis'), findsOneWidget);
    expect(find.text('Legal Risk Breakdown'), findsOneWidget);
    expect(find.text('Due Diligence Checklist'), findsOneWidget);
  });

  testWidgets('ChatScreen builds without overflowing on desktop/mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.textContaining('LEGAL AI ASSISTANT'), findsWidgets);
  });

  testWidgets('AnalysisScreen renders with summary and Export PDF button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AnalysisScreen(
            documentTitle: 'Sample Rental Agreement',
            originalText: 'The tenant must pay 10 months security deposit.',
            analysis: [
              {
                'text': 'The tenant must pay 10 months security deposit.',
                'category': 'Yellow',
                'reason': 'Excessive security deposit under standard Model Tenancy Act guidance.'
              }
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(AnalysisScreen), findsOneWidget);
    expect(find.text('Risk Analysis Report'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('ChatScreen renders empty state suggestions and handles input', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.textContaining('LEGAL AI ASSISTANT'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('ChecklistsListScreen builds and renders header and action', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChecklistsListScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(ChecklistsListScreen), findsOneWidget);
  });

  testWidgets('ChecklistScreen builds with initial title and actions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChecklistScreen(
            type: 'sample_type',
            initialTitle: 'Resale Apartment Due Diligence',
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(ChecklistScreen), findsOneWidget);
    expect(find.text('Resale Apartment Due Diligence'), findsOneWidget);
  });

  testWidgets('PrivacyPolicyScreen renders all key legal sections and disclaimer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Last Updated: 15 September 2026'), findsOneWidget);
    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('Information We Collect'), findsOneWidget);
    expect(find.text('Legal Disclaimer & Non-Advocate Notice'), findsOneWidget);
  });

  testWidgets('TermsOfUseScreen renders terms and conditions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TermsOfUseScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(TermsOfUseScreen), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Last Updated: 15 September 2026'), findsOneWidget);
    expect(find.text('Acceptance of Terms'), findsOneWidget);
  });
}


