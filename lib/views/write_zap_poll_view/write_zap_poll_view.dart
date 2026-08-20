// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../logic/metadata_cubit/metadata_cubit.dart';
import '../../logic/write_note_cubit/write_note_cubit.dart';
import '../../logic/write_zap_poll_cubit/write_zap_poll_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/global_keys.dart';
import '../../utils/utils.dart';
import '../giphy_view/giphy_view.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/curation_container.dart';
import '../widgets/custom_date_picker.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/data_providers.dart';
import '../widgets/dotted_container.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/media_selector.dart';
import '../widgets/modal_sheet_container.dart';
import '../widgets/profile_picture.dart';
import '../write_note_view/widgets/publish_media_container.dart';
import '../write_note_view/write_note_view.dart';

class WriteZapPollView extends HookWidget {
  const WriteZapPollView({
    super.key,
    required this.onZapPollAdded,
  });

  final Function(Event) onZapPollAdded;

  @override
  Widget build(BuildContext context) {
    final mentions = useState(<String>{});
    final tags = useState(<String>{});
    final closedDate = useState<DateTime?>(null);
    final miTec = useTextEditingController();
    final maTec = useTextEditingController();
    final mention = useState<String?>(null);
    final controller = useMemoized(() {
      return MentionTagTextEditingController();
    }, []);

    final currentUserPubkey = currentSigner!.getPublicKey();

    return BlocProvider(
      create: (context) => WriteZapPollCubit(),
      child: ModalSheetContainer(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const Center(child: ModalBottomSheetHandle()),
              _postZapPoll(context, controller, mentions, tags, closedDate,
                  maTec, miTec),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              const Divider(
                height: 0,
                thickness: 0.5,
              ),
              _content(currentUserPubkey, context, controller, mention, miTec,
                  maTec, closedDate),
              const Divider(
                thickness: 0.5,
                height: 0,
              ),
              PublishingMediaContainer(
                controller: controller,
                mention: mention,
                onImageAdd: (imageMaps) {
                  final imageLinks =
                      imageMaps.map((e) => e['url'] ?? '').toList();
                  context.read<WriteZapPollCubit>().addImage(imageLinks);
                  appendTextToPosition(
                    controller: controller,
                    textToAppend: imageLinks.join(' '),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _content(
      String currentUserPubkey,
      BuildContext context,
      MentionTagTextEditingController controller,
      ValueNotifier<String?> mention,
      TextEditingController miTec,
      TextEditingController maTec,
      ValueNotifier<DateTime?> closedDate) {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        primary: false,
        children: [
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Padding(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metadata(currentUserPubkey, context),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                _mentionTextfield(controller, mention),
              ],
            ),
          ),
          BlocBuilder<WriteZapPollCubit, WriteZapPollState>(
            builder: (context, state) {
              if (state.images.isNotEmpty) {
                return Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 140,
                          child: _images(state),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.t.pollOptions.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                CustomIconButton(
                  onClicked: () {
                    context.read<WriteZapPollCubit>().addPollOption();
                  },
                  icon: FeatureIcons.addRaw,
                  size: 15,
                  backgroundColor: Theme.of(context).cardColor,
                  vd: -2,
                ),
              ],
            ),
          ),
          _optionsList(),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _maxMinSats(context, miTec, maTec),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.t.pollCloseDate.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (closedDate.value == null)
                  _clodeDate(context, closedDate)
                else
                  _close(closedDate, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BlocBuilder<WriteZapPollCubit, WriteZapPollState> _optionsList() {
    return BlocBuilder<WriteZapPollCubit, WriteZapPollState>(
      builder: (context, state) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          shrinkWrap: true,
          primary: false,
          itemBuilder: (context, index) {
            final option = state.options[index];

            return PollOptionTextField(
              option: option,
              index: index,
              optionsLength: state.options.length,
              onChanged: (value) {
                context
                    .read<WriteZapPollCubit>()
                    .updatePollOption(value, index);
              },
              onRemove: () {
                context.read<WriteZapPollCubit>().removePollOption(index);
              },
            );
          },
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 4,
          ),
          itemCount: state.options.length,
        );
      },
    );
  }

  Row _close(ValueNotifier<DateTime?> closedDate, BuildContext context) {
    return Row(
      children: [
        Text(
          dateFormat4.format(closedDate.value!),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        CustomIconButton(
          onClicked: () {
            closedDate.value = null;
          },
          icon: FeatureIcons.close,
          size: 20,
          backgroundColor: Theme.of(context).primaryColorLight,
          vd: -2,
        ),
      ],
    );
  }

  IconButton _clodeDate(
      BuildContext context, ValueNotifier<DateTime?> closedDate) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: BlocProvider.value(
                value: context.read<WriteZapPollCubit>(),
                child: PickDateTimeWidget(
                  focusedDate: closedDate.value ?? DateTime.now(),
                  isAfter: true,
                  onDateSelected: (selectedDate) {
                    closedDate.value = selectedDate;
                  },
                  onClearDate: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        );
      },
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
      ),
      icon: AppIcon(
        FeatureIcons.calendar,
        size: 22,
        color: Theme.of(context).primaryColorDark,
      ),
    );
  }

  Padding _maxMinSats(BuildContext context, TextEditingController miTec,
      TextEditingController maTec) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  context.t.minimumSatoshis.capitalizeFirst(),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: miTec,
                  style: Theme.of(context).textTheme.bodyMedium,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  context.t.maximumSatoshis.capitalizeFirst(),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: maTec,
                  style: Theme.of(context).textTheme.bodyMedium,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ListView _images(WriteZapPollState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(
        width: kDefaultPadding / 2,
      ),
      padding: const EdgeInsets.all(
        kDefaultPadding / 2,
      ),
      scrollDirection: Axis.horizontal,
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        final image = state.images[index];

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Positioned.fill(
                child: ExtendedImage.network(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: MediaQuery.of(context).size.width.toInt(),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 2,
                  ),
                  loadStateChanged: (state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                        return const ImageLoadingPlaceHolder();
                      case LoadState.failed:
                        return const NoImagePlaceHolder();
                      case LoadState.completed:
                        return null;
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<WriteNoteCubit>().removeImage(index);
                },
                icon: const Icon(
                  LucideIcons.x,
                  color: kWhite,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: kBlack.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Expanded _mentionTextfield(MentionTagTextEditingController controller,
      ValueNotifier<String?> mention) {
    return Expanded(
      child: Column(
        children: [
          BlocBuilder<MetadataCubit, MetadataState>(
            builder: (context, authorsState) {
              return MentionTagTextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                onMention: (value) async {
                  mention.value = value;
                },
                minLines: 1,
                maxLines: null,
                mentionTagDecoration: MentionTagDecoration(
                  maxWords: null,
                  mentionTextStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Theme.of(context).primaryColor),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: context.t.writeSomething.capitalizeFirst(),
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  focusColor: Theme.of(context).primaryColorLight,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  MetadataProvider _metadata(String currentUserPubkey, BuildContext context) {
    return MetadataProvider(
      pubkey: currentUserPubkey,
      child: (metadata, _) => ProfilePicture2(
        size: 40,
        image: metadata.picture,
        pubkey: metadata.pubkey,
        padding: 0,
        strokeWidth: 0,
        strokeColor: kTransparent,
        onClicked: () {
          openProfileFastAccess(
            context: context,
            pubkey: metadata.pubkey,
          );
        },
      ),
    );
  }

  Padding _postZapPoll(
      BuildContext context,
      MentionTagTextEditingController controller,
      ValueNotifier<Set<String>> mentions,
      ValueNotifier<Set<String>> tags,
      ValueNotifier<DateTime?> closedDate,
      TextEditingController maTec,
      TextEditingController miTec) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            onClicked: () => Navigator.pop(context),
            icon: FeatureIcons.closeRaw,
            backgroundColor: Theme.of(context).cardColor,
          ),
          Text(
            context.t.zapPoll.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          BlocBuilder<WriteZapPollCubit, WriteZapPollState>(
            builder: (context, state) {
              return AppIconButton(
                onClicked: () {
                  final post = getRawText(controller);

                  if (post.trim().isEmpty && state.images.isEmpty) {
                    BotToastUtils.showError(
                      context.t.typeValidZapQuestion.capitalizeFirst(),
                    );
                  } else {
                    context.read<WriteZapPollCubit>().postZapPoll(
                          content: post,
                          mentions: mentions.value.toList(),
                          tags: tags.value.toList(),
                          onSuccess: onZapPollAdded,
                          closedAt: closedDate.value,
                          maximumSatoshis: maTec.text,
                          minimumSatoshis: miTec.text,
                        );
                  }
                },
                icon: FeatureIcons.addRaw,
                iconColor: kWhite,
                backgroundColor: Theme.of(context).primaryColor,
              );
            },
          ),
        ],
      ),
    );
  }
}

class PollOptionTextField extends HookWidget {
  const PollOptionTextField({
    super.key,
    required this.option,
    required this.index,
    required this.optionsLength,
    required this.onChanged,
    required this.onRemove,
  });

  final String option;
  final int index;
  final int optionsLength;
  final Function(String) onChanged;
  final Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final tfc = useTextEditingController(text: option);

    useEffect(
      () {
        tfc.clear();
        tfc.text = option;
        return;
      },
    );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            context.t
                .optionsNumber(
                  number: index.toString(),
                )
                .capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: tfc,
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: onChanged,
          ),
        ),
        if (optionsLength > 2) ...[
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          CustomIconButton(
            onClicked: onRemove,
            icon: FeatureIcons.trash,
            size: 20,
            backgroundColor: kRed,
          ),
        ]
      ],
    );
  }
}

class PublishingMediaContainer extends HookWidget {
  const PublishingMediaContainer({
    super.key,
    required this.onImageAdd,
    required this.controller,
    required this.mention,
  });

  final Function(List<Map<String, String>>) onImageAdd;
  final MentionTagTextEditingController controller;
  final ValueNotifier<String?> mention;

  @override
  Widget build(BuildContext context) {
    final metadatas = useState<List<Metadata>>([]);
    final tags = useState<List<String>>([]);

    Future<void> searchMetadata(String search) async {
      final users = await HttpFunctionsRepository.getUsers(search);

      final List<Metadata> newList = <Metadata>[...metadatas.value];

      for (final user in users) {
        final bool userExists = newList
            .where((Metadata element) => element.pubkey == user.pubkey)
            .isNotEmpty;

        if (!userExists && !isUserMuted(user.pubkey) && user.nip05.isNotEmpty) {
          newList.add(user);
          metadataCubit.saveMetadata(user);
        }
      }

      metadatas.value = orderMetadataByScore(metadatas: newList, match: search);
    }

    useMemoized(
      () {
        mention.addListener(
          () async {
            if (mention.value == null || mention.value!.length <= 1) {
              metadatas.value.clear();
            } else {
              if (mention.value![0] == '@') {
                final sub = mention.value!.substring(1);
                metadatas.value = orderMetadataByScore(
                  metadatas: await metadataCubit.searchCacheMetadatas(sub),
                  match: sub,
                );
                searchMetadata(sub);
              } else {
                tags.value = nostrRepository
                    .getFilteredTopics()
                    .where(
                      (t) => t.contains(mention.value!.substring(1)),
                    )
                    .toList();
              }
            }
          },
        );
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if ((mention.value?.length ?? 0) > 1) ...[
              SizedBox(
                height: 20.h,
                child: ScrollShadow(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: mention.value![0] == '@'
                      ? MentionMetadas(
                          metadatas: metadatas,
                          controller: controller,
                          onTextChanged: () {},
                        )
                      : MentioTags(
                          tags: tags.value,
                          controller: controller,
                          onTextChanged: () {},
                        ),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    showAppModalSheet(
                      context: context,
                      builder: (_) {
                        return MediaSelector(
                          onSuccess: (urls) {
                            onImageAdd.call(urls);
                          },
                        );
                      },
                      backgroundColor: kTransparent,
                    );
                  },
                  icon: AppIcon(
                    FeatureIcons.imageLink,
                    size: 25,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showAppModalSheet(
                      context: context,
                      builder: (_) {
                        return GiphyView(
                          onGifSelected: (p0) {
                            onImageAdd.call([
                              {'url': p0}
                            ]);
                          },
                        );
                      },
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
                  icon: SvgPicture.asset(
                    FeatureIcons.giphy,
                    width: 22,
                    height: 22,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final controller =
                        GlobalKeys.flutterMentionKey.currentState?.controller;

                    controller?.text = '${controller.text}@';
                  },
                  icon: const Text(
                    '@',
                    style: TextStyle(
                      fontSize: 22,
                      height: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final controller =
                        GlobalKeys.flutterMentionKey.currentState?.controller;

                    controller?.text = '${controller.text}#';
                  },
                  icon: const Text(
                    '#',
                    style: TextStyle(
                      fontSize: 22,
                      height: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
