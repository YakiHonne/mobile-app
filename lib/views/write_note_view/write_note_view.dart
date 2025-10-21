// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../logic/metadata_cubit/metadata_cubit.dart';
import '../../logic/write_note_cubit/write_note_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../utils/utils.dart';
import '../smart_widgets_view/widgets/smart_widget_container.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_manager/dicover_settings_views/relay_settings_view.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/data_providers.dart';
import '../widgets/dotted_container.dart';
import '../widgets/note_container.dart';
import '../widgets/parsed_media_container.dart';
import '../widgets/profile_picture.dart';
import 'widgets/mention_text_field.dart';
import 'widgets/paid_note_process.dart';
import 'widgets/publish_media_container.dart';
import 'widgets/reply_container.dart';

class AddReply extends HookWidget {
  const AddReply({
    super.key,
    this.attachedEvent,
    this.replyContent,
    this.onSuccess,
    this.isMention,
  });

  final Map<String, dynamic>? replyContent;
  final BaseEventModel? attachedEvent;
  final bool? isMention;
  final Function(Event)? onSuccess;

  @override
  Widget build(BuildContext context) {
    final replyId = useState<String?>(null);
    final signer = useState(currentSigner!);
    final controller = useMemoized(() {
      replyId.value = getReplyId(replyContent);
      return MentionTagTextEditingController();
    }, []);

    useEffect(() {
      return () {
        controller.dispose();
      };
    }, [controller]);

    useEffect(() {
      if (controller.text.isEmpty) {
        try {
          if (replyContent == null) {
            controller.setText = nostrRepository.userDrafts?.noteDraft ?? '';
          } else {
            final id = getReplyId(replyContent);

            if (id != null) {
              controller.setText =
                  nostrRepository.userDrafts?.replies[id] ?? '';
            }
          }
        } catch (e) {
          lg.i(e);
        }
      }
      return null;
    }, []);

    return BlocProvider(
      create: (context) =>
          WriteNoteCubit(attachedEvent, isMention: isMention ?? false),
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const Center(child: ModalBottomSheetHandle()),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomIconButton(
                      onClicked: () => Navigator.pop(context),
                      icon: FeatureIcons.closeRaw,
                      size: 18,
                      vd: 0,
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                    Text(
                      context.t.compose.capitalizeFirst(),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    _publishNote(controller, signer),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Expanded(
                child: NoteWritingComponent(
                  replyContent: replyContent,
                  controller: controller,
                  isMention: isMention,
                  attachedEvent: attachedEvent,
                  replyId: replyId.value,
                  scrollController: scrollController,
                  signer: signer,
                  onSignerChanged: (s) {
                    signer.value = s;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BlocBuilder<WriteNoteCubit, WriteNoteState> _publishNote(
      MentionTagTextEditingController controller,
      ValueNotifier<EventSigner> signer) {
    return BlocBuilder<WriteNoteCubit, WriteNoteState>(
      builder: (context, state) {
        return CustomIconButton(
          onClicked: () {
            context.read<WriteNoteCubit>().postNote(
                  content: getRawText(controller),
                  replyContent: replyContent,
                  signer: signer.value,
                  useSourceRelay: false,
                  isPaid: false,
                  onPaymentProcess: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return BlocProvider.value(
                          value: context.read<WriteNoteCubit>(),
                          child: const PaidNoteProcess(),
                        );
                      },
                      isScrollControlled: true,
                      useRootNavigator: true,
                      useSafeArea: true,
                      elevation: 0,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
                  onSuccess: (ev) {
                    Navigator.pop(context);
                    onSuccess?.call(ev);
                  },
                );
          },
          icon: FeatureIcons.send,
          size: 20,
          vd: 0,
          iconColor: kWhite,
          backgroundColor: kMainColor,
        );
      },
    );
  }
}

class NoteWritingComponent extends HookWidget {
  const NoteWritingComponent({
    super.key,
    this.scrollController,
    this.replyContent,
    this.attachedEvent,
    this.isMention,
    this.isNewNote,
    this.replyId,
    this.isPaid,
    this.useSourceRelay,
    required this.controller,
    required this.signer,
    required this.onSignerChanged,
  });

  final ScrollController? scrollController;
  final Map<String, dynamic>? replyContent;
  final BaseEventModel? attachedEvent;
  final bool? isMention;
  final bool? isNewNote;
  final String? replyId;
  final MentionTagTextEditingController controller;
  final ValueNotifier<bool>? isPaid;
  final ValueNotifier<bool>? useSourceRelay;
  final ValueNotifier<EventSigner> signer;
  final Function(EventSigner) onSignerChanged;

  @override
  Widget build(BuildContext context) {
    final mention = useState<String?>(null);
    final debounceTimer = useRef<Timer?>(null);
    final focusNode = useFocusNode();

    // Handle delayed focus to reduce first-time lag
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Small delay to let the widget tree settle before focusing
        Future.delayed(const Duration(milliseconds: 500), () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
      });

      return () {
        debounceTimer.value = null;
      };
    }, []);

    void onTextChangedDebounced() {
      debounceTimer.value = Timer(const Duration(milliseconds: 500), () {
        final content = getRawText(controller);
        if (replyId != null) {
          nostrRepository.saveNoteReply(
            note: content,
            replyId: replyId!,
          );
        } else {
          nostrRepository.saveNote(note: content);
        }
      });
    }

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              controller: scrollController,
              children: [
                if (replyContent != null) ...[
                  ReplyContainer(replyContent: replyContent!),
                ],
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                _NoteInputSection(
                  controller: controller,
                  mention: mention,
                  focusNode: focusNode,
                  onTextChanged: onTextChangedDebounced,
                  signer: signer,
                ),
                _MediaPreviewSection(controller: controller),
                if (attachedEvent != null)
                  AttachedEventBox(attachedEvent: attachedEvent!),
              ],
            ),
          ),
        ),
        if (useSourceRelay != null) ...[
          NoteSelectedRelay(useSourceRelay: useSourceRelay),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        const Divider(
          thickness: 0.3,
          height: 0,
        ),
        PublishingMediaContainer(
          onImageAdd: (imageLinks) {
            context.read<WriteNoteCubit>().addImage(imageLinks);

            appendTextToPosition(
              controller: controller,
              textToAppend: imageLinks.join(' '),
            );

            onTextChangedDebounced();
          },
          isPaid: isPaid,
          isNewNote: isNewNote,
          controller: controller,
          mention: mention,
          onTextChanged: onTextChangedDebounced,
        ),
      ],
    );
  }
}

class NoteSelectedRelay extends StatelessWidget {
  const NoteSelectedRelay({
    super.key,
    required this.useSourceRelay,
  });

  final ValueNotifier<bool>? useSourceRelay;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final snc = appSettingsManagerCubit.getNoteSourceRelay();

        if (snc != null) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            margin: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            child: Row(
              children: [
                _relayInfo(context, snc),
                Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    value: useSourceRelay!.value,
                    onChanged: (isToggled) {
                      useSourceRelay!.value = !useSourceRelay!.value;
                    },
                    activeTrackColor: kMainColor,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Expanded _relayInfo(BuildContext context, String snc) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kDefaultPadding / 8,
        children: [
          Text(
            context.t.publishOnly.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          RelayInfoProvider(
            relay: snc,
            child: (relayInfo) => Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RelayImage(
                      isSelected: true,
                      url: snc,
                      relayInfo: relayInfo,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  Relay.removeSocket(snc) ?? snc,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreviewSection extends StatelessWidget {
  const _MediaPreviewSection({
    required this.controller,
  });

  final MentionTagTextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteNoteCubit, WriteNoteState>(
      builder: (context, state) {
        if (state.medias.isNotEmpty) {
          return Column(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 2,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.medias.length,
                      itemBuilder: (context, index) {
                        final m = state.medias[index];

                        return _mediaItem(m, context, index);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  AspectRatio _mediaItem(String m, BuildContext context, int index) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imageUrlRegex.hasMatch(m)
          ? _thumbnail(m, context, index)
          : _video(context, index, m),
    );
  }

  Stack _video(BuildContext context, int index, String m) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
            color: Theme.of(context).cardColor,
          ),
          child: Center(
            child: SvgPicture.asset(
              FeatureIcons.videoGallery,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            onPressed: () {
              context.read<WriteNoteCubit>().removeImage(index);
              controller.text = controller.text.replaceAll(
                m,
                '',
              );
            },
            icon: const Icon(
              Icons.close,
              color: kWhite,
            ),
            style: IconButton.styleFrom(
              backgroundColor: kBlack.withValues(alpha: 0.5),
            ),
          ),
        )
      ],
    );
  }

  Stack _thumbnail(String m, BuildContext context, int index) {
    return Stack(
      children: [
        CommonThumbnail(
          image: m,
          placeholder: getRandomPlaceholder(input: m, isPfp: false),
          width: double.infinity,
          height: 200,
          radius: kDefaultPadding / 2,
          isRound: true,
        ),
        Positioned(
          right: kDefaultPadding / 4,
          top: kDefaultPadding / 4,
          child: CustomIconButton(
            onClicked: () {
              final newText = controller.text.replaceFirst(m, '');
              controller.value = TextEditingValue(
                text: newText,
              );

              context.read<WriteNoteCubit>().removeImage(index);
            },
            icon: FeatureIcons.closeRaw,
            size: 18,
            vd: -2,
            backgroundColor:
                Theme.of(context).scaffoldBackgroundColor.withValues(
                      alpha: 0.5,
                    ),
          ),
        )
      ],
    );
  }
}

class _NoteInputSection extends StatelessWidget {
  const _NoteInputSection({
    required this.signer,
    required this.controller,
    required this.mention,
    required this.onTextChanged,
    required this.focusNode,
  });

  final ValueNotifier<EventSigner> signer;
  final MentionTagTextEditingController controller;
  final ValueNotifier<String?> mention;
  final VoidCallback onTextChanged;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pre-load account switcher to avoid initialization lag
          RepaintBoundary(
            child: NoteAccountsSwitcher(signer: signer),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          _mentionTextField(context),
        ],
      ),
    );
  }

  Expanded _mentionTextField(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: kDefaultPadding / 3),
          RepaintBoundary(
            child: ClipboardPasteMentionTextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              onMention: (value) async {
                mention.value = value;
              },
              onChanged: (_) {
                onTextChanged();
              },
              mentionTagDecoration: MentionTagDecoration(
                maxWords: null,
                mentionTextStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: kMainColor),
              ),
              style: Theme.of(context).textTheme.bodyMedium!,
              decoration: InputDecoration(
                hintText: context.t.writeSomething.capitalizeFirst(),
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                focusColor: Theme.of(context).primaryColorLight,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteAccountsSwitcher extends HookWidget {
  const NoteAccountsSwitcher({
    super.key,
    required this.signer,
  });

  final ValueNotifier<EventSigner?> signer;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataCubit, MetadataState>(
      builder: (context, state) {
        return SizedBox(
          width: 35,
          child: Column(
            children: [
              RepaintBoundary(
                child: MetadataProvider(
                  child: (metadata, isNip05Valid) => ProfilePicture2(
                    size: 35,
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
                  pubkey: signer.value!.getPublicKey(),
                ),
              ),
              ConnectedUsersList(
                signer: signer,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConnectedUsersList extends HookWidget {
  const ConnectedUsersList({
    required this.signer,
    super.key,
  });

  final ValueNotifier<EventSigner?> signer;

  @override
  Widget build(BuildContext context) {
    final privateKeys = useState(settingsCubit.getPrivateKeys());
    final isListExpanded = useState(false);

    // Memoize the processed user data to avoid recalculating on every build
    final processedUsers = useMemoized(() {
      return privateKeys.value
          .map((p) {
            final isExternal = settingsCubit.isExternalSignerKeyIndex(
              int.tryParse(p.key) ?? -1,
            );

            final pubkey =
                isExternal ? p.value : Keychain.getPublicKey(p.value);

            return {
              'privateKey': p,
              'isExternal': isExternal,
              'pubkey': pubkey,
            };
          })
          .where((user) => user['pubkey'] != signer.value!.getPublicKey())
          .toList();
    }, [privateKeys.value, signer.value?.getPublicKey()]);

    return privateKeys.value.length <= 1
        ? const SizedBox.shrink()
        : Column(
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: Column(
                  children: [
                    const Divider(
                      thickness: 0.5,
                      height: kDefaultPadding,
                    ),
                    _usersList(processedUsers, isListExpanded),
                  ],
                ),
                secondChild: const SizedBox(width: 35),
                crossFadeState: isListExpanded.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
              ),
              CustomIconButton(
                onClicked: () {
                  isListExpanded.value = !isListExpanded.value;
                },
                icon: !isListExpanded.value
                    ? FeatureIcons.arrowDown
                    : FeatureIcons.arrowUp,
                size: 20,
                backgroundColor: kTransparent,
              ),
            ],
          );
  }

  ConstrainedBox _usersList(List<Map<String, Object>> processedUsers,
      ValueNotifier<bool> isListExpanded) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: ScrollShadow(
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final user = processedUsers[index];
            final p = user['privateKey']! as MapEntry<String, String>;
            final isExternal = user['isExternal']! as bool;
            final pubkey = user['pubkey']! as String;

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 8,
              ),
              child: _UserListItem(
                pubkey: pubkey,
                privateKey: p,
                isExternal: isExternal,
                onTap: () {
                  if (isExternal) {
                    signer.value = AmberEventSigner(pubkey);
                  } else {
                    signer.value = Bip340EventSigner(
                      p.value,
                      pubkey,
                    );
                  }
                  isListExpanded.value = false;
                },
              ),
            );
          },
          itemCount: processedUsers.length,
        ),
      ),
    );
  }
}

// Extract list item into separate widget to optimize rebuilds
class _UserListItem extends StatelessWidget {
  const _UserListItem({
    required this.pubkey,
    required this.privateKey,
    required this.isExternal,
    required this.onTap,
  });

  final String pubkey;
  final MapEntry<String, String> privateKey;
  final bool isExternal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MetadataProvider(
        child: (metadata, isNip05Valid) => ProfilePicture2(
          size: 35,
          image: metadata.picture,
          pubkey: metadata.pubkey,
          padding: 0,
          strokeWidth: 0,
          strokeColor: kTransparent,
          onClicked: onTap,
        ),
        pubkey: pubkey,
      ),
    );
  }
}

String getRawText(MentionTagTextEditingController controller) {
  final text = controller.text;
  final mentions = controller.mentions;

  return text.replaceAllMapped(mentionToken, (match) {
    final removedMention = mentions.removeAt(0);

    if (removedMention is Metadata) {
      return 'nostr:${Nip19.encodePubkey(removedMention.pubkey)}';
    } else {
      return '#$removedMention';
    }
  });
}

String? getReplyId(Map<String, dynamic>? replyContent) {
  try {
    if (replyContent != null) {
      final data = replyContent['replyData'] as List<List<String>>?;
      if (data != null) {
        String? root;
        String? reply;

        for (final s in data) {
          if (s[0] == 'e' && s.length >= 4 && s[3] == 'reply') {
            reply = s[1];
          } else if ((s[0] == 'e' || s[0] == 'a') &&
              s.length >= 4 &&
              s[3] == 'root') {
            root = s[1];
          }
        }

        return reply ?? root;
      }

      return null;
    } else {
      return null;
    }
  } catch (_) {
    return null;
  }
}

class AttachedEventBox extends StatelessWidget {
  const AttachedEventBox({super.key, required this.attachedEvent});

  final BaseEventModel attachedEvent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Builder(
        builder: (context) {
          if (attachedEvent is DetailedNoteModel) {
            return NoteContainer(
              note: attachedEvent as DetailedNoteModel,
            );
          } else if (attachedEvent is SmartWidget) {
            return SmartWidgetComponent(
              smartWidget: attachedEvent as SmartWidget,
              disableWidget: true,
            );
          } else {
            return ParsedMediaContainer(
              baseEventModel: attachedEvent,
              canBeAccesed: false,
            );
          }
        },
      ),
    );
  }
}
