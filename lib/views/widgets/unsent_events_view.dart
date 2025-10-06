import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';

import '../../logic/unsent_events_cubit/unsent_events_cubit.dart';
import '../../models/flash_news_model.dart';
import '../../utils/utils.dart';
import '../settings_view/widgets/settings_text.dart';
import 'dotted_container.dart';
import 'empty_list.dart';
import 'pull_down_global_button.dart';
import 'show_raw_event_view.dart';

class UnsentEventsView extends StatelessWidget {
  const UnsentEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: MediaQuery.of(context).viewInsets.copyWith(
            left: kDefaultPadding / 2,
            right: kDefaultPadding / 2,
          ),
      decoration: _buildContainerDecoration(context),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding / 2,
          children: [
            const ModalBottomSheetHandle(),
            TitleDescriptionComponent(
              title: context.t.pendingEvents,
              description: context.t.pendingEventsDesc,
            ),
            Expanded(
              child: _getCurrentWidget(
                context: context,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build container decoration
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kDefaultPadding),
        topRight: Radius.circular(kDefaultPadding),
      ),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    );
  }

  Widget _getCurrentWidget({
    required BuildContext context,
    required ScrollController scrollController,
  }) {
    return BlocBuilder<UnsentEventsCubit, UnsentEventsState>(
      builder: (context, state) {
        final events = state.events.values.toList();

        if (events.isNotEmpty) {
          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(
              height: kDefaultPadding / 4,
            ),
            controller: scrollController,
            itemBuilder: (context, index) {
              final e = events[index];

              return UnsentEventContainer(e: e);
            },
            itemCount: events.length,
          );
        }

        return EmptyList(
          description: context.t.NewPostDesc,
          icon: FeatureIcons.showRawEvent,
        );
      },
    );
  }
}

class UnsentEventContainer extends StatelessWidget {
  const UnsentEventContainer({
    super.key,
    required this.e,
  });

  final Event e;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _infoColumn(context),
          _pulldownButton(context),
        ],
      ),
    );
  }

  PullDownGlobalButton _pulldownButton(BuildContext context) {
    return PullDownGlobalButton(
      enableShowRawEvent: true,
      onShowRawEvent: () {
        showModalBottomSheet(
          elevation: 0,
          context: context,
          builder: (_) {
            return ShowRawEventView(
              attachedEvent: e.toJsonString(),
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      model: LightMetadata(
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          e.createdAt * 1000,
        ),
        pubkey: e.pubkey,
        id: e.id,
      ),
    );
  }

  Expanded _infoColumn(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${context.t.kind}: '),
              Text(
                EventKindHelper.getKindDisplayName(
                  context,
                  e.kind,
                ),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: kMainColor,
                    ),
              ),
            ],
          ),
          Text(
            dateFormat3.format(
              DateTime.fromMillisecondsSinceEpoch(
                e.createdAt * 1000,
              ),
            ),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }
}
