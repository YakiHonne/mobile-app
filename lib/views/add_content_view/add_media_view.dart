// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../logic/add_media_cubit/add_media_cubit.dart';
import '../../models/picture_model.dart';
import '../../models/video_model.dart';
import '../../utils/utils.dart';
import '../widgets/publish_content_final_step.dart';
import 'add_content_main_views/add_article_main_view.dart';
import 'widgets/add_content_appbar.dart';
import 'widgets/add_media_bottom_navigation_bar.dart';
import 'widgets/add_media_main_view.dart';

class AddMediaView extends HookWidget {
  AddMediaView({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Add media view');
  }

  @override
  Widget build(BuildContext context) {
    final media = useState<File?>(null);
    final description = useState<String>('');
    final thumbnail = useState<String>('');
    final dimensions = useState<String>('');
    final isVideo = useState<bool>(false);
    final isSensitive = useState<bool>(false);
    final signer = useState(currentSigner!);

    final components = <Widget>[];

    components.add(
      Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
        child: Builder(
          builder: (context) {
            return AddMediaAppbar(
              actionButtonText: context.t.publish.capitalizeFirst(),
              isActionButtonEnabled: media.value != null,
              extraRight: Padding(
                padding: const EdgeInsets.only(left: kDefaultPadding / 3),
                child: ContentAccountsSwitcher(
                  signer: signer,
                ),
              ),
              onActionClicked: () {
                context.read<AddMediaCubit>().addMedia(
                      description: description.value,
                      imageLink: thumbnail.value,
                      media: media.value!,
                      isVideo: isVideo.value,
                      dimensions: dimensions.value,
                      signer: signer.value,
                      isSensitive: isSensitive.value,
                      onSuccess: (e) {
                        Navigator.pop(context);

                        showModalBottomSheet(
                          context: context,
                          elevation: 0,
                          builder: (_) {
                            return PublishContentFinalStep(
                              appContentType: isVideo.value
                                  ? AppContentType.video
                                  : AppContentType.picture,
                              event: isVideo.value
                                  ? VideoModel.fromEvent(e)
                                  : PictureModel.fromEvent(e),
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                    );
              },
            );
          },
        ),
      ),
    );

    components.add(
      Expanded(
        child: AddMediaMainView(
          media: media,
          isVideo: isVideo,
          description: description,
          dimensions: dimensions,
        ),
      ),
    );

    components.add(
      AddMediaBottomNavigationBar(
        isVideo: isVideo,
        media: media,
        description: description,
        thumbnail: thumbnail,
        isSensitive: isSensitive,
        onMediaSelected: (file, iv) {
          media.value = file;
          isVideo.value = iv;
        },
      ),
    );

    return BlocProvider(
      create: (context) => AddMediaCubit(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: components,
        ),
      ),
    );
  }
}
