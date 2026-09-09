import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/welcome_screen.dart';

class UserProfileButton extends ConsumerStatefulWidget {
  const UserProfileButton({super.key});

  @override
  ConsumerState<UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends ConsumerState<UserProfileButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;

    final String userName = (user?.fullName.isNotEmpty == true)
        ? user!.fullName
        : 'User';
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => showSettingsDialog(context, ref),
        child: Tooltip(
          message: '$userName (Settings)',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered ? colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showSettingsDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (dialogContext, ref, _) {
          final colorScheme = Theme.of(dialogContext).colorScheme;
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
          final authState = ref.watch(authProvider);
          final user = authState.user;
          final currentLanguage = ref.watch(localeProvider);
          final currentThemeMode = ref.watch(themeProvider);

          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.outline),
            ),
            title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.settings_outlined, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              currentLanguage == AppLanguage.hindi ? 'सेटिंग्स' : 'Settings',
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E334D) : const Color(0xFFF4EFE0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'U',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (user?.fullName != null && user!.fullName.isNotEmpty) ? user.fullName : 'LawBuddy User',
                              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (user?.email != null && user!.email!.isNotEmpty) ? user.email! : 'user@lawbuddy.in',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Theme / Appearance Control
                Text(
                  currentLanguage == AppLanguage.hindi ? 'थीम' : 'Theme',
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  currentLanguage == AppLanguage.hindi ? 'चुनें कि LawBuddy कैसा दिखे' : 'Choose how LawBuddy looks',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E334D) : const Color(0xFFF4EFE0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      // Light
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                          },
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: currentThemeMode == ThemeMode.light ? colorScheme.primary : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.light_mode_rounded,
                                  size: 15,
                                  color: currentThemeMode == ThemeMode.light ? Colors.white : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currentLanguage == AppLanguage.hindi ? 'लाइट' : 'Light',
                                  style: TextStyle(
                                    color: currentThemeMode == ThemeMode.light ? Colors.white : colorScheme.onSurface,
                                    fontWeight: currentThemeMode == ThemeMode.light ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Dark
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: currentThemeMode == ThemeMode.dark ? colorScheme.primary : Colors.transparent,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dark_mode_rounded,
                                  size: 15,
                                  color: currentThemeMode == ThemeMode.dark ? Colors.white : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currentLanguage == AppLanguage.hindi ? 'डार्क' : 'Dark',
                                  style: TextStyle(
                                    color: currentThemeMode == ThemeMode.dark ? Colors.white : colorScheme.onSurface,
                                    fontWeight: currentThemeMode == ThemeMode.dark ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // System
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                          },
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: currentThemeMode == ThemeMode.system ? colorScheme.primary : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.brightness_auto_rounded,
                                  size: 15,
                                  color: currentThemeMode == ThemeMode.system ? Colors.white : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  currentLanguage == AppLanguage.hindi ? 'सिस्टम' : 'System',
                                  style: TextStyle(
                                    color: currentThemeMode == ThemeMode.system ? Colors.white : colorScheme.onSurface,
                                    fontWeight: currentThemeMode == ThemeMode.system ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Language Option inside Settings
                Text(
                  currentLanguage == AppLanguage.hindi ? 'भाषा' : 'Language',
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E334D) : const Color(0xFFF4EFE0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(localeProvider.notifier).setLanguage(AppLanguage.english);
                          },
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: currentLanguage == AppLanguage.english ? colorScheme.primary : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'English',
                              style: TextStyle(
                                color: currentLanguage == AppLanguage.english ? Colors.white : colorScheme.onSurface,
                                fontWeight: currentLanguage == AppLanguage.english ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(localeProvider.notifier).setLanguage(AppLanguage.hindi);
                          },
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: currentLanguage == AppLanguage.hindi ? colorScheme.primary : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'हिंदी',
                              style: TextStyle(
                                color: currentLanguage == AppLanguage.hindi ? Colors.white : colorScheme.onSurface,
                                fontWeight: currentLanguage == AppLanguage.hindi ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              currentLanguage == AppLanguage.hindi ? 'बंद करें' : 'Close',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (authState.user != null || authState.status == AuthStatus.authenticated)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(authProvider.notifier).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(currentLanguage == AppLanguage.hindi ? 'साइन आउट' : 'Sign Out'),
            ),
        ],
      );
        },
      );
    },
  );
}
