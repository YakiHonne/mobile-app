import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/widgets/fluid_content_card.dart';

class _ThemeCubit extends Cubit<ThemeState> implements ThemeCubit {
  _ThemeCubit(bool fluid)
      : super(ThemeState(
          textScaleFactor: 1,
          mode: AppThemeMode.graphite,
          isFluid: fluid,
          fluidCards: false,
          glassQuality: GlassQuality.minimal,
          theme: ThemeData.dark(),
          primaryColor: Colors.orange,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop feed cards are visible in solid and fluid themes',
      (tester) async {
    for (final fluid in [false, true]) {
      final cubit = _ThemeCubit(fluid);
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider<ThemeCubit>.value(
          value: cubit,
          child: const FluidContentCard(
            desktopContainer: true,
            child: Text('note'),
          ),
        ),
      ));
      final container = tester.widget<Container>(find
          .ancestor(
            of: find.text('note'),
            matching: find.byWidgetPredicate((widget) =>
                widget is Container && widget.decoration is BoxDecoration),
          )
          .first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.color == null, fluid);
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    }
  });
}
