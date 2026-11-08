import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../catalogue/presentation/catalogue_screen.dart';
import '../catalogue/presentation/object_screen.dart';
import '../catalogue/presentation/glossary_screen.dart';
import '../core/presentation/service_screen.dart';
import '../core/presentation/sources_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import '../sky/presentation/sky_screen.dart';
import '../account/account_screen.dart';
import '../account/notebook_screen.dart';
import '../planning/planning_screen.dart';
import '../planning/planning_controls.dart';
import '../planning/reminder_screen.dart';

final routerProvider = Provider((ref) {
  final router = GoRouter(
    observers: [skyRouteObserver],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            SkyScreen(initialObserver: ref.read(initialSkyObserverProvider)),
      ),
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
      GoRoute(
        path: '/glossary',
        builder: (_, state) =>
            GlossaryScreen(termId: state.uri.queryParameters['term']),
      ),
      GoRoute(path: '/connection', builder: (_, _) => const ServiceScreen()),
      GoRoute(path: '/sources', builder: (_, _) => const SourcesScreen()),
      GoRoute(
        path: '/account',
        builder: (_, state) => AccountScreen(
          initialMode: state.uri.queryParameters['mode'] ?? 'login',
        ),
      ),
      GoRoute(path: '/notebook', builder: (_, _) => const NotebookScreen()),
      GoRoute(path: '/tonight', builder: (_, _) => const TonightScreen()),
      GoRoute(
        path: '/calendar',
        builder: (_, _) => const EventCalendarScreen(),
      ),
      GoRoute(path: '/reminders', builder: (_, _) => const ReminderScreen()),
      GoRoute(path: '/time-zone', builder: (_, _) => const TimeZoneScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class YorungezApp extends ConsumerStatefulWidget {
  const YorungezApp({super.key});
  @override
  ConsumerState<YorungezApp> createState() => _YorungezAppState();
}

class _YorungezAppState extends ConsumerState<YorungezApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      if (!mounted) return;
      await ref.read(localeProvider.notifier).restore();
      if (mounted) await ref.read(accountSessionProvider).initialise();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(accountSessionProvider).retry();
      ref.read(planningZoneProvider.notifier).refreshDevice();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Yorungez',
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: const Color(0xFF8B2333),
          selectedForegroundColor: const Color(0xFFF7F1E6),
          foregroundColor: const Color(0xFFF7F1E6),
        ),
      ),
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
