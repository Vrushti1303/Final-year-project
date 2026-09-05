import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_scanner/screens/home_screen.dart';
import 'package:legal_scanner/screens/chat_screen.dart';
import 'package:legal_scanner/screens/analysis_screen.dart';
import 'package:legal_scanner/screens/welcome_screen.dart';

void main() {
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
    expect(find.text('Understand in Plain English'), findsOneWidget);
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
    expect(find.text('Recent Documents'), findsOneWidget);
    expect(find.text('Latest Legal Updates'), findsOneWidget);
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
    expect(find.text('Legal AI Assistant'), findsOneWidget);
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
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });
}
