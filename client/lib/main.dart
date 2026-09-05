import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: LegalScannerApp()));
}

class LegalScannerApp extends ConsumerWidget {
  const LegalScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Legal Document Scanner',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Light Background
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2563EB), // Professional Royal Blue
          secondary: Color(0xFF10B981), // Emerald Green / Safe Status
          tertiary: Color(0xFFF59E0B), // Amber / Warning Status
          surface: Color(0xFFFFFFFF), // Main Cards
          surfaceContainerHighest: Color(0xFFF1F5F9), // Hover / Secondary Cards
          error: Color(0xFFEF4444), // Danger / Risk Status
          onPrimary: Colors.white,
          onSurface: Color(0xFF0F172A), // Deep Navy Text
          onSurfaceVariant: Color(0xFF64748B), // Slate Secondary Text
          outline: Color(0xFFE2E8F0), // Subtle Borders
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleMedium: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0F172A),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.25),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: Color(0xFF2563EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Navy Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6), // Royal Blue Accent
          secondary: Color(0xFF10B981), // Emerald Safe Status
          tertiary: Color(0xFFF59E0B), // Amber Warning
          surface: Color(0xFF1E293B), // Card Surface
          surfaceContainerHighest: Color(0xFF263549), // Secondary Card / Hover
          error: Color(0xFFEF4444), // Danger Status
          onPrimary: Colors.white,
          onSurface: Color(0xFFF8FAFC), // Crisp Off-white Text
          onSurfaceVariant: Color(0xFF94A3B8), // Muted Slate Text
          outline: Color(0xFF334155), // Subtle Border
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleMedium: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF8FAFC),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: Color(0xFF3B82F6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const AuthGate(),
    );
  }
}


class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const WelcomeScreen();
    }
  }
}
