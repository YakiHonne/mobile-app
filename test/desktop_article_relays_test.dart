import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/add_content_view/related_adding_views/article_widgets/article_selected_relays.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
  @override
  bool get isDark => false;
}

void main() {
  testWidgets('desktop relay choices fit a narrow pane and remain tappable',
      (tester) async {
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? toggled;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 2000, name: DESKTOP),
          ],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 700,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: ArticleSelectedRelays(
                  totaRelays: const [
                    'wss://first.example',
                    'wss://second.example',
                  ],
                  selectedRelays: const [],
                  onToggle: (relay) => toggled = relay,
                  onDeleteDraft: () {},
                  isDraft: false,
                  deleteDraft: false,
                  isForwardedAsDraft: false,
                  isDraftShown: false,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final first = find.text('first.example');
    final second = find.text('second.example');
    expect(tester.getTopLeft(second).dy,
        greaterThan(tester.getBottomLeft(first).dy));
    await tester.tap(second);
    expect(toggled, 'wss://second.example');
    expect(tester.takeException(), isNull);
  });
}
