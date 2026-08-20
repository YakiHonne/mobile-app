import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/amber_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/bip340_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/keychain.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../logic/metadata_cubit/metadata_cubit.dart';
import '../../../logic/subscription_cubit/subscription_cubit.dart';
import '../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../models/article_model.dart';
import '../../../repositories/localdatabase_repository.dart';
import '../../../utils/utils.dart';
import '../../subscription_view/pricing/subscription_gate.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/fluid_pull_down_button.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/profile_picture.dart';
import '../add_content_specification_views/add_article_specification_view.dart';
import '../related_adding_views/article_widgets/article_content.dart';
import '../widgets/add_content_appbar.dart';

class AddArticleMainView extends HookWidget {
  const AddArticleMainView({
    super.key,
    this.article,
  });

  final Article? article;

  @override
  Widget build(BuildContext context) {
    final signer = useState(currentSigner!);
    final editorAdvanced =
        useState(prefs.getBool('yh-editor-advanced') ?? false);

    // Make sure the gate reflects the current plan every time the editor opens.
    useEffect(() {
      subscriptionCubit.refreshStatus();
      return null;
    }, const []);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: nostrRepository.mainCubit,
        ),
        BlocProvider(
          create: (context) => WriteArticleCubit(
            article: article,
          ),
        ),
      ],
      child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, _) {
          final isSubscriber = subscriptionCubit.isPaid;
          final useAdvanced = isSubscriber && editorAdvanced.value;

          return Column(
            children: [
              _appbar(
                  context, signer, editorAdvanced, isSubscriber, useAdvanced),
              Expanded(
                child: BlocBuilder<AddContentCubit, AddContentState>(
                  builder: (context, state) {
                    return ArticleContent(
                      isMenuDismissed:
                          !state.displayBottomNavigationBar || article != null,
                      useAdvanced: useAdvanced,
                      signer: signer,
                      isSubscriber: isSubscriber,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _appbar(
    BuildContext context,
    ValueNotifier<EventSigner> signer,
    ValueNotifier<bool> editorAdvanced,
    bool isSubscriber,
    bool useAdvanced,
  ) {
    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      builder: (context, state) {
        final enabled = state.title.isNotEmpty && state.content.isNotEmpty;

        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: AddContentAppbar(
            actionButtonText: context.t.next.capitalize(),
            isActionButtonEnabled: enabled,
            extraRight: Padding(
              padding: const EdgeInsets.only(left: kDefaultPadding / 3),
              child: ContentAccountsSwitcher(signer: signer),
            ),
            extra: FluidPullDownButton(
              animationBuilder: (context, state, child) {
                return child;
              },
              routeTheme: PullDownMenuRouteTheme(
                backgroundColor: Theme.of(context).cardColor,
              ),
              itemBuilder: (context) {
                final textStyle = Theme.of(context).textTheme.labelMedium;

                return [
                  PullDownMenuItem.selectable(
                    title: context.t.editor_classic,
                    selected: !useAdvanced,
                    onTap: () {
                      prefs.setBool('yh-editor-advanced', false);
                      editorAdvanced.value = false;
                    },
                    itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
                  ),
                  PullDownMenuItem.selectable(
                    title: context.t.editor_advanced,
                    selected: useAdvanced,
                    icon: isSubscriber ? null : LucideIcons.lock,
                    onTap: () {
                      if (!requireSubscription(context)) {
                        return;
                      }

                      prefs.setBool('yh-editor-advanced', true);
                      editorAdvanced.value = true;
                    },
                    itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
                  ),
                ];
              },
              buttonBuilder: (context, showMenu) => Padding(
                padding: const EdgeInsets.only(right: kDefaultPadding / 4),
                child: TextButton(
                  onPressed: showMenu,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 1.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          useAdvanced
                              ? context.t.editor_advanced
                              : context.t.editor_classic,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(width: kDefaultPadding / 6),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            onActionClicked: () {
              context.read<WriteArticleCubit>().setContentKeywords();

              showAppModalSheet(
                context: context,
                builder: (_) {
                  return BlocProvider<WriteArticleCubit>.value(
                    value: context.read<WriteArticleCubit>(),
                    child: AddArticleSpecificationView(
                      signer: signer.value,
                    ),
                  );
                },
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          ),
        );
      },
    );
  }

//   PullDownMenuItem _deleteDraft(BuildContext context, TextStyle? textStyle) {
//     return PullDownMenuItem(
//       title: context.t.deleteDraft.capitalize(),
//       onTap: () {
//         context.read<WriteArticleCubit>().deleteDraft();
//       },
//       itemTheme: PullDownMenuItemTheme(
//         textStyle: textStyle,
//       ),
//       isDestructive: true,
//       iconWidget: SvgPicture.asset(
//         FeatureIcons.trash,
//         height: 20,
//         width: 20,
//         colorFilter: const ColorFilter.mode(
//           kRed,
//           BlendMode.srcIn,
//         ),
//       ),
//     );
//   }

//   PullDownMenuItem _saveDraft(BuildContext context,
//       ValueNotifier<EventSigner> signer, TextStyle? textStyle) {
//     return PullDownMenuItem(
//       title: context.t.saveDraft.capitalize(),
//       onTap: () {
//         context.read<WriteArticleCubit>().setArticle(
//               isDraft: true,
//               signer: signer.value,
//               onSuccess: (article) {
//                 Navigator.pop(context);

//                 if (article != null) {
//                   showAppModalSheet(
//                     context: context,
//                     elevation: 0,
//                     builder: (_) {
//                       return PublishContentFinalStep(
//                         appContentType: AppContentType.article,
//                         event: article,
//                       );
//                     },
//                     isScrollControlled: true,
//                     useRootNavigator: true,
//                     useSafeArea: true,
//                     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//                   );
//                 }
//               },
//             );
//       },
//       itemTheme: PullDownMenuItemTheme(
//         textStyle: textStyle,
//       ),
//       iconWidget: SvgPicture.asset(
//         FeatureIcons.upload,
//         height: 20,
//         width: 20,
//         colorFilter: ColorFilter.mode(
//           Theme.of(context).primaryColorDark,
//           BlendMode.srcIn,
//         ),
//       ),
//     );
//   }
}

class ContentAccountsSwitcher extends HookWidget {
  const ContentAccountsSwitcher({
    super.key,
    required this.signer,
  });

  final ValueNotifier<EventSigner?> signer;

  @override
  Widget build(BuildContext context) {
    final privateKeys = useState(settingsCubit.getPrivateKeys());
    final isOverlayOpen = useState(false);
    final overlayEntry = useState<OverlayEntry?>(null);
    final GlobalKey profilePictureKey = GlobalKey();

    void showOverlay() {
      if (overlayEntry.value != null) {
        return;
      }

      final RenderBox? renderBox =
          profilePictureKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        return;
      }

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final entry = OverlayEntry(
        builder: (context) => GestureDetector(
          onTap: () {
            isOverlayOpen.value = false;
            overlayEntry.value?.remove();
            overlayEntry.value = null;
          },
          child: ColoredBox(
            color: Theme.of(context).primaryColorLight.withValues(alpha: 0.3),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  top: position.dy + size.height + 10,
                  left: position.dx - 10,
                ),
                child: Material(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: kDefaultPadding / 2,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 35.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _metadataList(
                            context,
                            privateKeys,
                            isOverlayOpen,
                            overlayEntry,
                          ),
                          CustomIconButton(
                            onClicked: () {
                              isOverlayOpen.value = false;
                              overlayEntry.value?.remove();
                              overlayEntry.value = null;
                            },
                            icon: FeatureIcons.arrowUp,
                            size: 20,
                            backgroundColor: kTransparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(entry);
      overlayEntry.value = entry;
      isOverlayOpen.value = true;
    }

    return BlocBuilder<MetadataCubit, MetadataState>(
      builder: (context, state) {
        return MetadataProvider(
          child: (metadata, isNip05Valid) => ProfilePicture2(
            key: profilePictureKey,
            size: 40,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {
              if (privateKeys.value.length > 1) {
                if (isOverlayOpen.value) {
                  isOverlayOpen.value = false;
                  overlayEntry.value?.remove();
                  overlayEntry.value = null;
                } else {
                  showOverlay();
                }
              } else {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              }
            },
          ),
          pubkey: signer.value!.getPublicKey(),
        );
      },
    );
  }

  Expanded _metadataList(
      BuildContext context,
      ValueNotifier<List<MapEntry<String, String>>> privateKeys,
      ValueNotifier<bool> isOverlayOpen,
      ValueNotifier<OverlayEntry?> overlayEntry) {
    return Expanded(
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final p = privateKeys.value[index];
            return Center(
              child: MetadataProvider(
                child: (metadata, isNip05Valid) => ProfilePicture2(
                  size: 32,
                  image: metadata.picture,
                  pubkey: metadata.pubkey,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {
                    final isExternal = settingsCubit.isExternalSignerKeyIndex(
                      int.tryParse(p.key) ?? -1,
                    );

                    if (isExternal) {
                      signer.value = AmberEventSigner(
                        Keychain.getPublicKey(p.value),
                      );
                    } else {
                      signer.value = Bip340EventSigner(
                        p.value,
                        Keychain.getPublicKey(p.value),
                      );
                    }

                    isOverlayOpen.value = false;
                    overlayEntry.value?.remove();
                    overlayEntry.value = null;
                  },
                ),
                pubkey: Keychain.getPublicKey(p.value),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 2,
          ),
          itemCount: privateKeys.value.length,
        ),
      ),
    );
  }
}
