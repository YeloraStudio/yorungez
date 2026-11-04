import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../catalogue/presentation/catalogue_screen.dart';
import '../catalogue/presentation/object_screen.dart';
import '../core/presentation/service_screen.dart';
import '../core/presentation/sources_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import '../sky/presentation/sky_screen.dart';

final routerProvider = Provider((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SkyScreen()),
      GoRoute(
        path: '/catalogue',
        builder: (_, state) => CatalogueScreen(
          pickTarget: state.uri.queryParameters['pick'] == 'true',
        ),
      ),
      GoRoute(
        path: '/objects/:id',
        builder: (_, state) => ObjectScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/connection', builder: (_, _) => const ServiceScreen()),
      GoRoute(path: '/sources', builder: (_, _) => const SourcesScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class YorungezApp extends ConsumerWidget {
  const YorungezApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'yorungez',
    debugShowCheckedModeBanner: false,
    locale: ref.watch(localeProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: ref.watch(routerProvider),
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF17191C),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC9B6A6),
        onPrimary: Color(0xFF17191C),
        secondary: Color(0xFF8B2333),
        surface: Color(0xFF3C3F43),
        onSurface: Color(0xFFF7F1E6),
        error: Color(0xFFFFB4AB),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF17191C)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF272A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC9B6A6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8B2333),
          foregroundColor: const Color(0xFFF7F1E6),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
  );
}
