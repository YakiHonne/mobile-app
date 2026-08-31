import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/write_video_cubit/write_video_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_published_modal.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/modal_sheet_container.dart';
import '../related_adding_views/video_widgets/video_specifications.dart';

class AddVideoSpecificationView extends StatelessWidget {
  const AddVideoSpecificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteVideoCubit, WriteVideoState>(
      builder: (context, state) {
        return ModalSheetContainer(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: VideoSpecifications(
                    scrollController: scrollController,
                  ),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  padding: EdgeInsets.only(
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  alignment: Alignment.center,
                  child: _publish(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SizedBox _publish(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          context.read<WriteVideoCubit>().setVideo(
            onFailure: (message) {
              BotToastUtils.showError(
                message,
              );
            },
            onSuccess: (video) {
              Navigator.pop(context);
              Navigator.pop(context);

              showContentPublishedModalSheet(
                context,
                event: video,
                contentType: AppContentType.video,
              );
            },
          );
        },
        child: Text(
          context.t.publish.capitalize(),
        ),
      ),
    );
  }
}
