import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/views/points_management_view/widgets/points_login_popup.dart';

class _PointsCubit extends Cubit<PointsManagementState>
    implements PointsManagementCubit {
  _PointsCubit()
      : super(const PointsManagementState(
            isUpdated: false,
            isNew: true,
            standards: ['A deliberately long translated reward description for testing'],
            currentXp: 10,
            currentLevel: 1,
            nextLevelXp: 100,
            additionalXp: 0,
            currentLevelXp: 10,
            consumablePoints: 0,
            percentage: 0.1));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop points popup scrolls in a short window', (tester) async {
    final points = _PointsCubit();
    addTearDown(points.close);
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
        child: BlocProvider<PointsManagementCubit>.value(
      value: points,
      child: MaterialApp(
          builder: (context, child) =>
              ResponsiveBreakpoints.builder(child: child!, breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 2000, name: DESKTOP),
              ]),
          home: const Scaffold(
              body: Center(
                  child: SizedBox(
            width: 320,
            height: 300,
            child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: PointsLoginPopup()),
          )))),
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextButton));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
