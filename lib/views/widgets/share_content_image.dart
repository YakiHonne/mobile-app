// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import 'article_container.dart';
import 'curation_container.dart';
import 'dotted_container.dart';
import 'note_stats.dart';
import 'video_common_container.dart';

class ShareContentImage extends HookWidget {
  const ShareContentImage({super.key, required this.model});

  final BaseEventModel model;

  @override
  Widget build(BuildContext context) {
    final screenshotController = useState(ScreenshotController());
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 15.w : kDefaultPadding / 2,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalBottomSheetHandle(),
          _screenshot(screenshotController, context),
          _shareImage(screenshotController, context),
        ],
      ),
    );
  }

  SafeArea _shareImage(ValueNotifier<ScreenshotController> screenshotController,
      BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => shareImage(
            screenshotController: screenshotController.value,
            context: context,
          ),
          child: Text(
            context.t.shareImage,
          ),
        ),
      ),
    );
  }

  Padding _screenshot(ValueNotifier<ScreenshotController> screenshotController,
      BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
      ),
      child: Screenshot(
        controller: screenshotController.value,
        child: Container(
          width: 100.w,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          alignment: Alignment.center,
          child: _imageContainer(context),
        ),
      ),
    );
  }

  Container _imageContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(
              alpha: 0.5,
            ),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AbsorbPointer(
        child: Column(
          children: [
            getWidget(),
            const Divider(
              thickness: 0.5,
            ),
            Text(
              context.t.sharedOn(
                date: dateFormat2.format(DateTime.now()),
              ),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getWidget() {
    if (model is DetailedNoteModel) {
      return DetailedNoteContainer(
        note: model as DetailedNoteModel,
        isMain: true,
        addLine: false,
        noRender: true,
      );
    } else if (model is Article) {
      return ArticleContainer(
        article: model as Article,
        highlightedTag: '',
        isMuted: false,
        isBookmarked: false,
        onClicked: () {},
        isFollowing: false,
      );
    } else if (model is VideoModel) {
      final video = model;

      return VideoCommonContainer(
        isBookmarked: false,
        video: video as VideoModel,
        isMuted: false,
        isFollowing: false,
        onTap: () {},
      );
    } else if (model is Curation) {
      final curation = model;

      return CurationContainer(
        curation: curation as Curation,
        isFollowing: false,
        isBookmarked: false,
        isProfileAccessible: false,
        onClicked: () {},
        padding: 0,
      );
    }

    return Container();
  }

  Future<void> shareImage({
    required ScreenshotController screenshotController,
    required BuildContext context,
  }) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final temp = await getApplicationDocumentsDirectory();
      final img = await screenshotController.captureAndSave(temp.path);

      cancel.call();

      if (img != null) {
        YNavigator.pop(context);

        await Share.shareXFiles(
          [
            XFile(img),
          ],
        );
      }
    } catch (e, stack) {
      lg.i(stack);
      cancel.call();
    }
  }
}
