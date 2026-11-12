import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_dm_workspace.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_pane_split.dart';
import 'package:yakihonne/views/widgets/suggestions_box/interests.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
  @override
  ThemeState get state => ThemeState(
        textScaleFactor: 1,
        mode: AppThemeMode.graphite,
        isFluid: false,
        fluidCards: false,
        glassQuality: GlassQuality.minimal,
        theme: ThemeData.light(),
        primaryColor: Colors.orange,
      );
}

void main() {
  testWidgets('real DM workspace and interest cards fit divider extremes',
      (tester) async {
    themeCubit = _ThemeCubit();
    SharedPreferences.setMockInitialValues({'desktop_pane_split': 0.01});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selected = ValueNotifier<String?>('fixture-peer');
    addTearDown(selected.dispose);
    final topic = Topic(
      topic: 'A deliberately long topic label for a narrow pane',
      icon: '',
      subTopics: [],
    );
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1067,
              height: 550,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: DesktopPaneSplit(
                  preferences: prefs,
                  label: 'Resize panes',
                  mainBuilder: (_) => DesktopDmWorkspace(
                    selected: selected,
                    list: const Text('Conversation list'),
                    conversationBuilder: (_, __, ___) =>
                        const Material(child: TextField()),
                  ),
                  sideBuilder: (_) => ListView(
                    children: [
                      for (var i = 0; i < 4; i++)
                        SuggestedInterestContainer(
                          interest: topic,
                          isAdded: false,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(DesktopDmWorkspace)).width, 666);
    expect(tester.getSize(find.byType(SuggestedInterestContainer).first).width,
        400);
    await tester.enterText(find.byType(TextField), 'disposable draft');
    final divider = find.bySemanticsLabel('Resize panes');
    final semantics = tester.ensureSemantics();
    final node = tester.getSemantics(divider);
    final owner = tester.renderObject(divider).owner!.semanticsOwner!;
    for (var i = 0; i < 15; i++) {
      owner.performAction(node.id, SemanticsAction.increase);
      await tester.pump();
    }
    expect(tester.getSize(find.byType(DesktopDmWorkspace)).width, 400);
    expect(find.byType(TextField), findsNothing);
    for (var i = 0; i < 15; i++) {
      owner.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
    }
    expect(find.text('disposable draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
