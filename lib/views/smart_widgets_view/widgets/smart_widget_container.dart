// ignore_for_file: public_member_api_docs, sort_constructors_first, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../../common/common_regex.dart';
import '../../../logic/single_event_cubit/single_event_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/poll_model.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/related_adding_views/smart_widget_widgets/smart_widget_specifications.dart';
import '../../gallery_view/gallery_view.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/note_container.dart';

class SmartWidgetComponent extends HookWidget {
  const SmartWidgetComponent({
    super.key,
    required this.smartWidget,
    this.onChanged,
    this.backgroundColor,
    this.disableWidget,
    this.verticlaPadding,
  });

  final SmartWidget smartWidget;
  final Function(SmartWidget)? onChanged;
  final Color? backgroundColor;
  final bool? disableWidget;
  final double? verticlaPadding;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: disableWidget != null,
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              if (smartWidget.type != SWType.basic) {
                final buttons = smartWidget.smartWidgetBox.buttons;
                if (buttons.isNotEmpty) {
                  openApp(
                    context: context,
                    url: buttons.first.url,
                  );
                }
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                color: smartWidget.type != SWType.basic
                    ? Theme.of(context).cardColor
                    : Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              margin: verticlaPadding != null
                  ? EdgeInsets.symmetric(vertical: verticlaPadding!)
                  : null,
              child: SmartWidgetComponentData(
                key: ValueKey(smartWidget.id),
                smartWidget: smartWidget,
                onChanged: onChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}

class SmartWidgetComponentData extends HookWidget {
  const SmartWidgetComponentData({
    super.key,
    required this.smartWidget,
    required this.onChanged,
  });

  final SmartWidget smartWidget;
  final Function(SmartWidget)? onChanged;

  @override
  Widget build(BuildContext context) {
    final textfieldValue = useState('');
    final onPostStatus = useState(false);
    final currentSmartWidget = useState(smartWidget);
    final imageUrl = currentSmartWidget.value.smartWidgetBox.image.url;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Stack(
        key: ValueKey(currentSmartWidget.value.hashCode),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _thumbnail(currentSmartWidget, imageUrl, context),
              _swColumn(
                  currentSmartWidget, textfieldValue, context, onPostStatus),
            ],
          ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: onPostStatus.value
                  ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                  : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: onPostStatus.value
                    ? Center(
                        child: SpinKitCircle(
                          color: Theme.of(context).primaryColorDark,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          )
        ],
      ),
    );

    return child;
  }

  Padding _swColumn(
      ValueNotifier<SmartWidget> currentSmartWidget,
      ValueNotifier<String> textfieldValue,
      BuildContext context,
      ValueNotifier<bool> onPostStatus) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        children: [
          if (currentSmartWidget.value.smartWidgetBox.inputField != null)
            SMTextField(
              onChanged: (value) {
                textfieldValue.value = value;
              },
              smartWidget: smartWidget,
            ),
          if (currentSmartWidget.value.smartWidgetBox.buttons.isNotEmpty) ...[
            if (currentSmartWidget.value.type != SWType.basic)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 4,
                ),
                child: Text(
                  currentSmartWidget.value.smartWidgetBox.buttons.first.text,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else ...[
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              ButtonsGrid(
                buttons: currentSmartWidget.value.smartWidgetBox.buttons
                    .map(
                      (e) => SMTextButton(
                        text: e.text,
                        onClicked: () => onButtonClicked(
                          button: e,
                          context: context,
                          text: textfieldValue.value,
                          onPost: () async {
                            onPostStatus.value = true;

                            final sm =
                                await HttpFunctionsRepository.postSmartWidget(
                              url: e.url,
                              text: textfieldValue.value,
                              aTag: currentSmartWidget.value.aTag(),
                            );

                            if (context.mounted) {
                              if (sm != null) {
                                currentSmartWidget.value = sm;
                                onChanged?.call(sm);
                              }

                              onPostStatus.value = false;
                            }
                          },
                          onNaddr: (naddr) async {
                            onPostStatus.value = true;

                            final sm = await getSmartWidgetFromNaddr(naddr);

                            if (context.mounted) {
                              onPostStatus.value = false;

                              if (sm != null) {
                                currentSmartWidget.value = sm;
                                onChanged?.call(sm);
                              }
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]
          ],
        ],
      ),
    );
  }

  GestureDetector _thumbnail(ValueNotifier<SmartWidget> currentSmartWidget,
      String imageUrl, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (currentSmartWidget.value.type == SWType.basic) {
          openGallery(
            source: MapEntry(imageUrl, UrlType.image),
            index: 0,
            context: context,
          );
        } else {
          final buttons = smartWidget.smartWidgetBox.buttons;
          if (buttons.isNotEmpty) {
            openApp(
              context: context,
              url: buttons.first.url,
            );
          }
        }
      },
      child: CommonThumbnail(
        image: imageUrl,
        radius: kDefaultPadding / 2,
        isRound: true,
        placeholder: getRandomPlaceholder(
          input: imageUrl,
          isPfp: false,
        ),
        width: double.infinity,
        height: 0,
      ),
    );
  }

  void onButtonClicked({
    required SmartWidgetButton button,
    required BuildContext context,
    required String text,
    required Function() onPost,
    required Function(String naddr) onNaddr,
  }) {
    final usedUrl = button.url.trim();

    if (button.type == SWBType.Zap && usedUrl.isNotEmpty) {
      if (usedUrl.toLowerCase().startsWith('lnbc')) {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return SendZapsView(
              metadata: Metadata.empty().copyWith(
                lud06: usedUrl,
                lud16: usedUrl,
              ),
              lnbc: usedUrl.trim(),
              zapSplits: const [],
              isZapSplit: false,
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      } else if (emailRegExp.hasMatch(usedUrl) ||
          usedUrl.toLowerCase().startsWith('lnurl')) {
        final metadata = Metadata.empty().copyWith(
          lud06: usedUrl,
          lud16: usedUrl,
        );

        if (context.mounted) {
          showModalBottomSheet(
            elevation: 0,
            context: context,
            builder: (_) {
              return SendZapsView(
                metadata: metadata,
                zapSplits: const [],
                isZapSplit: false,
              );
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        }
      } else {
        BotToastUtils.showError(
          context.t.invalidInvoiceLnurl.capitalizeFirst(),
        );
      }
    } else if (button.type == SWBType.Nostr &&
        Nip19.nip19regex.allMatches(usedUrl).isNotEmpty) {
      try {
        if (usedUrl.startsWith('naddr')) {
          final nostrDecode = Nip19.decodeShareableEntity(usedUrl);
          if (nostrDecode['kind'] == EventKind.SMART_WIDGET_ENH) {
            onNaddr.call(usedUrl);
            return;
          }
        }
      } catch (_) {}

      nostrRepository.mainCubit.forwardView(
        uriString: usedUrl,
        isNostrScheme: true,
        skipDelay: true,
      );
    } else if (button.type == SWBType.Post) {
      onPost.call();
    } else if (urlRegExp.hasMatch(usedUrl)) {
      openWebPage(url: usedUrl);
    } else {
      BotToastUtils.showError(
        context.t.unableToOpenUrl.capitalizeFirst(),
      );
    }
  }
}

class SMTextField extends StatelessWidget {
  const SMTextField({
    super.key,
    required this.onChanged,
    required this.smartWidget,
  });

  final Function(String) onChanged;
  final SmartWidget smartWidget;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: smartWidget.smartWidgetBox.inputField?.placeholder,
      ),
    );
  }
}

class SMTextButton extends StatelessWidget {
  const SMTextButton({
    super.key,
    required this.text,
    required this.onClicked,
  });

  final String text;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClicked,
      style: TextButton.styleFrom(
        visualDensity: const VisualDensity(horizontal: -0.5, vertical: -0.5),
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).primaryColorDark,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class PollContainer extends HookWidget {
  const PollContainer({
    super.key,
    required this.poll,
    required this.includeUser,
    this.contentColor,
    this.optionBackgroundColor,
    this.optionTextColor,
    this.optionForegroundColor,
    this.backgroundColor,
    this.onTap,
  });

  final PollModel poll;
  final bool includeUser;
  final Color? contentColor;
  final Color? optionBackgroundColor;
  final Color? optionTextColor;
  final Color? optionForegroundColor;
  final Color? backgroundColor;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final votesByZaps = useState(true);
    final hasPubkey = useState(false);
    final hasReachedEnd = useState(false);
    final displayResults = useState(PollStatsStatus.idle);
    final pollStats = useState(singleEventCubit.state.pollStats[poll.id] ?? []);

    final searchFunc = useCallback(
      (bool showMessage) {
        pollStats.value = singleEventCubit.state.pollStats[poll.id] ?? [];

        hasReachedEnd.value = poll.closedAt != DateTime(1950) &&
            DateTime.now().compareTo(poll.closedAt) > 1;

        if (hasReachedEnd.value ||
            (canSign() && poll.pubkey == currentSigner!.getPublicKey())) {
          displayResults.value = PollStatsStatus.visible;
        } else {
          hasPubkey.value = canSign() &&
              pollStats.value
                  .where((element) =>
                      element.pubkey == currentSigner!.getPublicKey())
                  .isNotEmpty;

          if (hasPubkey.value) {
            displayResults.value = PollStatsStatus.visible;
          } else {
            if (showMessage) {
              BotToastUtils.showWarning(
                context.t.voteToSeeStats.capitalizeFirst(),
              );
            }

            displayResults.value = PollStatsStatus.invisible;
          }
        }
      },
    );

    return BlocBuilder<SingleEventCubit, SingleEventState>(
      buildWhen: (previous, current) =>
          previous.pollStats[poll.id] != current.pollStats[poll.id],
      builder: (context, state) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                !includeUser ? null : const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (includeUser) ...[
                  ProfileInfoHeader(
                    createdAt: poll.createdAt,
                    pubkey: poll.pubkey,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
                ParsedText(
                  text: poll.content.trim(),
                  color: contentColor,
                  inverseNoteColor: includeUser,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _options(context, votesByZaps),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                ...poll.options.map(
                  (e) => Builder(
                    builder: (context) {
                      num val = 0;
                      num total = 0;

                      final ps = getPollStats(
                        total: pollStats.value,
                        pollOption: e,
                        poll: poll,
                      );

                      final vps = getValidPollStats(
                        total: pollStats.value,
                        poll: poll,
                      );

                      final selfVote = hasPubkey.value &&
                          ps
                              .where((element) =>
                                  element.pubkey ==
                                  currentSigner!.getPublicKey())
                              .isNotEmpty;

                      for (final p in ps) {
                        val += p.zapAmount;
                      }

                      for (final v in vps) {
                        total += v.zapAmount;
                      }

                      return _pollItem(
                          e,
                          selfVote,
                          votesByZaps,
                          val,
                          ps,
                          displayResults,
                          total,
                          vps,
                          hasPubkey,
                          searchFunc,
                          context);
                    },
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                _pollInfoRow(displayResults, pollStats, context, searchFunc),
              ],
            ),
          ),
        );
      },
    );
  }

  Column _pollInfoRow(
      ValueNotifier<PollStatsStatus> displayResults,
      ValueNotifier<List<PollStat>> pollStats,
      BuildContext context,
      Function(bool) searchFunc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayResults.value == PollStatsStatus.visible)
          Builder(
            builder: (context) {
              final vps = getValidPollStats(
                total: pollStats.value,
                poll: poll,
              );

              return Text(
                context.t
                    .votesNumber(
                      number: vps.length.toString(),
                    )
                    .capitalizeFirst(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: contentColor,
                    ),
              );
            },
          )
        else
          displayResults.value == PollStatsStatus.invisible
              ? Text(
                  context.t.voteRequired.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: contentColor,
                      ),
                )
              : GestureDetector(
                  onTap: () {
                    singleEventCubit.zapPollSearch(
                      poll.id,
                      () {
                        searchFunc.call(true);
                      },
                    );
                  },
                  child: Text(
                    context.t.showStats.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          decoration: TextDecoration.underline,
                          color: contentColor,
                        ),
                  ),
                ),
        if (poll.closedAt != DateTime(1950)) ...[
          const SizedBox(
            height: kDefaultPadding / 8,
          ),
          Text(
            poll.closedAt.compareTo(DateTime.now()) > 0
                ? context.t
                    .pollClosesAt(
                      date: dateFormat3.format(poll.closedAt),
                    )
                    .capitalizeFirst()
                : context.t
                    .pollClosedAt(
                      date: dateFormat3.format(poll.closedAt),
                    )
                    .capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: contentColor,
                ),
          ),
        ]
      ],
    );
  }

  PollOptionContainer _pollItem(
      PollOption e,
      bool selfVote,
      ValueNotifier<bool> votesByZaps,
      num val,
      List<PollStat> ps,
      ValueNotifier<PollStatsStatus> displayResults,
      num total,
      List<PollStat> vps,
      ValueNotifier<bool> hasPubkey,
      Function(bool) searchFunc,
      BuildContext context) {
    return PollOptionContainer(
      pollOption: e,
      selfVote: selfVote,
      val: votesByZaps.value ? val : ps.length,
      displayResults: displayResults.value == PollStatsStatus.visible,
      backgroundColor: optionBackgroundColor,
      textColor: optionTextColor,
      fillColor: optionForegroundColor,
      total: votesByZaps.value ? total : vps.length,
      onClick: () async {
        doIfCanSignDirect(
          func: () async {
            if (displayResults.value != PollStatsStatus.visible &&
                !hasPubkey.value) {
              final user =
                  await metadataCubit.getFutureMetadata(poll.zapPubkey);

              if (user != null) {
                if (user.pubkey == currentSigner!.getPublicKey()) {
                  return;
                }

                singleEventCubit.zapPollSearch(
                  poll.id,
                  () async {
                    searchFunc.call(false);

                    if (hasPubkey.value) {
                      BotToastUtils.showWarning(
                        context.t.alreadyVoted.capitalizeFirst(),
                      );
                    } else {
                      showModalBottomSheet(
                        elevation: 0,
                        context: context,
                        builder: (_) {
                          return SendZapsView(
                            metadata: user,
                            pollOption: e.index.toString(),
                            isZapSplit: false,
                            zapSplits: const [],
                            eventId: poll.id,
                            valMax: poll.valMax,
                            valMin: poll.valMin,
                            onSuccess: (preimage, amount) async {
                              await Future.delayed(
                                const Duration(
                                  seconds: 1,
                                ),
                              ).then(
                                (value) => singleEventCubit.zapPollSearch(
                                  poll.id,
                                  () {
                                    searchFunc.call(true);
                                  },
                                ),
                              );
                            },
                          );
                        },
                        isScrollControlled: true,
                        useRootNavigator: true,
                        useSafeArea: true,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                      );
                    }
                  },
                );
              } else {
                BotToastUtils.showError(
                  context.t.userCannotBeFound.capitalizeFirst(),
                );
              }
            }
          },
          context: context,
        );
      },
    );
  }

  Row _options(BuildContext context, ValueNotifier<bool> votesByZaps) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.options.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: contentColor,
                    ),
              ),
              Text(
                context.t
                    .totalNumber(
                      number: poll.options.length.toString(),
                    )
                    .capitalizeFirst(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .copyWith(color: contentColor),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () {
            votesByZaps.value = !votesByZaps.value;
          },
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
          ),
          icon: SvgPicture.asset(
            votesByZaps.value ? FeatureIcons.zap : FeatureIcons.user,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              optionTextColor ?? Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          label: Text(
            votesByZaps.value
                ? context.t.votesByZaps.capitalizeFirst()
                : context.t.votesByUsers.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: optionTextColor ?? Theme.of(context).primaryColorDark),
          ),
        ),
      ],
    );
  }

  List<PollStat> getPollStats({
    required List<PollStat> total,
    required PollOption pollOption,
    required PollModel poll,
  }) {
    final pollMax = poll.valMax;
    final pollMin = poll.valMin;
    final List<PollStat> pollStats = [];

    for (final pollStat in total) {
      if (pollStat.index == pollOption.index) {
        if (pollMin != -1 && pollStat.zapAmount < pollMin) {
          break;
        }

        if (pollMax != -1 && pollStat.zapAmount > pollMax) {
          break;
        }

        pollStats.add(pollStat);
      }
    }

    return pollStats;
  }

  List<PollStat> getValidPollStats({
    required List<PollStat> total,
    required PollModel poll,
  }) {
    final List<PollStat> pollStats = [];

    for (final pollStat in total) {
      if ((poll.valMax == -1 || pollStat.zapAmount <= poll.valMax) &&
          (poll.valMin == -1 || pollStat.zapAmount >= poll.valMin)) {
        pollStats.add(pollStat);
      }
    }

    return pollStats;
  }
}

class PollOptionContainer extends StatelessWidget {
  const PollOptionContainer({
    super.key,
    required this.pollOption,
    required this.displayResults,
    required this.val,
    required this.total,
    required this.selfVote,
    required this.onClick,
    this.textColor,
    this.backgroundColor,
    this.fillColor,
  });

  final PollOption pollOption;
  final bool displayResults;
  final num val;
  final num total;
  final bool selfVote;
  final Function() onClick;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: selfVote
              ? Border.all(
                  color: kMainColor,
                )
              : null,
        ),
        child: _cliprrect(context),
      ),
    );
  }

  ClipRRect _cliprrect(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      child: Stack(
        children: [
          Positioned.fill(
            child: LinearProgressIndicator(
              color: kMainColor,
              backgroundColor: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              value: displayResults
                  ? total == 0
                      ? 0
                      : val / total
                  : 0.05,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 1.8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pollOption.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: textColor ?? Theme.of(context).primaryColorDark),
                  ),
                ),
                if (displayResults)
                  Text(
                    val.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: textColor ?? Theme.of(context).primaryColorDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
