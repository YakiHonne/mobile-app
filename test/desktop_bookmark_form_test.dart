import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/add_bookmark_cubit/add_bookmark_cubit.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';

class _BookmarkCubit extends Cubit<AddBookmarkState>
    implements AddBookmarkCubit {
  _BookmarkCubit()
      : super(const AddBookmarkState(
          bookmarks: [],
          loadingBookmarksList: [],
          isBookmarksLists: false,
          eventId: '',
          eventPubkey: '',
          kind: 1,
        ));

  String capturedTitle = '';

  @override
  void setText({required String text, required bool isTitle}) {
    if (isTitle) {
      capturedTitle = text;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('bookmark form fits a narrow desktop dialog and accepts input',
      (tester) async {
    final cubit = _BookmarkCubit();
    final controller = ScrollController();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 2000, name: DESKTOP),
          ],
        ),
        home: BlocProvider<AddBookmarkCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 500,
                child: MediaQuery(
                  data:
                      const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                  child: SubmitBookmarkList(controller: controller),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField).first;
    expect(tester.getSize(field).width, 280);
    await tester.enterText(field, 'Disposable title');
    expect(cubit.capturedTitle, 'Disposable title');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await cubit.close();
  });
}
