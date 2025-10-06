import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';

import '../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/publish_content_final_step.dart';
import '../related_adding_views/smart_widget_widgets/smart_widget_content.dart';

class AddSmartWidgetSpecificationView extends StatelessWidget {
  const AddSmartWidgetSpecificationView({required this.signer, super.key});

  final EventSigner signer;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
        return Container(
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
            initialChildSize: 0.85,
            minChildSize: 0.60,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: FrameContent(
                    scrollController: scrollController,
                  ),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  padding: EdgeInsets.only(
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  alignment: Alignment.center,
                  child: _publish(state, context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SizedBox _publish(WriteSmartWidgetState state, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          if (state.title.trim().isEmpty) {
            BotToastUtils.showError(
              context.t.smHaveTitle,
            );
          } else {
            context.read<WriteSmartWidgetCubit>().setSmartWidget(
                  signer: signer,
                  onSuccess: (sw) {
                    Navigator.pop(context);
                    Navigator.pop(context);

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
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
                );
          }
        },
        child: Text(
          context.t.publish.capitalize(),
        ),
      ),
    );
  }
}
