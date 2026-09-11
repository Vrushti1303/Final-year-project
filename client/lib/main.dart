import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Gracefully handle UI errors without crashing the entire web canvas to a blank white screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded, color: Color(0xFF91ADCD), size: 28),
              const SizedBox(height: 8),
              Text(
                'Temporarily adjusting layout...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: LawBuddyApp()));
}

class LawBuddyApp extends ConsumerWidget {
  const LawBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'LawBuddy',
      locale: Locale(currentLocale.code),
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF8EE), // Warm Ivory
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF91ADCD), // Primary Chambray Blue
          secondary: Color(0xFF92764B), // Warm Taupe
          tertiary: Color(0xFFFFDF8C), // Soft Golden Yellow
          surface: Color(0xFFF7F1D0), // Soft Cream Card Fill
          surfaceContainerHighest: Color(0xFFF4EFE0), // Secondary Cream Fill
          error: Color(0xFFC94A4A), // Soft Red Status
          onPrimary: Colors.white,
          onSurface: Color(0xFF244A78), // Deep Navy Primary Text
          onSurfaceVariant: Color(0xFF63748A), // Secondary Navy Text
          outline: Color(0xFFE4DDD0), // Subtle Taupe Border
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: const TextStyle(color: Color(0xFF244A78), fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: const TextStyle(color: Color(0xFF244A78), fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleMedium: const TextStyle(color: Color(0xFF244A78), fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Color(0xFF244A78), fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(color: Color(0xFF63748A), fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF244A78),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F1D0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4DDD0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4DDD0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF91ADCD), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC94A4A)),
          ),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF63748A)),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8FA0B5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF244A78), // Deep Navy or Chambray Blue
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: const Color(0xFF244A78).withValues(alpha: 0.2),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF244A78),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: const BorderSide(color: Color(0xFF91ADCD)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF7F1D0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4DDD0)),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF162B43), // Deep Navy Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5F7895), // Muted Steel Blue
          secondary: Color(0xFF4A392A), // Deep Cocoa
          tertiary: Color(0xFFC5A85E), // Muted Gold
          surface: Color(0xFF2B2920), // Deep Espresso / Warm Dark Surface
          surfaceContainerHighest: Color(0xFF1E334D), // Elevated Navy Surface
          error: Color(0xFFC94A4A), // Soft Red Status
          onPrimary: Color(0xFFE8E1D0),
          onSurface: Color(0xFFE8E1D0), // Warm Ivory Primary Text
          onSurfaceVariant: Color(0xFFA5B4C7), // Muted Steel Text
          outline: Color(0xFF334356), // Subtle Dark Border
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: const TextStyle(color: Color(0xFFE8E1D0), fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: const TextStyle(color: Color(0xFFE8E1D0), fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleMedium: const TextStyle(color: Color(0xFFE8E1D0), fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Color(0xFFE8E1D0), fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(color: Color(0xFFA5B4C7), fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFE8E1D0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2B2920),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334356)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334356)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5F7895), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC94A4A)),
          ),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFA5B4C7)),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF6E8299)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F7895), // Muted Steel Blue
            foregroundColor: const Color(0xFFE8E1D0),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: const Color(0xFF5F7895).withValues(alpha: 0.25),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE8E1D0),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: const BorderSide(color: Color(0xFF5F7895)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2B2920),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334356)),
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
