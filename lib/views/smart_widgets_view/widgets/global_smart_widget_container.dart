// ignore_for_file: public_member_api_docs, sort_constructors_first, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/smart_widgets_cubit/smart_widgets_cubit.dart';
import '../../../models/app_models/popup_menu_common_item.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/add_content_view.dart';
import '../../widgets/note_container.dart';
import '../../widgets/publish_content_final_step.dart';
import '../../widgets/pull_down_global_button.dart';
import '../../widgets/response_snackbar.dart';
import 'smart_widget_container.dart';

class GlobalSmartWidgetContainer extends HookWidget {
  const GlobalSmartWidgetContainer({
    super.key,
    required this.smartWidgetModel,
    this.onClicked,
    this.canPerformOwnerActions,
    this.disableActions,
    this.isMinimised = false,
  });

  final SmartWidget smartWidgetModel;
  final bool isMinimised;
  final Function()? onClicked;
  final bool? canPerformOwnerActions;
  final bool? disableActions;

  @override
  Widget build(BuildContext context) {
    final currentSw = useState(smartWidgetModel);
    final isOriginal = currentSw.value == smartWidgetModel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: GestureDetector(
        onTap: onClicked,
        child: AbsorbPointer(
          absorbing: onClicked != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMinimised) ...[
                GlobalSmartWidgetHeader(
                  smartWidgetModel: smartWidgetModel,
                  isOriginal: isOriginal,
                  currentSw: currentSw,
                  disableActions: disableActions,
                  canPerformOwnerActions: canPerformOwnerActions,
                  isMinimised: isMinimised,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
              ],
              SmartWidgetComponent(
                smartWidget: smartWidgetModel,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                onChanged: (sw) {
                  currentSw.value = sw;
                },
              ),
              if (isMinimised) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                GlobalSmartWidgetHeader(
                  smartWidgetModel: smartWidgetModel,
                  isOriginal: isOriginal,
                  currentSw: currentSw,
                  disableActions: disableActions,
                  canPerformOwnerActions: canPerformOwnerActions,
                  isMinimised: isMinimised,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalSmartWidgetHeader extends StatelessWidget {
  const GlobalSmartWidgetHeader({
    super.key,
    required this.smartWidgetModel,
    required this.isOriginal,
    required this.currentSw,
    required this.disableActions,
    required this.canPerformOwnerActions,
    required this.isMinimised,
  });

  final SmartWidget smartWidgetModel;
  final bool isOriginal;
  final bool isMinimised;
  final ValueNotifier<SmartWidget> currentSw;
  final bool? disableActions;
  final bool? canPerformOwnerActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isMinimised
          ? BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            )
          : null,
      padding:
          isMinimised ? const EdgeInsets.only(left: kDefaultPadding / 2) : null,
      child: Row(
        children: [
          Expanded(
            child: ProfileInfoHeader(
              createdAt: smartWidgetModel.createdAt,
              pubkey: smartWidgetModel.pubkey,
              isMinimised: isMinimised,
            ),
          ),
          if (!isOriginal) _publish(context),
          if (disableActions == null) _pulldownButton(context),
        ],
      ),
    );
  }

  PullDownGlobalButton _pulldownButton(BuildContext context) {
    return PullDownGlobalButton(
      model: smartWidgetModel,
      enablePostInNote: true,
      enableShareWidgetImage: true,
      widgetImage: currentSw.value.smartWidgetBox.image.url,
      enableCopyNaddr: isOriginal,
      enableClone: true,
      enableEdit: currentSigner!.getPublicKey() == smartWidgetModel.pubkey &&
          canPerformOwnerActions != null,
      enableCheckValidity: true,
      enableDelete: currentSigner!.getPublicKey() == smartWidgetModel.pubkey &&
          canPerformOwnerActions != null,
      onDelete: () {
        showCupertinoDeletionDialogue(
          context: context,
          title: context.t
              .deleteContent(type: context.t.smartWidget)
              .capitalizeFirst(),
          description: context.t
              .confirmDeleteContent(type: context.t.smartWidget)
              .capitalizeFirst(),
          buttonText: context.t.delete.capitalizeFirst(),
          onDelete: () {
            context.read<SmartWidgetsCubit>().deleteSmartWidget(
              smartWidgetModel.id,
              () {
                final cubit = context.read<SmartWidgetsCubit>();
                cubit.getSmartWidgets(isAdd: false, isSelf: cubit.isSelfVal);

                Navigator.of(context).pop();
              },
            );
          },
        );
      },
      onPostInNote: () {
        if (isOriginal) {
          PdmCommonActions.postInNote(context, currentSw.value);
        } else {
          NostrFunctionsRepository.publishClonedSmartWidget(
            sm: currentSw.value,
            onSuccess: (sw) {
              YNavigator.pushPage(
                context,
                (context) => AddContentView(
                  attachedEvent: sw,
                  contentType: AppContentType.note,
                  isMention: true,
                ),
              );
            },
          );
        }
      },
    );
  }

  AnimatedSwitcher _publish(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: TextButton(
        onPressed: () {
          NostrFunctionsRepository.publishClonedSmartWidget(
            sm: currentSw.value,
            onSuccess: (sw) {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return PublishContentFinalStep(
                    appContentType: AppContentType.smartWidget,
                    event: sw,
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          context.t.publish.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
