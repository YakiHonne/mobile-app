import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/markdown/markdown_text_selection.dart';
import 'package:yakihonne/logic/dashboard_cubits/dashboard_scheduled_cubit/dashboard_scheduled_cubit.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/routes/navigator.dart';

void main() {
  group('GlitchTip regression fixes', () {
    testWidgets('unmounted navigation contexts cannot pop routes', (
      WidgetTester tester,
    ) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(savedContext.mounted, isFalse);
      expect(YNavigator.canPop(savedContext), isFalse);
    });

    test('closed scheduled-note cubits ignore late load calls', () async {
      final cubit = DashboardScheduledCubit();
      await cubit.close();

      await expectLater(cubit.getScheduledNotes(), completes);
    });

    test('normalizes reversed and stale Markdown text selections', () {
      expect(
        normalizeMarkdownSelection(
          const TextSelection(baseOffset: 3837, extentOffset: 3751),
          8521,
        ),
        const TextRange(start: 3751, end: 3837),
      );
      expect(
        normalizeMarkdownSelection(
          const TextSelection(baseOffset: 9, extentOffset: 14),
          7,
        ),
        const TextRange(start: 7, end: 7),
      );
    });

    test('skips malformed points actions while retaining valid records', () {
      var malformedCount = 0;
      final actions = PointAction.fromList(
        [
          {'action': null},
          {
            'action': 'note_created',
            'current_points': 1,
            'count': 2,
            'all_time_points': 3,
            'last_updated': 1,
          },
          {
            'action': 'malformed',
            'current_points': null,
            'count': 1,
            'all_time_points': 1,
            'last_updated': 1,
          },
        ],
        onMalformed: () => malformedCount++,
      );

      expect(actions, hasLength(1));
      expect(actions.single.actionId, 'note_created');
      expect(malformedCount, 2);
    });
  });
}
