import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/suggestion_box_cubit/suggestions_box_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_density.dart';
import 'package:yakihonne/views/widgets/suggestions_box/interests.dart';
import 'package:yakihonne/views/widgets/suggestions_box/multi_suggestion_box.dart';

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

class _Suggestions extends Cubit<SuggestionsBoxState>
    implements SuggestionsBoxCubit {
  _Suggestions(Topic topic)
      : super(SuggestionsBoxState(
          trendingUsers24: const [],
          notes: const [],
          articles: const [],
          suggestions: [topic],
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop sidebar density updates section spacing, not card size',
      (tester) async {
    themeCubit = _ThemeCubit();
    nostrRepository = NostrDataRepository();
    currentSigner = null;
    SharedPreferences.setMockInitialValues({});
    final controller =
        DesktopDensityController(await SharedPreferences.getInstance());
    final suggestions =
        _Suggestions(Topic(topic: 'Fixture', icon: '', subTopics: []));
    addTearDown(controller.dispose);
    addTearDown(suggestions.close);
    await tester.pumpWidget(TranslationProvider(
      child: BlocProvider<SuggestionsBoxCubit>.value(
        value: suggestions,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: DesktopDensityScope(
            controller: controller,
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: MultiSuggestionBox(
                        index: 3, isLeading: true, desktopPane: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final card = find.byType(SuggestedInterestContainer);
    final heading = find.text('Interests');
    final comfortableGap =
        tester.getTopLeft(card).dy - tester.getBottomLeft(heading).dy;
    final comfortableSize = tester.getSize(card);
    final comfortableSectionHeight =
        tester.getSize(find.byType(MultiSuggestionBox)).height;
    controller.select(DesktopDensity.compact);
    await tester.pumpAndSettle();
    final compactGap =
        tester.getTopLeft(card).dy - tester.getBottomLeft(heading).dy;
    expect(compactGap, lessThan(comfortableGap));
    expect(tester.getSize(card), comfortableSize);
    expect(tester.getSize(find.byType(MultiSuggestionBox)).height,
        lessThan(comfortableSectionHeight));
    controller.select(DesktopDensity.comfortable);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MultiSuggestionBox)).height,
        comfortableSectionHeight);
    expect(tester.takeException(), isNull);
  });
}
