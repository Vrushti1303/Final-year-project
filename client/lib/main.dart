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
          primary: Color(0xFF2563EB), // Royal Blue
          secondary: Color(0xFF10B981), // Emerald Green
          tertiary: Color(0xFFF59E0B), // Amber Accent
          surface: Color(0xFFFFFFFF), // Cards
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSurface: Color(0xFF0F172A), // Primary Text
          onSurfaceVariant: Color(0xFF64748B), // Secondary Text
          outline: Color(0xFFE2E8F0), // Borders
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0F172A),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2, // Soft shadow in Light Mode
            shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: Color(0xFF2563EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB), // Royal Blue
          secondary: Color(0xFF10B981), // Emerald Green
          tertiary: Color(0xFFF59E0B), // Amber Accent
          surface: Color(0xFF1E293B), // Surface Cards
          surfaceContainerHighest: Color(0xFF334155), // Elevated Cards
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSurface: Color(0xFFF8FAFC), // Primary Text
          onSurfaceVariant: Color(0xFFCBD5E1), // Secondary Text
          outline: Color(0xFF475569), // Borders
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF8FAFC),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF475569)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF475569)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1)),
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4, // Slight elevation in Dark Mode
            shadowColor: Colors.black.withValues(alpha: 0.5),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: Color(0xFF2563EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
