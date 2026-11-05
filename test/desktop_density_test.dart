import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_density.dart';
import 'package:yakihonne/views/main_view/desktop/workspace_feed.dart';

void main() {
  testWidgets('density updates feed spacing and restores the saved choice',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = DesktopDensityController(preferences);
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: DesktopDensityScope(
        controller: controller,
        child: Center(
            child: SizedBox(
          width: 400,
          height: 600,
          child: DesktopWorkspaceFeed(
            storageKey: const PageStorageKey('density-test'),
            padding: EdgeInsets.zero,
            header: const SizedBox.shrink(),
            itemCount: 2,
            itemBuilder: (_, index) => SizedBox(
              key: ValueKey(index),
              height: 60,
            ),
          ),
        )),
      ),
    ));
    final comfortableGap = tester.getTopLeft(find.byKey(const ValueKey(1))).dy -
        tester.getBottomLeft(find.byKey(const ValueKey(0))).dy;
    controller.select(DesktopDensity.compact);
    await tester.pump();
    final compactGap = tester.getTopLeft(find.byKey(const ValueKey(1))).dy -
        tester.getBottomLeft(find.byKey(const ValueKey(0))).dy;
    expect(compactGap, lessThan(comfortableGap));
    final restored = DesktopDensityController(preferences);
    expect(restored.value, DesktopDensity.compact);
    restored.dispose();
  });
}
