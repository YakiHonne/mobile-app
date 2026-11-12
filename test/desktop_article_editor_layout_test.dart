import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/common/markdown/markdown_text_input.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/utils/utils.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
  @override
  ThemeState get state => ThemeState(
      textScaleFactor: 1,
      mode: AppThemeMode.graphite,
      isFluid: false,
      fluidCards: false,
      glassQuality: GlassQuality.minimal,
      theme: ThemeData.light(),
      primaryColor: Colors.orange);
}

void main() {
  testWidgets('desktop article live preview adapts while preserving its draft',
      (tester) async {
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(900.0);
    final mode = ValueNotifier(ArticleWritingState.editPreview);
    final content = TextEditingController();
    addTearDown(width.dispose);
    addTearDown(mode.dispose);
    addTearDown(content.dispose);
    await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
      builder: (context, child) =>
          ResponsiveBreakpoints.builder(child: child!, breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: 2000, name: DESKTOP),
      ]),
      home: Scaffold(
          body: Center(
              child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, child) =>
            SizedBox(width: value, height: 500, child: child),
        child: MarkdownTextInput((value) {}, '', false,
            controller: content,
            actions: const [],
            toggleArticleContent: mode,
            previewWidget: const Text('Disposable preview')),
      ))),
    )));
    await tester.pump();
    expect(find.text('Disposable preview'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Disposable draft');
    width.value = 400;
    await tester.pump();
    expect(find.text('Disposable preview'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Disposable preview')).dy,
        greaterThan(tester.getTopLeft(find.byType(TextFormField)).dy));
    expect(content.text, 'Disposable draft');
    width.value = 900;
    await tester.pump();
    expect(find.text('Disposable preview'), findsOneWidget);
    expect(content.text, 'Disposable draft');
    expect(tester.takeException(), isNull);
  });
}
