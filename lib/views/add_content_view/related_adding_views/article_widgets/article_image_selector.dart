import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_article_cubit/image_selector_cubit/article_image_selector_cubit.dart';
import '../../../../repositories/localdatabase_repository.dart';
import '../../../../repositories/nostr_data_repository.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/buttons_containers_widgets.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/curation_container.dart';
import '../../../widgets/dotted_container.dart';

class ImageSelector extends HookWidget {
  const ImageSelector({
    super.key,
    required this.onTap,
  });

  final Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final imageUrlController = useTextEditingController();

    return BlocProvider(
      create: (context) => ArticleImageSelectorCubit(
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Material(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          height: 80.h,
          child: Column(
            children: [
              const ModalBottomSheetHandle(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isTablet ? kDefaultPadding : kDefaultPadding / 2,
                    vertical: kDefaultPadding / 2,
                  ),
                  shrinkWrap: true,
                  primary: false,
                  children: [
                    BlocBuilder<ArticleImageSelectorCubit,
                        ArticleImageSelectorState>(
                      builder: (context, state) {
                        return Stack(
                          children: [
                            _imageContainer(state, context),
                            if (state.isImageSelected)
                              Positioned(
                                right: kDefaultPadding / 2,
                                top: kDefaultPadding / 2,
                                child: CircleAvatar(
                                  backgroundColor:
                                      kWhite.withValues(alpha: 0.8),
                                  child: IconButton(
                                    onPressed: () {
                                      context
                                          .read<ArticleImageSelectorCubit>()
                                          .removeImage();
                                      imageUrlController.clear();
                                    },
                                    icon: SvgPicture.asset(
                                      FeatureIcons.trash,
                                      width: 25,
                                      height: 25,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    _selectUploadImage(context, imageUrlController),
                    const Divider(
                      height: kDefaultPadding * 1.5,
                    ),
                    Text(
                      context.t.imageUploadHistory,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    _imageHistory(isTablet),
                  ],
                ),
              ),
              _uploadAndUse(context, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _uploadAndUse(BuildContext context, bool isTablet) {
    return SizedBox(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 15.w : kDefaultPadding,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: Text(
                    context.t.cancel.capitalize(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              BlocBuilder<ArticleImageSelectorCubit, ArticleImageSelectorState>(
                builder: (context, state) {
                  return Expanded(
                    child: Builder(
                      builder: (context) {
                        return TextButton(
                          onPressed: () {
                            if (state.isImageSelected) {
                              context
                                  .read<ArticleImageSelectorCubit>()
                                  .addImage(
                                onSuccess: (link) {
                                  onTap.call(link);
                                  Navigator.pop(context);
                                },
                                onFailure: (message) {
                                  BotToastUtils.showError(
                                    message,
                                  );
                                },
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                state.isImageSelected ? kPurple : kDimGrey,
                          ),
                          child: Text(
                            context.t.uploadAndUse.capitalize(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  BlocBuilder<ArticleImageSelectorCubit, ArticleImageSelectorState>
      _imageHistory(bool isTablet) {
    return BlocBuilder<ArticleImageSelectorCubit, ArticleImageSelectorState>(
      builder: (context, state) {
        if (state.imagesLinks.isEmpty) {
          return Text(
            context.t.noImageHistory,
            style: Theme.of(context).textTheme.labelMedium,
          );
        } else {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              childAspectRatio: 16 / 9,
              crossAxisSpacing: kDefaultPadding / 2,
              mainAxisSpacing: kDefaultPadding / 2,
            ),
            shrinkWrap: true,
            primary: false,
            itemBuilder: (context, index) {
              final link = state.imagesLinks[index];

              return GestureDetector(
                onTap: () {
                  onTap.call(link);
                  Navigator.pop(context);
                },
                child: Stack(
                  children: [
                    if (link.isEmpty)
                      SizedBox(
                        height: 20.h,
                        child: const NoMediaPlaceHolder(),
                      )
                    else
                      CommonThumbnail(
                        image: link,
                        height: 20.h,
                        width: double.infinity,
                        isRound: true,
                        radius: kDefaultPadding,
                      ),
                    Positioned(
                      top: kDefaultPadding / 4,
                      right: kDefaultPadding / 4,
                      child: CircleAvatar(
                        backgroundColor: kWhite.withValues(alpha: 0.8),
                        child: const Icon(
                          Icons.add,
                          color: kBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            itemCount: state.imagesLinks.length,
          );
        }
      },
    );
  }

  Row _selectUploadImage(
      BuildContext context, TextEditingController imageUrlController) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.selectAndUploadLocaleImage,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        BlocBuilder<ArticleImageSelectorCubit, ArticleImageSelectorState>(
          builder: (context, state) {
            return BorderedIconButton(
              firstSelection: true,
              onClicked: () {
                imageUrlController.clear();
                context.read<ArticleImageSelectorCubit>().selectProfileImage(
                  onFailed: () {
                    BotToastUtils.showError(
                      context.t.issueOccuredSelectingImage,
                    );
                  },
                );
              },
              primaryIcon: FeatureIcons.upload,
              secondaryIcon: FeatureIcons.notVisible,
              borderColor: state.isLocalImage
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColorLight,
            );
          },
        ),
      ],
    );
  }

  Container _imageContainer(
      ArticleImageSelectorState state, BuildContext context) {
    return Container(
      height: 20.h,
      decoration: state.isImageSelected
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding,
              ),
              border: Border.all(
                width: 0.5,
                color: Theme.of(context).dividerColor,
              ),
            ),
      foregroundDecoration: state.isImageSelected && state.isLocalImage
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding,
              ),
              image: DecorationImage(
                image: FileImage(
                  state.localImage!,
                ),
                fit: BoxFit.cover,
              ),
            )
          : null,
      child: state.isImageSelected && !state.isLocalImage
          ? state.imageLink.isEmpty
              ? SizedBox(
                  height: 20.h,
                  child: const NoMediaPlaceHolder(),
                )
              : CommonThumbnail(
                  image: state.imageLink,
                  height: 20.h,
                  width: double.infinity,
                  isRound: true,
                  radius: kDefaultPadding,
                )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    FeatureIcons.image,
                    width: 30,
                    height: 30,
                    fit: BoxFit.scaleDown,
                    colorFilter: const ColorFilter.mode(
                      kDimGrey,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    context.t.thumbnailPreview,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
    );
  }
}
