import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/utils/theme/theme.dart';
import 'package:yakihonne/views/widgets/content_renderer/desktop_feed_media.dart';

void main() {
  testWidgets('hidden media fits translated large text in desktop themes',
      (tester) async {
    final themes = [
      AppPreferredThemes.light(),
      AppPreferredThemes.dark(),
      AppPreferredThemes.black(),
      AppPreferredThemes.cream(),
      AppPreferredThemes.fluidGraphite(),
      AppPreferredThemes.fluidNoir(),
      AppPreferredThemes.fluidNeige(),
      AppPreferredThemes.fluidIvory(),
    ];
    addTearDown(() => LocaleSettings.setLocale(AppLocale.en));
    for (final locale in [AppLocale.en, AppLocale.fr, AppLocale.ar]) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      for (final theme in themes) {
        await tester.pumpWidget(TranslationProvider(
          child: MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Directionality(
                textDirection: locale == AppLocale.ar
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: const Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 320,
                      height: 180,
                      child: DesktopHiddenVideo(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: '${locale.name}, ${theme.brightness}');
        final message = find
            .descendant(
              of: find.byType(DesktopHiddenVideo),
              matching: find.byType(Text),
            )
            .last;
        await tester.ensureVisible(message);
        await tester.pump();
        expect(
            tester.getBottomLeft(message).dy,
            lessThanOrEqualTo(
                tester.getBottomLeft(find.byType(DesktopHiddenVideo)).dy));
        final background = theme.cardColor.computeLuminance();
        final foreground = theme.primaryColorDark.computeLuminance();
        final contrast = (background > foreground)
            ? (background + 0.05) / (foreground + 0.05)
            : (foreground + 0.05) / (background + 0.05);
        expect(contrast, greaterThanOrEqualTo(3),
            reason: 'hidden-media icon contrast in ${locale.name}');
      }
    }
  });
}
