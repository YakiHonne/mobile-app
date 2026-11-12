import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/add_content_view/widgets/add_media_main_view.dart';

void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('$platform shows a file picker instead of a camera preview',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final isVideo = ValueNotifier<bool>(false);
      addTearDown(isVideo.dispose);

      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            body: MediaPicker(isVideo: isVideo, onSuccess: (_, __) {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CameraPreview), findsNothing);
      // The localized desktop message is shown with a file-pick action.
      expect(find.text(t.desktopCameraUnavailable), findsOneWidget);
      expect(find.byIcon(LucideIcons.folderOpen), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('$platform camera fallback does not request camera permission',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final isVideo = ValueNotifier<bool>(true);
      addTearDown(isVideo.dispose);

      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            body: MediaPicker(isVideo: isVideo, onSuccess: (_, __) {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // The mobile-only permission message must not appear.
      expect(find.text(t.cameraPermission), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
