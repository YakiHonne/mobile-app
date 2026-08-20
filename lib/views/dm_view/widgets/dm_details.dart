// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/metadata_cubit/metadata_cubit.dart';
import '../../../models/dm_models.dart';
import '../../../models/flash_news_model.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../giphy_view/giphy_view.dart';
import '../../profile_view/profile_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_pull_down_button.dart';
import '../../widgets/fluid_scaffold.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/pull_down_global_button.dart';
import '../../widgets/response_snackbar.dart';
import 'camera_options_view.dart';
import 'dm_gift_widget.dart';
import 'dm_redeem_widget.dart';
import 'send_gift_view.dart';

/// Main DM Details screen with messaging functionality
class DmDetails extends HookWidget {
  static const routeName = '/dmDetailsView';

  // Constants
  static const double _imageContainerHeight = 70.0;
  static const double _imageSize = 60.0;
  static const double _profilePictureSize = 30.0;
  static const int _maxTextLines = 3;
  static const int _minTextLines = 1;
  static const Duration _scrollDuration = Duration(seconds: 1);

  static Route route(RouteSettings settings) {
    final data = settings.arguments! as List;
    nostrRepository.usersMessageNotifications.add(data[0]);

    return CupertinoPageRoute(
      builder: (_) => DmDetails(pubkey: data[0]),
    );
  }

  DmDetails({super.key, required this.pubkey}) {
    umamiAnalytics.trackEvent(screenName: 'Private message details view');
  }

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController(
      text: nostrRepository.getDmDraft(
        pubkey: currentSigner!.getPublicKey(),
        peer: pubkey,
      ),
    );
    final scrollController = useScrollController();
    final isShrinked = useState(false);
    final replyId = useState<String?>(null);
    final replyPubkey = useState<String?>(null);
    final replyText = useState<String?>(null);
    final showNip44Message = useState<bool>(true);
    final images = useState(<String>[]);
    final isImageUploading = useState(false);
    final isSelectionMode = useState(false);
    final selectedEvents = useState(<String>{});

    useEffect(() {
      return () => nostrRepository.usersMessageNotifications.remove(pubkey);
    }, []);

    final appBar = DmAppBar(
      pubkey: pubkey,
      isSelectionMode: isSelectionMode,
      selectedEvents: selectedEvents,
      onDelete: () {
        showCupertinoDeletionDialogue(
          context: context,
          title: context.t.deleteMessage.capitalizeFirst(),
          description: context.t.deleteMessageDesc.capitalizeFirst(),
          buttonText: context.t.delete.capitalizeFirst(),
          onDelete: () async {
            await dmsCubit.deleteMessages(
              pubkey,
              selectedEvents.value.toList(),
            );
            isSelectionMode.value = false;
            selectedEvents.value = {};
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        );
      },
    );

    return FluidScaffold(
      leading: appBar.leading(context),
      titleWidget: appBar.title(context),
      actions: appBar.actions(context),
      body: SafeArea(
        // top: false — fluidScaffoldTopInset already includes the status bar,
        // so leaving SafeArea's top on would count it twice.
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _buildMessagesList(
                context,
                scrollController,
                replyId,
                replyPubkey,
                replyText,
                showNip44Message,
                isSelectionMode,
                selectedEvents,
              ),
            ),
            _buildMessageInput(
              context,
              textEditingController,
              scrollController,
              replyId,
              replyPubkey,
              replyText,
              images,
              isImageUploading,
              isShrinked,
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Messages List

  Widget _buildMessagesList(
    BuildContext context,
    ScrollController scrollController,
    ValueNotifier<String?> replyId,
    ValueNotifier<String?> replyPubkey,
    ValueNotifier<String?> replyText,
    ValueNotifier<bool> showNip44Message,
    ValueNotifier<bool> isSelectionMode,
    ValueNotifier<Set<String>> selectedEvents,
  ) {
    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, state) {
        return Stack(
          children: [
            Positioned.fill(
              child: _buildMessagesContent(
                context,
                scrollController,
                replyId,
                replyPubkey,
                replyText,
                isSelectionMode,
                selectedEvents,
              ),
            ),
            if (!state.isUsingNip44 && showNip44Message.value)
              _buildSecurityNotice(context, showNip44Message),
            ChatResetScrollButton(scrollController: scrollController),
          ],
        );
      },
    );
  }

  Widget _buildMessagesContent(
    BuildContext context,
    ScrollController scrollController,
    ValueNotifier<String?> replyId,
    ValueNotifier<String?> replyPubkey,
    ValueNotifier<String?> replyText,
    ValueNotifier<bool> isSelectionMode,
    ValueNotifier<Set<String>> selectedEvents,
  ) {
    return BlocBuilder<DmsCubit, DmsState>(
      buildWhen: (previous, current) => previous.rebuild != current.rebuild,
      builder: (context, state) {
        final dm = state.dmSessionDetails[pubkey];

        if (dm == null || dm.dmSession.length() == 0) {
          return _buildEmptyState(context);
        }

        return ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView.custom(
            reverse: true,
            controller: scrollController,
            // top padding clears the GlassAppBar; the list is reverse:true so
            // top maps to the trailing edge, where old messages scroll under it.
            padding: EdgeInsets.only(
              top: kDefaultPadding + fluidScaffoldTopInset(context),
              bottom: kDefaultPadding,
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) => _buildMessageItem(
                context,
                dm,
                index,
                replyId,
                replyPubkey,
                replyText,
                isSelectionMode,
                selectedEvents,
              ),
              childCount: dm.dmSession.length(),
              findChildIndexCallback: (Key key) {
                final valueKey = key as GlobalObjectKey;
                final index = dm.dmSession.getAll().indexWhere(
                      (message) => message.id == valueKey.value,
                    );

                return index == -1 ? null : index;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: EmptyList(
        description: context.t.noMessagesToDisplay.capitalizeFirst(),
        icon: FeatureIcons.dms,
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    DMSessionDetail dm,
    int index,
    ValueNotifier<String?> replyId,
    ValueNotifier<String?> replyPubkey,
    ValueNotifier<String?> replyText,
    ValueNotifier<bool> isSelectionMode,
    ValueNotifier<Set<String>> selectedEvents,
  ) {
    final event = dm.dmSession.get(index);
    return BlocBuilder<MetadataCubit, MetadataState>(
      key: GlobalObjectKey(event!.id),
      builder: (context, state) {
        final isCurrentUser = event.pubkey == currentSigner!.getPublicKey();
        final peerUserPubkey = !isCurrentUser ? event.pubkey : null;
        final ownUserPubkey = isCurrentUser ? event.pubkey : null;
        final isSelected = selectedEvents.value.contains(event.id);

        return GestureDetector(
          onTap: isSelectionMode.value
              ? () {
                  if (!isCurrentUser) {
                    return;
                  }

                  if (isSelected) {
                    selectedEvents.value = Set.from(selectedEvents.value)
                      ..remove(event.id);
                  } else {
                    selectedEvents.value = Set.from(selectedEvents.value)
                      ..add(event.id);
                  }
                }
              : null,
          child: Slidable(
            enabled: !isSelectionMode.value,
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.2,
              children: [
                Expanded(
                  child: Builder(builder: (context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconButton(
                          onClicked: () async {
                            final content = await dmsCubit.getMessage(event);
                            final message = content.first.trim();

                            replyText.value = message;
                            replyId.value = event.id;
                            replyPubkey.value =
                                isCurrentUser ? ownUserPubkey : peerUserPubkey;

                            if (context.mounted) {
                              Slidable.of(context)?.close();
                            }
                          },
                          icon: FeatureIcons.reply,
                          size: 20,
                          backgroundColor: Theme.of(context).cardColor,
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
            child: DmChatContainer(
              event: event,
              dmSession: dm.dmSession,
              isCurrentUser: isCurrentUser,
              dmSessionDetail: dm,
              peerUserPubkey: peerUserPubkey,
              ownUserPubkey: ownUserPubkey,
              scrollToIndex: (id) => _scrollToMessage(id),
              onMessageReply: (messageId, message, pubkey) {
                replyId.value = messageId;
                replyText.value = message;
                replyPubkey.value = pubkey;
              },
              onSelect: isCurrentUser
                  ? () {
                      isSelectionMode.value = true;
                      selectedEvents.value = {event.id};
                    }
                  : null,
              isSelected: isSelected,
            ),
          ),
        );
      },
    );
  }

  Future<void> _scrollToMessage(String id) async {
    final componentContext = GlobalObjectKey(id).currentContext;
    if (componentContext != null) {
      await Scrollable.ensureVisible(
        componentContext,
        duration: _scrollDuration,
        alignment: 0.5,
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Widget _buildSecurityNotice(
    BuildContext context,
    ValueNotifier<bool> showNip44Message,
  ) {
    return Positioned(
      // Below the GlassAppBar, same inset the message list clears by.
      top: kDefaultPadding / 2 + fluidScaffoldTopInset(context),
      left: kDefaultPadding / 2,
      right: kDefaultPadding / 2,
      child: Material(
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.triangleAlert,
                  color: Theme.of(context).primaryColor),
              const SizedBox(width: kDefaultPadding / 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Security Notice',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: kDefaultPadding / 8),
                    Text(
                      context.t.enableSecureDmsMessage.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              CustomIconButton(
                onClicked: () => showNip44Message.value = false,
                icon: FeatureIcons.closeRaw,
                size: 18,
                backgroundColor: kTransparent,
                vd: -4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Message Input

  Widget _buildMessageInput(
    BuildContext context,
    TextEditingController textEditingController,
    ScrollController scrollController,
    ValueNotifier<String?> replyId,
    ValueNotifier<String?> replyPubkey,
    ValueNotifier<String?> replyText,
    ValueNotifier<List<String>> images,
    ValueNotifier<bool> isImageUploading,
    ValueNotifier<bool> isShrinked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: kDefaultPadding / 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyId.value != null)
            _buildReplyPreview(context, replyId, replyPubkey, replyText),
          DmTextfieldBox(
            textEditingController: textEditingController,
            pubkey: pubkey,
            replyId: replyId,
            replyPubkey: replyPubkey,
            replyText: replyText,
            scrollController: scrollController,
            images: images,
            isImageUploading: isImageUploading,
            isShrinked: isShrinked,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(
    BuildContext context,
    ValueNotifier<String?> replyId,
    ValueNotifier<String?> replyPubkey,
    ValueNotifier<String?> replyText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MetadataProvider(
                  pubkey: pubkey,
                  child: (metadata, isNip05Valid) {
                    return Text(
                      context.t.replyingTo(name: metadata.getName()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    );
                  },
                ),
                const SizedBox(height: kDefaultPadding / 6),
                Text(
                  replyText.value!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _clearReply(replyId, replyPubkey, replyText),
            icon: const Icon(LucideIcons.x),
          ),
        ],
      ),
    );
  }

  void _clearReply(
    ValueNotifier<String?> replyId,
    ValueNotifier<String?> replyPubkey,
    ValueNotifier<String?> replyText,
  ) {
    replyId.value = null;
    replyText.value = null;
    replyPubkey.value = null;
  }
}

/// Text input widget with image handling and media options
class DmTextfieldBox extends StatelessWidget {
  const DmTextfieldBox({
    super.key,
    required this.textEditingController,
    required this.pubkey,
    required this.replyId,
    required this.replyPubkey,
    required this.replyText,
    required this.isImageUploading,
    required this.images,
    required this.scrollController,
    required this.isShrinked,
  });

  final TextEditingController textEditingController;
  final String pubkey;
  final ValueNotifier<String?> replyId;
  final ValueNotifier<String?> replyPubkey;
  final ValueNotifier<String?> replyText;
  final ValueNotifier<bool> isImageUploading;
  final ValueNotifier<List<String>> images;
  final ScrollController scrollController;
  final ValueNotifier<bool> isShrinked;

  // Constants
  static const double _iconSize = 20.0;
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _scrollDuration = Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, state) {
        return Column(
          children: [
            if (isImageUploading.value || images.value.isNotEmpty)
              _buildImagePreview(),
            _buildTextInputRow(context, state),
          ],
        );
      },
    );
  }

  // MARK: - Image Preview

  Widget _buildImagePreview() {
    return Column(
      children: [
        SizedBox(
          height: DmDetails._imageContainerHeight,
          child: ListView.separated(
            padding: EdgeInsets.only(left: isShrinked.value ? 35 : 92),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              if (index == 0 && isImageUploading.value) {
                return const LoadingImageContainer();
              }
              final imageIndex = isImageUploading.value ? index - 1 : index;
              final image = images.value[imageIndex];
              return DmImageContainer(
                url: image,
                onDelete: () => _removeImage(imageIndex),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(width: kDefaultPadding / 4),
            itemCount: isImageUploading.value
                ? images.value.length + 1
                : images.value.length,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 4),
      ],
    );
  }

  void _removeImage(int index) {
    images.value = List<String>.from(images.value)..removeAt(index);
  }

  // MARK: - Text Input Row

  Widget _buildTextInputRow(BuildContext context, DmsState state) {
    return Row(
      children: [
        _buildMediaButtons(context),
        Expanded(
          child: _buildTextField(context, state),
        ),
      ],
    );
  }

  Widget _buildMediaButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildExpandedMediaButtons(context),
          crossFadeState: isShrinked.value
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: _animationDuration,
        ),
        const SizedBox(width: kDefaultPadding / 2),
        _buildToggleButton(),
        const SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }

  Widget _buildExpandedMediaButtons(BuildContext context) {
    return Row(
      children: [
        _buildGiftButton(context),
        const SizedBox(width: kDefaultPadding / 2),
        _buildGiphyButton(context),
        const SizedBox(width: kDefaultPadding / 2),
        _buildCameraButton(context),
      ],
    );
  }

  Widget _buildGiphyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGiphyView(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 8),
        child: SvgPicture.asset(
          FeatureIcons.gif,
          width: _iconSize,
          height: _iconSize,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildGiftButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGiftView(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 8),
        child: AppIcon(
          FeatureIcons.dmGift,
          size: _iconSize,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }

  Widget _buildCameraButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCameraOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 8),
        child: AppIcon(
          FeatureIcons.camera,
          size: _iconSize,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () => isShrinked.value = !isShrinked.value,
      child: AnimatedRotation(
        duration: _animationDuration,
        turns: isShrinked.value ? 0 : 0.5,
        child: const Icon(LucideIcons.chevronRight, size: _iconSize),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, DmsState state) {
    return TextField(
      controller: textEditingController,
      textCapitalization: TextCapitalization.sentences,
      contextMenuBuilder: _contextMenuBuilder,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (text) => _saveDraft(text),
      decoration: InputDecoration(
        hintText: context.t.writeYourMessage.capitalizeFirst(),
        suffixIcon: _buildSendButton(context, state),
      ),
      maxLines: DmDetails._maxTextLines,
      minLines: DmDetails._minTextLines,
    );
  }

  Widget _buildSendButton(BuildContext context, DmsState state) {
    return IconButton(
      onPressed: () => _sendMessage(context, state),
      icon: AppIcon(
        FeatureIcons.send,
        size: _iconSize,
        color: Theme.of(context).primaryColorDark,
      ),
    );
  }

  // MARK: - Actions

  void _showGiphyView(BuildContext context) {
    showAppModalSheet(
      context: context,
      builder: (_) => GiphyView(
        onGifSelected: (link) => context.read<DmsCubit>().sendEvent(
              pubkey,
              link,
              '',
              () {},
            ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  void _showCameraOptions(BuildContext context) {
    showAppModalSheet(
      context: context,
      builder: (_) => CameraOptions(
        pubkey: pubkey,
        replyId: replyId.value,
        onFailed: () {},
        onSuccess: () {
          _clearReplyAndScroll();
          Navigator.pop(context);
        },
      ),
      backgroundColor: kTransparent,
    );
  }

  void _showGiftView(BuildContext context) {
    showAppModalSheet(
      context: context,
      builder: (_) => SendGiftView(receiverPubkey: pubkey),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  void _saveDraft(String text) {
    nostrRepository.setDmsDraft(
      pubkey: currentSigner!.getPublicKey(),
      peer: pubkey,
      draft: text,
    );
  }

  void _sendMessage(BuildContext context, DmsState state) {
    if (state.isSendingMessage) {
      return;
    }

    final text = textEditingController.text.trim();
    final imagesString = images.value.join(' ').trim();

    if (text.isNotEmpty || images.value.isNotEmpty) {
      final finalText = _buildFinalMessage(text, imagesString);

      context.read<DmsCubit>().sendEvent(
        pubkey,
        finalText,
        replyId.value,
        () {
          _clearMessageInput();
          _clearReplyAndScroll();
        },
      );
    }
  }

  String _buildFinalMessage(String text, String imagesString) {
    if (imagesString.isEmpty) {
      return text;
    }
    if (text.isEmpty) {
      return imagesString;
    }
    return '$imagesString $text';
  }

  void _clearMessageInput() {
    images.value = [];
    isImageUploading.value = false;
    textEditingController.clear();
    nostrRepository.deleteDmDraft(
      pubkey: currentSigner!.getPublicKey(),
      peer: pubkey,
    );
  }

  void _clearReplyAndScroll() {
    replyId.value = null;
    replyPubkey.value = null;
    replyText.value = null;

    if ((dmsCubit.state.dmSessionDetails[pubkey]?.dmSession.length() ?? 0) >
        0) {
      scrollController.animateTo(
        0.0,
        duration: _scrollDuration,
        curve: Curves.easeOut,
      );
    }
  }

  // MARK: - Context Menu & Clipboard

  Widget _contextMenuBuilder(
      BuildContext context, EditableTextState editableTextState) {
    final List<ContextMenuButtonItem> buttonItems = [];
    final TextEditingValue value = editableTextState.textEditingValue;

    if (!editableTextState.widget.readOnly && !value.selection.isCollapsed) {
      buttonItems.add(ContextMenuButtonItem(
        label: 'Cut',
        onPressed: () {
          editableTextState.cutSelection(SelectionChangedCause.toolbar);
          ContextMenuController.removeAny();
        },
      ));
    }

    if (!value.selection.isCollapsed) {
      buttonItems.add(ContextMenuButtonItem(
        label: 'Copy',
        onPressed: () {
          editableTextState.copySelection(SelectionChangedCause.toolbar);
          ContextMenuController.removeAny();
        },
      ));
    }

    buttonItems.add(ContextMenuButtonItem(
      label: 'Paste',
      onPressed: () {
        _handlePaste(context);
        ContextMenuController.removeAny();
      },
    ));

    if (value.text.isNotEmpty && value.selection.isCollapsed) {
      buttonItems.add(ContextMenuButtonItem(
        label: 'Select All',
        onPressed: () =>
            editableTextState.selectAll(SelectionChangedCause.toolbar),
      ));
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Future<void> _handlePaste(BuildContext context) async {
    final imageUrl = await mediaServersCubit.pasteImage(
      () => _pasteText(context),
      (status) => isImageUploading.value = status,
    );

    if (imageUrl != null && context.mounted) {
      images.value = List<String>.from(images.value)..insert(0, imageUrl);
    }
  }

  Future<void> _pasteText(BuildContext context) async {
    try {
      final clipboardText = await getClipboardTextSafely();

      if (clipboardText != null) {
        final text = clipboardText;
        final selection = textEditingController.selection;
        final currentText = textEditingController.text;

        final newText =
            currentText.replaceRange(selection.start, selection.end, text);
        textEditingController.text = newText;
        textEditingController.selection = TextSelection.collapsed(
          offset: selection.start + text.length,
        );
      }
    } catch (e) {
      lg.i(e);
    }
  }
}

/// Loading indicator for image uploads
class LoadingImageContainer extends StatelessWidget {
  const LoadingImageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: DmDetails._imageSize,
          width: DmDetails._imageSize,
          margin: const EdgeInsets.all(kDefaultPadding / 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SpinKitCircle(color: Theme.of(context).primaryColor, size: 20),
        ),
      ],
    );
  }
}

/// Container for displaying uploaded images with delete option
class DmImageContainer extends StatelessWidget {
  const DmImageContainer({
    super.key,
    required this.url,
    required this.onDelete,
  });

  final String url;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: DmDetails._imageSize,
          width: DmDetails._imageSize,
          margin: const EdgeInsets.all(kDefaultPadding / 4),
          child: CommonThumbnail(
            image: url,
            radius: kDefaultPadding / 2,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: CustomIconButton(
            onClicked: onDelete,
            icon: FeatureIcons.closeRaw,
            size: 15,
            backgroundColor: Theme.of(context).cardColor,
            vd: -4,
          ),
        ),
      ],
    );
  }
}

/// Custom app bar for DM screen
/// The DM header's three [FluidScaffold] slots. Was a `PreferredSizeWidget`
/// wrapping its own `AppBar`; now it hands the pieces to the shared scaffold so
/// the fluid path gets a real `GlassAppBar` instead of a flat Material one.
class DmAppBar {
  const DmAppBar({
    required this.pubkey,
    required this.isSelectionMode,
    required this.selectedEvents,
    this.onDelete,
  });

  final String pubkey;
  final ValueNotifier<bool> isSelectionMode;
  final ValueNotifier<Set<String>> selectedEvents;
  final VoidCallback? onDelete;

  /// Null on the normal path, so FluidScaffold supplies its own back chevron.
  Widget? leading(BuildContext context) {
    if (!isSelectionMode.value) {
      return null;
    }

    return IconButton(
      onPressed: () {
        isSelectionMode.value = false;
        selectedEvents.value = {};
      },
      icon: const Icon(LucideIcons.x),
    );
  }

  Widget title(BuildContext context) {
    if (isSelectionMode.value) {
      return Text(
        '${selectedEvents.value.length} ${context.t.selected.capitalizeFirst()}',
        style: Theme.of(context).textTheme.titleMedium,
      );
    }

    return _buildTitle(context);
  }

  List<Widget> actions(BuildContext context) {
    if (isSelectionMode.value) {
      return [
        IconButton(
          onPressed: selectedEvents.value.isEmpty ? null : onDelete,
          icon: AppIcon(
            FeatureIcons.trash,
            size: 20,
            color: selectedEvents.value.isEmpty ? kDimGrey : kRed,
          ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
      ];
    }

    return [
      // _buildTitle brings its own MetadataProvider, so the options button
      // needs one too now that they're separate slots.
      MetadataProvider(
        pubkey: pubkey,
        child: (metadata, isNip05Valid) =>
            _buildMoreOptionsButton(context, metadata),
      ),
    ];
  }

  Widget _buildMoreOptionsButton(BuildContext context, dynamic metadata) {
    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, state) {
        return PullDownGlobalButton(
          model: LightMetadata(
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(metadata.createdAt * 1000),
            pubkey: metadata.pubkey,
            id: metadata.pubkey,
          ),
          enableSecureMessage: true,
          secureMessagesStatus: dmsCubit.state.isUsingNip44,
          enableZap: true,
          enableMute: true,
          muteStatus: state.mutes.contains(metadata.pubkey),
          useFluidMode: true,
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Navigator.pushNamed(
            context,
            ProfileView.routeName,
            arguments: [pubkey],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
            child: FluidBlurContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding / 6,
              ),
              child: Row(
                children: [
                  ProfilePicture2(
                    size: DmDetails._profilePictureSize,
                    image: metadata.picture,
                    pubkey: metadata.pubkey,
                    padding: 0,
                    strokeWidth: 0,
                    reduceSize: true,
                    strokeColor: kTransparent,
                    onClicked: () => openProfileFastAccess(
                      context: context,
                      pubkey: metadata.pubkey,
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding / 3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          metadata.getName(),
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (isNip05Valid)
                          _buildVerifiedBadge(context, metadata),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifiedBadge(BuildContext context, dynamic metadata) {
    return Row(
      children: [
        Text(
          metadata.nip05,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(width: kDefaultPadding / 4),
        AppIcon(
          FeatureIcons.verified,
          size: 15,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: kDefaultPadding / 4),
      ],
    );
  }
}

/// Individual chat message container
class DmChatContainer extends HookWidget {
  const DmChatContainer({
    super.key,
    required this.event,
    required this.dmSession,
    required this.isCurrentUser,
    required this.dmSessionDetail,
    required this.peerUserPubkey,
    required this.ownUserPubkey,
    required this.onMessageReply,
    required this.scrollToIndex,
    this.onSelect,
    this.isSelected = false,
  });

  final Event event;
  final DMSession dmSession;
  final bool isCurrentUser;
  final DMSessionDetail dmSessionDetail;
  final String? peerUserPubkey;
  final String? ownUserPubkey;
  final Function(String, String, String) onMessageReply;
  final Function(String) scrollToIndex;
  final VoidCallback? onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final copiedText = useState<String?>(null);
    final replyId = useState<String?>(null);
    final contentText = useState('');

    useMemoized(() async {
      final content = await dmsCubit.getMessage(event);

      if (context.mounted) {
        contentText.value = content.first.trim();
        replyId.value = content.last;
        copiedText.value = content.first.trim();
      }
    });

    useAutomaticKeepAlive();

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isSelected) ...[
                Icon(
                  LucideIcons.circleCheck,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: kDefaultPadding / 2),
              ],
              if (!isCurrentUser) ...[
                MetadataProvider(
                  pubkey: peerUserPubkey!,
                  child: (metadata, p1) =>
                      _buildProfilePicture(context, metadata),
                ),
                const SizedBox(width: kDefaultPadding / 2),
              ],
              if (isCurrentUser) _buildContextMenu(context, copiedText.value),
              Flexible(
                child: GestureDetector(
                  onLongPress: onSelect,
                  child: _buildMessageContainer(
                    context,
                    isTablet,
                    contentText.value,
                    replyId.value,
                  ),
                ),
              ),
              if (!isCurrentUser) _buildContextMenu(context, copiedText.value),
              if (isCurrentUser) ...[
                const SizedBox(width: kDefaultPadding / 2),
                MetadataProvider(
                  pubkey: ownUserPubkey!,
                  child: (metadata, p1) =>
                      _buildProfilePicture(context, metadata),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context, Metadata userModel) {
    return ProfilePicture3(
      size: DmDetails._profilePictureSize,
      image: userModel.picture,
      pubkey: userModel.pubkey,
      padding: 0,
      strokeWidth: 0,
      strokeColor: kTransparent,
      onClicked: () => openProfileFastAccess(
        context: context,
        pubkey: userModel.pubkey,
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, String? copiedText) {
    return ChatContainerPullDownMenu(
      eventId: event.id,
      copiedText: copiedText,
      onDelete: isCurrentUser
          ? () {
              showCupertinoDeletionDialogue(
                context: context,
                title: context.t.deleteMessage.capitalizeFirst(),
                description: context.t.deleteMessageDesc.capitalizeFirst(),
                buttonText: context.t.delete.capitalizeFirst(),
                onDelete: () async {
                  await dmsCubit.deleteMessage(
                    dmSessionDetail.info.peerPubkey,
                    event.id,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }
          : null,
      onSelect: onSelect,
      onMessageReply: () {
        if (copiedText != null) {
          onMessageReply.call(
            event.id,
            copiedText,
            isCurrentUser ? ownUserPubkey! : peerUserPubkey!,
          );
        }
      },
    );
  }

  Widget _buildMessageContainer(
    BuildContext context,
    bool isTablet,
    String contentText,
    String? replyId,
  ) {
    final redeemCode = _redeemCode(contentText);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      constraints: BoxConstraints(
        maxWidth: isTablet ? 50.w : double.infinity,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser ? Theme.of(context).cardColor : null,
        gradient: isCurrentUser
            ? null
            : const LinearGradient(
                colors: [Color(0xff392D69), Color(0xffB57BEE)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyId != null) _buildReplySection(context, replyId),
          if (_isGift(contentText))
            DMGiftWidget(token: contentText, isCurrentUser: isCurrentUser)
          else if (redeemCode != null)
            DMRedeemWidget(text: contentText, code: redeemCode)
          else
            _buildMessageContent(context, contentText),
          const SizedBox(height: kDefaultPadding / 4),
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildReplySection(BuildContext context, String replyId) {
    final searchedEvent = dmSession.getById(replyId);
    if (searchedEvent == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => scrollToIndex.call(searchedEvent.id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
        child: IntrinsicHeight(
          child: Row(
            children: [
              const VerticalDivider(thickness: 2, width: 0, color: kRed),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 3,
                  ),
                  child: FutureBuilder(
                    future: dmsCubit.getMessage(searchedEvent),
                    builder: (context, snapshot) {
                      final text =
                          snapshot.hasData ? snapshot.data!.first.trim() : '';
                      return ParsedText(
                        text: text,
                        color: isCurrentUser ? null : kWhite,
                        useDetailedNote: true,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, String contentText) {
    return ParsedText(
      text: contentText,
      color: isCurrentUser ? null : kWhite,
      inverseNoteColor: true,
      enableTruncation: false,
      useDetailedNote: true,
      isDm: true,
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return BlocBuilder<DmsCubit, DmsState>(
      buildWhen: (previous, current) =>
          previous.pendingEventIds.contains(event.id) !=
          current.pendingEventIds.contains(event.id),
      builder: (context, state) {
        final isPending = state.pendingEventIds.contains(event.id);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending)
              Padding(
                padding: const EdgeInsets.only(right: kDefaultPadding / 4),
                child: SpinKitCircle(
                  color: isCurrentUser
                      ? Theme.of(context).primaryColor
                      : kTransparent,
                  size: 15,
                ),
              )
            else
              AppIcon(
                event.kind == EventKind.DIRECT_MESSAGE
                    ? FeatureIcons.nonSecure
                    : FeatureIcons.secure,
                size: 15,
                color: !isCurrentUser
                    ? kWhite
                    : event.kind == EventKind.DIRECT_MESSAGE
                        ? Theme.of(context)
                            .primaryColorDark
                            .withValues(alpha: 0.5)
                        : kGreen,
              ),
            const SizedBox(width: kDefaultPadding / 4),
            Flexible(
              child: Text(
                dateFormat3.format(
                  DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
                ),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontStyle: FontStyle.italic,
                      color: !isCurrentUser
                          ? kWhite
                          : Theme.of(context)
                              .primaryColorDark
                              .withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Redeem codes are only trusted from the YakiHonne gateway, never from
  /// arbitrary peers — the card is the app vouching for the message.
  String? _redeemCode(String text) {
    if (isCurrentUser || event.pubkey != redeemTrustedSender) {
      return null;
    }

    return extractRedeemCode(text);
  }

  bool _isGift(String text) {
    if (text.isEmpty) {
      return false;
    }
    final parts = text.split('.');
    return parts.length == 3 && !text.contains(' ');
  }
}

/// Context menu for chat messages
class ChatContainerPullDownMenu extends StatelessWidget {
  const ChatContainerPullDownMenu({
    super.key,
    required this.eventId,
    required this.copiedText,
    required this.onMessageReply,
    this.onDelete,
    this.onSelect,
  });

  final String eventId;
  final String? copiedText;
  final VoidCallback onMessageReply;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return FluidPullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelLarge;
        return [
          PullDownMenuItem(
            title: context.t.copy.capitalizeFirst(),
            onTap: () => _handleCopy(context),
            itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
            iconWidget: AppIcon(
              FeatureIcons.copy,
              size: 20,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          PullDownMenuItem(
            title: context.t.reply.capitalizeFirst(),
            onTap: onMessageReply,
            itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
            iconWidget: const Icon(LucideIcons.reply, size: 20),
          ),
          PullDownMenuItem(
            title: context.t.select.capitalizeFirst(),
            onTap: onSelect,
            itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
            iconWidget: const Icon(LucideIcons.circleCheck, size: 20),
          ),
          if (onDelete != null) ...[
            const PullDownMenuDivider.large(),
            PullDownMenuItem(
              title: context.t.delete.capitalizeFirst(),
              onTap: onDelete,
              isDestructive: true,
              itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
              iconWidget: const AppIcon(
                FeatureIcons.trash,
                size: 20,
                color: kRed,
              ),
            ),
          ]
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        icon: Icon(
          LucideIcons.moreVertical,
          color: Theme.of(context).primaryColorDark,
          size: 20,
        ),
      ),
    );
  }

  void _handleCopy(BuildContext context) {
    if (copiedText != null) {
      Clipboard.setData(ClipboardData(text: copiedText!));
      BotToastUtils.showSuccess(context.t.messageCopied.capitalizeFirst());
    } else {
      BotToastUtils.showError(context.t.messageNotDecrypted.capitalizeFirst());
    }
  }
}
