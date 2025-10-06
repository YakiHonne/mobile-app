import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../logic/write_video_cubit/write_video_cubit.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../add_content_specification_views/add_video_specification_view.dart';
import '../related_adding_views/video_widgets/video_content.dart';
import '../widgets/add_content_appbar.dart';

class AddVideoMainView extends StatelessWidget {
  const AddVideoMainView({super.key, this.videoModel});

  final VideoModel? videoModel;

  @override
  Widget build(BuildContext context) {
    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteVideoCubit, WriteVideoState>(
        builder: (context, state) {
          final enabled = state.title.isNotEmpty && state.videoUrl.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: AddContentAppbar(
              actionButtonText: context.t.next,
              isActionButtonEnabled: enabled,
              onActionClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return BlocProvider<WriteVideoCubit>.value(
                      value: context.read<WriteVideoCubit>(),
                      child: const AddVideoSpecificationView(),
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
            ),
          );
        },
      ),
    );

    components.add(
      Expanded(
        child: BlocBuilder<AddContentCubit, AddContentState>(
          builder: (context, state) {
            return const VideoContent();
          },
        ),
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: nostrRepository.mainCubit,
        ),
        BlocProvider(
          create: (context) => WriteVideoCubit(videoModel: videoModel),
        )
      ],
      child: Column(
        children: components,
      ),
    );
  }
}
