import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_scanner/screens/home_screen.dart';
import 'package:legal_scanner/screens/chat_screen.dart';

void main() {
  testWidgets('HomeScreen builds on Desktop (1200x900)', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1200, 900);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

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

  testWidgets('HomeScreen builds on Tablet (800x900)', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 900);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

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
  });

  testWidgets('HomeScreen builds on Mobile (400x800)', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

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
  });

  testWidgets('ChatScreen builds on Desktop (1200x900)', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1200, 900);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('How can I help with your legal questions?'), findsOneWidget);
    expect(find.text('Review Agreement Clauses'), findsOneWidget);
    expect(find.text('RERA Compliance & Rights'), findsOneWidget);
  });

  testWidgets('ChatScreen builds on Mobile (400x800)', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Review Agreement Clauses'), findsOneWidget);
  });
}
