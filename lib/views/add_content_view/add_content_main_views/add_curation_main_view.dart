import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../logic/write_curation_cubit/write_curation_cubit.dart';
import '../../../models/curation_model.dart';
import '../../../utils/utils.dart';
import '../add_content_specification_views/add_curation_specification_view.dart';
import '../related_adding_views/curation_widgets/curation_content.dart';
import '../widgets/add_content_appbar.dart';

class AddCurationMainView extends StatelessWidget {
  const AddCurationMainView({super.key, this.curation});

  final Curation? curation;

  @override
  Widget build(BuildContext context) {
    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteCurationCubit, WriteCurationState>(
        builder: (context, state) {
          final enabled = state.title.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: AddContentAppbar(
              actionButtonText: context.t.next.capitalize(),
              isActionButtonEnabled: enabled,
              onActionClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return BlocProvider<WriteCurationCubit>.value(
                      value: context.read<WriteCurationCubit>(),
                      child: const AddCurationSpecificationView(),
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
            ),
          );
        },
      ),
    );

    components.add(
      Expanded(
        child: BlocBuilder<AddContentCubit, AddContentState>(
          builder: (context, state) {
            return CurationContent(
              isAdding: curation == null,
            );
          },
        ),
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: nostrRepository.mainCubit,
        ),
        BlocProvider(
          create: (context) => WriteCurationCubit(curation: curation),
        )
      ],
      child: Column(
        children: components,
      ),
    );
  }
}
