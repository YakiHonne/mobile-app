// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/tools_view/tools_view.dart';
import '../../giphy_view/giphy_view.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/media_selector.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';

class PublishingMediaContainer extends HookWidget {
  const PublishingMediaContainer({
    super.key,
    required this.onImageAdd,
    required this.onTextChanged,
    required this.mention,
    required this.controller,
    required this.isNewNote,
    this.isPaid,
  });

  final Function(List<String>) onImageAdd;
  final Function() onTextChanged;
  final ValueNotifier<String?> mention;
  final ValueNotifier<bool>? isPaid;
  final MentionTagTextEditingController controller;
  final bool? isNewNote;

  @override
  Widget build(BuildContext context) {
    final component = Column(
      children: [
        MentionBox(
          mention: mention,
          controller: controller,
          onTextChanged: onTextChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _image(context),
            _gif(context),
            _mention(),
            _smartWidgets(context),
            if (isPaid != null) _paidNote(context),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: isNewNote == null
          ? SafeArea(child: component)
          : Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom == 0 && !isNewNote!
                        ? MediaQuery.of(context).viewPadding.bottom
                        : 0,
              ),
              child: component,
            ),
    );
  }

  Container _paidNote(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 4,
        vertical: kDefaultPadding / 8,
      ),
      child: Center(
        child: Row(
          children: [
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Text(
              context.t.paidNote.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            SizedBox(
              width: 35,
              height: 25,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CupertinoSwitch(
                  value: isPaid!.value,
                  onChanged: (isToggled) {
                    isPaid!.value = !isPaid!.value;
                  },
                  activeTrackColor: kMainColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconButton _smartWidgets(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) {
            return ToolsView(
              onContentAdded: (content) => appendTextToPosition(
                controller: controller,
                textToAppend: content,
              ),
            );
          },
          backgroundColor: kTransparent,
          useRootNavigator: true,
          elevation: 0,
          useSafeArea: true,
        );
      },
      icon: SvgPicture.asset(
        FeatureIcons.menu,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  IconButton _mention() {
    return IconButton(
      onPressed: () {
        appendTextToPosition(controller: controller, textToAppend: '@');
        onTextChanged();
      },
      icon: const Text(
        '@',
        style: TextStyle(
          fontSize: 20,
          height: 0.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconButton _gif(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return GiphyView(
              onGifSelected: (url) => onImageAdd.call([url]),
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      icon: SvgPicture.asset(
        FeatureIcons.gif,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  IconButton _image(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) {
            return MediaSelector(
              onSuccess: (urls) {
                onImageAdd.call(urls);
                Navigator.pop(context);
              },
            );
          },
          backgroundColor: kTransparent,
          useRootNavigator: true,
          elevation: 0,
          useSafeArea: true,
        );
      },
      icon: SvgPicture.asset(
        FeatureIcons.imageLink,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class MentionBox extends HookWidget {
  const MentionBox({
    super.key,
    required this.mention,
    required this.controller,
    required this.onTextChanged,
  });

  final ValueNotifier<String?> mention;
  final MentionTagTextEditingController controller;
  final Function() onTextChanged;

  @override
  Widget build(BuildContext context) {
    final metadatas = useState<List<Metadata>>([]);
    final tags = useState<List<String>>([]);

    final searchMetadata = useMemoized(() {
      return (String search) async {
        final users = await HttpFunctionsRepository.getUsers(search);
        final newList = <Metadata>[...metadatas.value];

        for (final user in users) {
          final userExists = newList
              .where((Metadata element) => element.pubkey == user.pubkey)
              .isNotEmpty;

          if (!userExists &&
              !nostrRepository.mutes.contains(user.pubkey) &&
              user.nip05.isNotEmpty) {
            newList.add(user);
            metadataCubit.saveMetadata(user);
          }
        }

        metadatas.value = newList;
      };
    });

    useMemoized(
      () {
        mention.addListener(
          () async {
            if (mention.value == null || mention.value!.length <= 1) {
              metadatas.value.clear();
            } else {
              if (mention.value![0] == '@') {
                final sub = mention.value!.substring(1);

                metadatas.value = (await metadataCubit
                    .searchCacheMetadatasFromContactList(
                  sub,
                ))
                  ..where((element) =>
                      !nostrRepository.mutes.contains(element.pubkey) &&
                      !nostrRepository.bannedPubkeys
                          .contains(element.pubkey)).toList();

                if (metadatas.value.length >= 10) {
                  return;
                }

                final local = await metadataCubit.searchCacheMetadatas(sub);
                final filteredLocal = <Metadata>[];
                for (final user in local) {
                  final notAvailable = metadatas.value
                      .where(
                          (Metadata element) => element.pubkey == user.pubkey)
                      .isEmpty;

                  if (notAvailable) {
                    filteredLocal.add(user);
                  }
                }

                metadatas.value = [
                  ...metadatas.value,
                  ...orderMetadataByScore(metadatas: filteredLocal, match: sub)
                ];

                if (metadatas.value.length >= 10) {
                  return;
                }

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

    return (mention.value?.length ?? 0) > 1
        ? SizedBox(
            height: 25.h,
            child: ScrollShadow(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: mention.value![0] == '@'
                  ? MentionMetadas(
                      metadatas: metadatas,
                      controller: controller,
                      onTextChanged: onTextChanged,
                    )
                  : MentioTags(
                      tags: tags.value,
                      controller: controller,
                      onTextChanged: onTextChanged,
                    ),
            ),
          )
        : const SizedBox.shrink();
  }
}

class MentionMetadas extends HookWidget {
  const MentionMetadas({
    super.key,
    required this.metadatas,
    required this.controller,
    required this.onTextChanged,
  });

  final ValueNotifier<List<Metadata>> metadatas;
  final MentionTagTextEditingController controller;
  final Function() onTextChanged;

  @override
  Widget build(BuildContext context) {
    final contactList = useMemoized(() {
      return contactListCubit.contacts;
    });

    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final metadata = metadatas.value[index];

        return MentionItem(
            metadata: metadata,
            controller: controller,
            onTextChanged: onTextChanged,
            contactList: contactList);
      },
      itemCount: metadatas.value.length,
    );
  }
}

class MentionItem extends StatelessWidget {
  const MentionItem({
    super.key,
    required this.metadata,
    required this.controller,
    required this.onTextChanged,
    required this.contactList,
  });

  final Metadata metadata;
  final MentionTagTextEditingController controller;
  final Function() onTextChanged;
  final List<String> contactList;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey(metadata.pubkey),
      onTap: () {
        controller.addMention(
          label: metadata.getName(),
          data: metadata,
        );
        onTextChanged();
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: <Widget>[
          ProfilePicture3(
            size: 40,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {},
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _userInfo(context),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          CustomIconButton(
            onClicked: () {
              openProfileFastAccess(
                context: context,
                pubkey: metadata.pubkey,
              );
            },
            icon: FeatureIcons.shareExternal,
            size: 17,
            backgroundColor: kTransparent,
          ),
        ],
      ),
    );
  }

  Expanded _userInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (contactList.contains(metadata.pubkey)) ...[
                const SizedBox(
                  width: kDefaultPadding / 3,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Text(
                    context.t.youFollow.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ),
              ]
            ],
          ),
          Nip05Component(
            metadata: metadata,
            removeSpace: true,
            useNip05: true,
          ),
        ],
      ),
    );
  }
}

class MentioTags extends StatelessWidget {
  const MentioTags({
    super.key,
    required this.controller,
    required this.tags,
    required this.onTextChanged,
  });

  final MentionTagTextEditingController controller;
  final List<String> tags;
  final Function() onTextChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final tag = tags[index];

        return GestureDetector(
          onTap: () {
            controller.addMention(
              label: tag,
              data: tag,
            );
            onTextChanged();
          },
          behavior: HitTestBehavior.translucent,
          child: Row(
            children: <Widget>[
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      itemCount: tags.length,
    );
  }
}
