import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/app/app.dart';
import 'package:yorungez/app/providers.dart';
import 'package:yorungez/catalogue/data/catalogue_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalogue catalogue;
  setUpAll(() async => catalogue = await CatalogueRepository().load());

  testWidgets(
    'offline search opens M31 with source and reference-epoch context',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [catalogueProvider.overrideWith((ref) async => catalogue)],
      );
      addTearDown(container.dispose);
      container.read(routerProvider).go('/catalogue');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const YorungezApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sky catalogue'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'M31');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Andromeda Galaxy'));
      await tester.pumpAndSettle();
      expect(find.text('Andromeda Galaxy'), findsOneWidget);
      expect(find.textContaining('Lviatour'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(find.text('Catalogue coordinates · J2000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Turkish UI at narrow large-text size keeps menu and language selection usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [catalogueProvider.overrideWith((ref) async => catalogue)],
      );
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).select('tr');
      container.read(routerProvider).go('/catalogue');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const YorungezApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gökyüzü kataloğu'), findsOneWidget);
      await tester.tap(find.byTooltip('Menüyü aç'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<String>),
        180,
        scrollable: find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Dil'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(container.read(localeProvider).languageCode, 'en');
      expect(tester.takeException(), isNull);
    },
  );
}
