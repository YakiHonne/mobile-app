import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/views/add_content_view/related_adding_views/curation_widgets/curation_content.dart';

void main() {
  testWidgets('desktop handles reorder items without covering delete actions',
      (tester) async {
    final items = ['First', 'Second', 'Third'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) => ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorderItem: (oldIndex, newIndex) => setState(() {
                    items.insert(newIndex, items.removeAt(oldIndex));
                  }),
                  itemBuilder: (context, index) => DesktopCurationReorderItem(
                    key: ValueKey(items[index]),
                    index: index,
                    child: SizedBox(
                      height: 60,
                      child: Row(children: [
                        Expanded(child: Text(items[index])),
                        TextButton(
                          onPressed: () =>
                              setState(() => items.removeAt(index)),
                          child: Text('Delete ${items[index]}'),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(ReorderableDragStartListener).first,
      const Offset(0, 135),
    );
    await tester.pumpAndSettle();
    expect(items, ['Second', 'First', 'Third']);
    await tester.tap(find.text('Delete Third'));
    await tester.pumpAndSettle();
    expect(items, ['Second', 'First']);
    expect(tester.takeException(), isNull);
  });
}
