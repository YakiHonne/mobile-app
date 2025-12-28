// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../add_content_main_views/add_article_main_view.dart';
import '../add_content_main_views/add_curation_main_view.dart';
import '../add_content_main_views/add_note_main_view.dart';
import '../add_content_main_views/add_smart_widget_main_view.dart';
import '../add_content_main_views/add_video_main_view.dart';

class AddContentMainView extends StatelessWidget {
  const AddContentMainView({
    super.key,
    this.content,
    this.article,
    this.attachedEvent,
    this.isMention,
    this.smartWidgetModel,
    this.isCloning,
    this.onSuccess,
    this.curation,
    this.video,
    this.selectedExternalRelay,
    this.selectFirstSmartWidgetDraft,
  });

  final String? content;
  final Article? article;
  final VideoModel? video;
  final Curation? curation;
  final SmartWidget? smartWidgetModel;
  final bool? selectFirstSmartWidgetDraft;
  final BaseEventModel? attachedEvent;
  final bool? isMention;
  final bool? isCloning;
  final String? selectedExternalRelay;
  final Function(Event)? onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddContentCubit, AddContentState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildSwitchCaseWidget(state),
        );
      },
    );
  }

  Widget _buildSwitchCaseWidget(AddContentState state) {
    switch (state.appContentType) {
      case AppContentType.note:
        return AddNoteMainView(
          key: const ValueKey(
            AppContentType.note,
          ),
          attachedEvent: attachedEvent,
          isMention: isMention,
          content: content,
          onSuccess: onSuccess,
          selectedExternalRelay: selectedExternalRelay,
        );
      case AppContentType.article:
        return AddArticleMainView(
          key: const ValueKey(
            AppContentType.article,
          ),
          article: article,
        );
      case AppContentType.curation:
        return AddCurationMainView(
          key: const ValueKey(
            AppContentType.curation,
          ),
          curation: curation,
        );
      case AppContentType.video:
        return AddVideoMainView(
          key: const ValueKey(
            AppContentType.video,
          ),
          videoModel: video,
        );
      case AppContentType.smartWidget:
        return AddSmartWidgetMainView(
          key: const ValueKey(
            AppContentType.smartWidget,
          ),
          isCloning: isCloning,
          smartWidgetModel: smartWidgetModel,
          selectFirstSmartWidgetDraft: selectFirstSmartWidgetDraft,
        );
      case AppContentType.picture:
        return const SizedBox.shrink();
    }
  }
}
