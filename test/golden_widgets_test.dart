import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/core/theme/app_theme.dart';
import 'package:stash/features/links/domain/link_model.dart';
import 'package:stash/features/categories/presentation/providers/category_providers.dart';
import 'package:stash/features/links/presentation/widgets/add_link_sheet.dart';
import 'package:stash/features/links/presentation/widgets/edit_link_sheet.dart';
import 'package:stash/features/links/presentation/widgets/empty_state.dart';
import 'package:stash/features/links/presentation/widgets/link_card.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('EmptyState renders consistently', (tester) async {
    final builder = GoldenBuilder.column()
      ..addScenario(
        'empty state',
        _wrapWithApp(
          const EmptyState(
            title: 'No links yet',
            subtitle: 'Tap the + button to save your first link',
            icon: Icons.bookmark_border_rounded,
          ),
        ),
      )
      ..addScenario(
        'empty state (dark)',
        _wrapWithApp(
          const EmptyState(
            title: 'No links yet',
            subtitle: 'Tap the + button to save your first link',
            icon: Icons.bookmark_border_rounded,
          ),
          theme: AppTheme.darkTheme,
        ),
      );

    await tester.pumpWidgetBuilder(builder.build(), surfaceSize: const Size(400, 600));
    await screenMatchesGolden(tester, 'empty_state');
  });

  testGoldens('LinkCard renders consistently', (tester) async {
    final sampleLink = LinkModel(
      id: 'link-1',
      url: 'https://example.com',
      label: 'Example Site',
      category: 'General',
      faviconUrl: 'https://example.com/favicon.ico',
      pageTitle: 'Example Domain',
      createdAt: DateTime(2025, 1, 15),
      isFavourite: true,
      isArchived: false,
    );

    await mockNetworkImagesFor(() async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'link card',
          ProviderScope(
            child: _wrapWithApp(
              LinkCard(link: sampleLink),
            ),
          ),
        )
        ..addScenario(
          'link card (dark)',
          ProviderScope(
            child: _wrapWithApp(
              LinkCard(link: sampleLink),
              theme: AppTheme.darkTheme,
            ),
          ),
        );

      await tester.pumpWidgetBuilder(builder.build(), surfaceSize: const Size(480, 220));
      await screenMatchesGolden(tester, 'link_card');
    });
  });

  testGoldens('AddLinkSheet renders consistently', (tester) async {
    final overrides = <Override>[
      categoryNamesProvider.overrideWithValue(
        const AsyncValue.data(['General', 'Reading', 'Videos', 'Other']),
      ),
    ];

    final builder = GoldenBuilder.column()
      ..addScenario(
        'add link sheet',
        ProviderScope(
          overrides: overrides,
          child: _wrapWithApp(
            const AddLinkSheet(),
          ),
        ),
      )
      ..addScenario(
        'add link sheet (dark)',
        ProviderScope(
          overrides: overrides,
          child: _wrapWithApp(
            const AddLinkSheet(),
            theme: AppTheme.darkTheme,
          ),
        ),
      );

    await tester.pumpWidgetBuilder(builder.build(), surfaceSize: const Size(520, 720));
    await screenMatchesGolden(tester, 'add_link_sheet');
  });

  testGoldens('EditLinkSheet renders consistently', (tester) async {
    final sampleLink = LinkModel(
      id: 'link-2',
      url: 'https://flutter.dev',
      label: 'Flutter',
      category: 'Reading',
      faviconUrl: 'https://flutter.dev/favicon.ico',
      pageTitle: 'Flutter',
      createdAt: DateTime(2025, 2, 12),
      isFavourite: false,
      isArchived: false,
    );

    final overrides = <Override>[
      categoryNamesProvider.overrideWithValue(
        const AsyncValue.data(['General', 'Reading', 'Videos', 'Other']),
      ),
    ];

    final builder = GoldenBuilder.column()
      ..addScenario(
        'edit link sheet',
        ProviderScope(
          overrides: overrides,
          child: _wrapWithApp(
            EditLinkSheet(link: sampleLink),
          ),
        ),
      )
      ..addScenario(
        'edit link sheet (dark)',
        ProviderScope(
          overrides: overrides,
          child: _wrapWithApp(
            EditLinkSheet(link: sampleLink),
            theme: AppTheme.darkTheme,
          ),
        ),
      );

    await tester.pumpWidgetBuilder(builder.build(), surfaceSize: const Size(520, 700));
    await screenMatchesGolden(tester, 'edit_link_sheet');
  });
}

Widget _wrapWithApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}
