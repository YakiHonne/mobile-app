import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/profile_settings_cubit/profile_settings_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/profile_picture.dart';

class ProfileSettingsMedia extends StatelessWidget {
  const ProfileSettingsMedia({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
      buildWhen: (previous, current) =>
          previous.imageLink != current.imageLink ||
          previous.bannerLink != current.bannerLink,
      builder: (context, state) {
        return Stack(
          children: [
            const SizedBox(
              width: double.infinity,
              height: 220,
            ),
            Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => CommonThumbnail(
                    image: state.bannerLink,
                    width: constraints.maxWidth,
                    isRound: false,
                    radius: 0,
                    height: 120,
                  ),
                ),
                Positioned(
                  left: kDefaultPadding / 2,
                  top: kDefaultPadding / 2,
                  right: kDefaultPadding / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          context
                              .read<ProfileSettingsCubit>()
                              .setMetadataMedia(false);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(
                                alpha: 0.8,
                              ),
                        ),
                        child: Text(
                          state.bannerLink.isEmpty
                              ? context.t.addCover.capitalizeFirst()
                              : context.t.editCover.capitalizeFirst(),
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    height: 1,
                                  ),
                        ),
                      ),
                      if (state.bannerLink.isNotEmpty) _bannerButton(context),
                    ],
                  ),
                ),
              ],
            ),
            _addEditPicture(context, state),
          ],
        );
      },
    );
  }

  Positioned _addEditPicture(BuildContext context, ProfileSettingsState state) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                context.read<ProfileSettingsCubit>().setMetadataMedia(true);
              },
              behavior: HitTestBehavior.translucent,
              child: ProfilePicture2(
                size: 100,
                image: state.imageLink,
                pubkey: state.pubkey,
                padding: 0,
                strokeWidth: 3,
                strokeColor: Theme.of(context).scaffoldBackgroundColor,
                onClicked: () {
                  context.read<ProfileSettingsCubit>().setMetadataMedia(true);
                },
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<ProfileSettingsCubit>().setMetadataMedia(true);
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor.withValues(
                      alpha: 0.8,
                    ),
              ),
              child: Text(
                state.bannerLink.isEmpty
                    ? context.t.addPicture.capitalizeFirst()
                    : context.t.editPicture.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      height: 1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconButton _bannerButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<ProfileSettingsCubit>(),
            child: CupertinoAlertDialog(
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<ProfileSettingsCubit>().deleteBanner();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                  child: Text(
                    context.t.delete,
                    style: const TextStyle(
                      color: kRed,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                  child: Text(
                    context.t.cancel,
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                ),
              ],
              title: Text(
                context.t.deleteCoverPic.capitalizeFirst(),
                style: const TextStyle(
                  height: 1.5,
                ),
              ),
              content: Text(
                context.t.deleteCoverPicDesc.capitalizeFirst(),
              ),
            ),
          ),
        );
      },
      icon: const Icon(
        CupertinoIcons.delete,
      ),
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(
              alpha: 0.8,
            ),
      ),
    );
  }
}
