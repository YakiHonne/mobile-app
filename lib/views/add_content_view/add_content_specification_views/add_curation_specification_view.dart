import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/write_curation_cubit/write_curation_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/modal_sheet_container.dart';
import '../../widgets/publish_content_final_step.dart';
import '../related_adding_views/curation_widgets/curation_specifications.dart';

class AddCurationSpecificationView extends StatelessWidget {
  const AddCurationSpecificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      builder: (context, state) {
        return ModalSheetContainer(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: CurationSpecifications(
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
                  child: _publish(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SizedBox _publish(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          context.read<WriteCurationCubit>().addCuration(
            onFailure: (message) {
              BotToastUtils.showError(
                message,
              );
            },
            onSuccess: (curation) {
              Navigator.pop(context);
              Navigator.pop(context);

              showAppModalSheet(
                context: context,
                builder: (_) {
                  return PublishContentFinalStep(
                    appContentType: AppContentType.curation,
                    event: curation,
                  );
                },
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          );
        },
        child: Text(
          context.t.publish.capitalize(),
        ),
      ),
    );
  }
}
