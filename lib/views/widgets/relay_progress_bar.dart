import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../logic/relays_progress_cubit/relays_progress_cubit.dart';
import '../../utils/utils.dart';
import 'empty_list.dart';

class RelaysProgressBar extends StatefulWidget {
  const RelaysProgressBar({
    super.key,
  });

  @override
  State<RelaysProgressBar> createState() => _RelaysProgressBarState();
}

class _RelaysProgressBarState extends State<RelaysProgressBar> {
  AnimationController? animationController;
  double progressValue = 0;

  @override
  void dispose() {
    if (animationController != null && !animationController!.isDismissed) {
      animationController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RelaysProgressCubit, RelaysProgressState>(
      listenWhen: (previous, current) =>
          previous.isProgressVisible != current.isProgressVisible,
      listener: (context, state) {
        if (animationController != null) {
          if (state.isProgressVisible) {
            animationController!.forward();
          } else {
            animationController!.reverse();
          }
        }
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeInDown(
          manualTrigger: true,
          duration: const Duration(milliseconds: 300),
          controller: (controller) {
            animationController = controller;
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: kToolbarHeight + kDefaultPadding / 2,
            ),
            child: Column(
              children: [_infoRow(context), _closeButton()],
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _infoRow(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        context.read<RelaysProgressCubit>().dismissProgressBar();
      },
      child: Material(
        elevation: 15,
        borderRadius: BorderRadius.circular(300),
        child: Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 4,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _progressCircle(),
              const SizedBox(
                width: kDefaultPadding / 1.5,
              ),
              _details(context),
              const SizedBox(
                width: kDefaultPadding / 1.5,
              ),
              _closeIcon(context),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _closeIcon(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: () {
          context.read<RelaysProgressCubit>().dismissProgressBar();
        },
        icon: const Icon(
          Icons.close,
          size: 20,
        ),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          visualDensity: const VisualDensity(
            horizontal: -4,
            vertical: -4,
          ),
        ),
      ),
    );
  }

  Column _details(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.t.successfulRelays.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        GestureDetector(
          onTap: () =>
              context.read<RelaysProgressCubit>().setRelaysListVisibility(true),
          child: Text(
            context.t.details.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }

  BlocBuilder<RelaysProgressCubit, RelaysProgressState> _progressCircle() {
    return BlocBuilder<RelaysProgressCubit, RelaysProgressState>(
      builder: (context, state) {
        return Stack(
          children: [
            SizedBox(
              height: 35,
              width: 35,
              child: CircularProgressIndicator(
                strokeCap: StrokeCap.round,
                value: progressValue = state.successfulRelays.length /
                    (state.totalRelays.isEmpty ? 1 : state.totalRelays.length),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                strokeWidth: 2,
                color: kMainColor,
              ),
            ),
            Positioned.fill(
              child: Align(
                child: Text(
                  '${state.successfulRelays.length}/${state.totalRelays.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  BlocBuilder<RelaysProgressCubit, RelaysProgressState> _closeButton() {
    return BlocBuilder<RelaysProgressCubit, RelaysProgressState>(
      builder: (context, state) {
        return Visibility(
          visible: state.isRelaysVisible,
          maintainAnimation: true,
          maintainState: true,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: state.isRelaysVisible ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 2,
              ),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(kDefaultPadding),
                color: Theme.of(context).cardColor,
                child: Container(
                  height: 40.h,
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    removeLeft: true,
                    removeRight: true,
                    removeTop: true,
                    child: Column(
                      children: [
                        Expanded(child: getRelays(state)),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<RelaysProgressCubit>()
                                .setRelaysListVisibility(false);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColorDark,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            context.t.dismiss.capitalizeFirst(),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget getRelays(RelaysProgressState state) {
    try {
      return state.totalRelays.isEmpty
          ? EmptyList(
              description: context.t.noRelaysCanBeFound.capitalizeFirst(),
              icon: FeatureIcons.relays,
            )
          : ScrollShadow(
              color: Theme.of(context).cardColor,
              child: ScrollShadow(
                color: Theme.of(context).cardColor,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(kDefaultPadding),
                  itemCount: state.totalRelays.length,
                  itemBuilder: (context, index) {
                    final e = state.totalRelays[index];
                    return relayStatus(
                      relay: e,
                      isSuccessful: state.successfulRelays.contains(e),
                    );
                  },
                ),
              ));
    } catch (e) {
      lg.i(e);
      lg.i(state.totalRelays);
      return EmptyList(
        description: context.t.noRelaysCanBeFound.capitalizeFirst(),
        icon: FeatureIcons.relays,
      );
    }
  }

  Widget relayStatus({required String relay, required bool isSuccessful}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isSuccessful ? Images.ok : Images.forbidden,
            width: 25,
            height: 25,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Flexible(
            child: Text(
              Relay.clean(relay) ?? relay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
