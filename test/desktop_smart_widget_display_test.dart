import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/metadata_cubit/metadata_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/mute_model.dart';
import 'package:yakihonne/models/smart_widgets_components.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_display.dart';

class _MetadataCubit extends Cubit<MetadataState> implements MetadataCubit {
  _MetadataCubit() : super(const MetadataState());
  @override
  void requestMetadata(String pubkey) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NostrRepository extends Fake implements NostrDataRepository {
  @override
  MuteModel get muteModel => MuteModel.empty();
}

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
  testWidgets('desktop smart widget preview scrolls tall disposable content',
      (tester) async {
    final metadata = _MetadataCubit();
    metadataCubit = metadata;
    nostrRepository = _NostrRepository();
    themeCubit = _ThemeCubit();
    final model = SmartWidget(
      id: 'disposable',
      createdAt: DateTime(2025),
      pubkey: '',
      identifier: 'disposable',
      client: '',
      title: 'Preview',
      keywords: const [],
      icon: '',
      image: '',
      type: SWType.basic,
      smartWidgetBox: SmartWidgetBox(
        image: const SmartWidgetImage(url: ''),
        buttons: List.generate(
          6,
          (index) => SmartWidgetButton(
            text: 'Button $index',
            type: SWBType.Redirect,
            url: '',
            id: '$index',
          ),
        ),
      ),
      stringifiedEvent: '',
    );
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: BlocProvider<MetadataCubit>.value(
          value: metadata,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 180,
                child: SmartWidgetDisplay(smartWidgetModel: model),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final scroll = find.byType(SingleChildScrollView);
    expect(scroll, findsOneWidget);
    final scrollable = find.descendant(
      of: scroll,
      matching: find.byType(Scrollable),
    );
    expect(tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0));
    await tester.drag(scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await metadata.close();
  });
}
