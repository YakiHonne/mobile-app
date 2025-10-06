// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/polls_cubit/polls_cubit.dart';
import '../../models/poll_model.dart';
import '../../utils/utils.dart';
import '../smart_widgets_view/widgets/smart_widget_container.dart';
import '../widgets/classic_footer.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/dotted_container.dart';
import '../widgets/empty_list.dart';
import '../widgets/note_container.dart';

class ZapPollSelection extends StatefulWidget {
  const ZapPollSelection({
    super.key,
    required this.onZapPollAdded,
  });

  final Function(Event) onZapPollAdded;

  @override
  State<ZapPollSelection> createState() => _ZapPollSelectionState();
}

class _ZapPollSelectionState extends State<ZapPollSelection>
    with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(
      length: 2,
      vsync: this,
    );
    super.initState();
  }

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => PollsCubit(),
      child: BlocConsumer<PollsCubit, PollsState>(
        listener: (context, state) {
          if (state.loadingState == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadingState == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          return DraggableScrollableSheet(
            initialChildSize: 0.80,
            minChildSize: 0.40,
            maxChildSize: 0.80,
            expand: false,
            builder: (context, scrollController) => ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              ),
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: NestedScrollView(
                  controller: scrollController,
                  floatHeaderSlivers: true,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      _appbar(context),
                    ];
                  },
                  body: _body(state, isTablet, scrollController),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Builder _body(
      PollsState state, bool isTablet, ScrollController scrollController) {
    return Builder(
      builder: (context) {
        if (state.isLoading) {
          return Center(
            child: SpinKitPulse(
              color: Theme.of(context).primaryColorDark,
              size: 20,
            ),
          );
        } else if (state.polls.isEmpty) {
          return EmptyList(
            description: context.t.noPollsCanBeFound,
            icon: FeatureIcons.polls,
          );
        } else {
          return _items(context, isTablet, scrollController, state);
        }
      },
    );
  }

  SmartRefresher _items(BuildContext context, bool isTablet,
      ScrollController scrollController, PollsState state) {
    return SmartRefresher(
      controller: refreshController,
      enablePullDown: false,
      enablePullUp: true,
      header: const MaterialClassicHeader(
        color: kPurple,
      ),
      footer: const RefresherClassicFooter(),
      onLoading: () =>
          context.read<PollsCubit>().getPolls(isAdd: true, isSelf: false),
      onRefresh: () => onRefresh(
        onInit: () =>
            context.read<PollsCubit>().getPolls(isAdd: false, isSelf: false),
      ),
      child: isTablet
          ? _itemsGrid(scrollController, state)
          : _itemsList(state, scrollController),
    );
  }

  ListView _itemsList(PollsState state, ScrollController scrollController) {
    return ListView.separated(
      itemCount: state.polls.length,
      controller: scrollController,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final poll = state.polls[index];

        return GestureDetector(
          onTap: () {
            widget.onZapPollAdded.call(poll.event);
          },
          child: PollContainer(
            poll: poll,
            onTap: () {
              widget.onZapPollAdded.call(poll.event);
            },
          ),
        );
      },
    );
  }

  MasonryGridView _itemsGrid(
      ScrollController scrollController, PollsState state) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      controller: scrollController,
      itemCount: state.polls.length,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final poll = state.polls[index];

        return PollContainer(
          poll: poll,
          onTap: () {
            widget.onZapPollAdded.call(poll.event);
          },
        );
      },
    );
  }

  SliverAppBar _appbar(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      elevation: 5,
      pinned: true,
      actions: const [SizedBox.shrink()],
      titleSpacing: 0,
      toolbarHeight: 64,
      flexibleSpace: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalBottomSheetHandle(),
            TabBar(
              labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              dividerColor: Theme.of(context).dividerColor,
              dividerHeight: 0.5,
              controller: tabController,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 4,
              ),
              unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
              onTap: (index) {
                if (index == 0) {
                  context
                      .read<PollsCubit>()
                      .getPolls(isAdd: false, isSelf: false);
                } else {
                  context
                      .read<PollsCubit>()
                      .getPolls(isAdd: false, isSelf: true);
                }
              },
              tabs: [
                Tab(
                  height: 35,
                  child: Text(
                    context.t.communityPolls.capitalizeFirst(),
                  ),
                ),
                Tab(
                  height: 35,
                  child: Text(
                    context.t.myPolls.capitalizeFirst(),
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

class PollContainer extends HookWidget {
  const PollContainer({
    super.key,
    required this.poll,
    required this.onTap,
  });

  final PollModel poll;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final displayResults = useState(false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
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
            Row(
              children: [
                Expanded(
                  child: ProfileInfoHeader(
                    createdAt: poll.createdAt,
                    pubkey: poll.pubkey,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                CustomIconButton(
                  onClicked: onTap,
                  icon: FeatureIcons.addRaw,
                  size: 15,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  vd: -2,
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              poll.content.trim(),
              style: Theme.of(context).textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.options.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  context.t
                      .totalNumber(number: poll.options.length.toString())
                      .capitalizeFirst(),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: Theme.of(context).highlightColor),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            ...poll.options.map(
              (e) => PollOptionContainer(
                pollOption: e,
                displayResults: displayResults.value,
                total: 0,
                val: 0,
                onClick: () {},
                selfVote: false,
              ),
            )
          ],
        ),
      ),
    );
  }
}
