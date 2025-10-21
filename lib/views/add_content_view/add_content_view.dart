// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';

import '../../logic/add_content_cubit/add_content_cubit.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../utils/utils.dart';
import 'widgets/add_content_bottom_navigation_bar.dart';
import 'widgets/add_content_main_view.dart';

class AddContentView extends StatelessWidget {
  AddContentView({
    super.key,
    this.content,
    this.article,
    this.smartWidgetModel,
    this.selectFirstSmartWidgetDraft,
    this.video,
    this.curation,
    this.contentType,
    this.attachedEvent,
    this.isMention,
    this.onSuccess,
    this.selectedExternalRelay,
    this.isCloning,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Add content view');
  }

  final String? content;
  final Article? article;
  final SmartWidget? smartWidgetModel;
  final bool? selectFirstSmartWidgetDraft;
  final VideoModel? video;
  final Curation? curation;
  final AppContentType? contentType;
  final BaseEventModel? attachedEvent;
  final bool? isMention;
  final String? selectedExternalRelay;
  final Function(Event)? onSuccess;
  final bool? isCloning;

  @override
  Widget build(BuildContext context) {
    final components = <Widget>[];

    components.add(
      BlocBuilder<AddContentCubit, AddContentState>(
        builder: (context, state) {
          return Expanded(
            child: ClipRRect(
              borderRadius:
                  contentType == null && state.displayBottomNavigationBar
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(kDefaultPadding),
                          bottomRight: Radius.circular(kDefaultPadding),
                        )
                      : BorderRadius.zero,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: AddContentMainView(
                  content: content,
                  article: article,
                  attachedEvent: attachedEvent,
                  isMention: isMention,
                  onSuccess: onSuccess,
                  isCloning: isCloning,
                  smartWidgetModel: smartWidgetModel,
                  selectFirstSmartWidgetDraft: selectFirstSmartWidgetDraft,
                  curation: curation,
                  video: video,
                  selectedExternalRelay: selectedExternalRelay,
                ),
              ),
            ),
          );
        },
      ),
    );

    components.add(
      BlocBuilder<AddContentCubit, AddContentState>(
        builder: (context, state) {
          return AnimatedCrossFade(
            firstChild: AddContentBottomNavigationBar(
              index: getIndex(),
              removeExtra: contentType == null,
            ),
            secondChild: const SizedBox(
              width: double.infinity,
              height: 0,
            ),
            crossFadeState:
                contentType == null && state.displayBottomNavigationBar
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          );
        },
      ),
    );

    return BlocProvider(
      create: (context) => AddContentCubit(appContentType: contentType),
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        body: Column(
          children: components,
        ),
      ),
    );
  }

  int getIndex() {
    if (contentType != null) {
      return AppContentType.values.indexOf(contentType!);
    }

    return 0;
  }
}
