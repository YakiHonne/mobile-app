import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/models/smart_widgets_components.dart';
import 'package:yakihonne/views/add_content_view/related_adding_views/smart_widget_widgets/smart_widget_specifications.dart';
import 'package:yakihonne/views/gallery_view/gallery_view.dart';
import 'package:yakihonne/views/widgets/common_thumbnail.dart';
import 'package:yakihonne/views/widgets/content_placeholder.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';
import 'package:yakihonne/views/widgets/yaki_gallery/interactive_viewer_boundary.dart';
import 'package:yakihonne/views/widgets/yaki_gallery/yaki_gallery.dart';

void main() {
  testWidgets('link image preview uses the locally available width',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
              child: SizedBox(width: 320, child: ImageDisplayer(link: ''))),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.widget<GalleryImageView>(find.byType(GalleryImageView)).width,
        320);
    expect(tester.takeException(), isNull);
  });
  testWidgets('gallery zoom boundary follows the pane on resize',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(320.0);
    addTearDown(width.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, child) =>
            SizedBox(width: value, height: 400, child: child),
        child: YakiGallery<String>(
            sources: const ['fixture'],
            initIndex: 0,
            itemBuilder: (context, index, focused) =>
                const ColoredBox(color: Colors.red)),
      ),
    ))));
    await tester.pump();
    expect(
        tester
            .widget<InteractiveViewerBoundary>(
                find.byType(InteractiveViewerBoundary))
            .boundaryWidth,
        320);
    width.value = 600;
    await tester.pump();
    expect(
        tester
            .widget<InteractiveViewerBoundary>(
                find.byType(InteractiveViewerBoundary))
            .boundaryWidth,
        600);
    expect(tester.takeException(), isNull);
  });
  testWidgets('media skeleton follows its local pane width on resize',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(320.0);
    addTearDown(width.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SingleChildScrollView(
      child: ValueListenableBuilder<double>(
          valueListenable: width,
          builder: (context, value, child) =>
              SizedBox(width: value, child: child),
          child: const MediaSkeleton()),
    )))));
    await tester.pump();
    final narrowHeight = tester.getSize(find.byType(MediaSkeleton)).height;
    width.value = 600;
    await tester.pump();
    final wideHeight = tester.getSize(find.byType(MediaSkeleton)).height;
    expect(wideHeight, greaterThan(narrowHeight * 1.7));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Smart Widget image editor uses its local width', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
        child: const MaterialApp(
            home: Scaffold(
                body: Center(
      child: SizedBox(
          width: 320,
          child: ImageEditableContainer(
            smartWidgetBox: SmartWidgetBox(
                buttons: [],
                image:
                    SmartWidgetImage(url: 'https://example.invalid/image.png')),
            toggleView: false,
          )),
    )))));
    await tester.pump();
    expect(tester.widget<CommonThumbnail>(find.byType(CommonThumbnail)).width,
        300);
    expect(tester.takeException(), isNull);
  });
}
