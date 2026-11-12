import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/main_view/widgets/app_bar_widgets.dart';

class _NotificationsCubit extends Cubit<NotificationsState>
    implements NotificationsCubit {
  _NotificationsCubit()
      : super(const NotificationsState(
          events: [],
          index: 0,
          isRead: true,
          refresh: false,
          isLoading: false,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  testWidgets('desktop notification selector fits and opens in a narrow pane',
      (tester) async {
    themeCubit = _ThemeCubit();
    final cubit = _NotificationsCubit();
    notificationsCubit = cubit;
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: BlocProvider<NotificationsCubit>.value(
          value: cubit,
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                  child: Center(child: NotificationTypes()),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.getSize(find.byType(NotificationTypes)).width, 280);
    await tester.tap(find.byType(NotificationTypes));
    await tester.pumpAndSettle();
    expect(find.text('Mentions'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
}
