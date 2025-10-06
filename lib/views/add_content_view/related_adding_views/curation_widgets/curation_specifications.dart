import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_curation_cubit/write_curation_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/content_zap_splits.dart';
import '../../widgets/publish_preview_container.dart';

class CurationSpecifications extends StatelessWidget {
  const CurationSpecifications({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteCurationCubit, WriteCurationState>(
        builder: (context, state) {
          return PublishPreviewContainer(
            descInitText: context.read<WriteCurationCubit>().state.description,
            title: state.title,
            onDescChanged: (desc) {
              context.read<WriteCurationCubit>().setDescription(desc);
            },
            imageLink: state.imageLink,
            onImageLinkChanged: (url) {
              context.read<WriteCurationCubit>().setImage(url);
              Navigator.pop(context);
            },
          );
        },
      ),
    );

    components.add(
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    components.add(
      BlocBuilder<WriteCurationCubit, WriteCurationState>(
        buildWhen: (previous, current) =>
            previous.isZapSplitEnabled != current.isZapSplitEnabled ||
            previous.zapsSplits != current.zapsSplits,
        builder: (context, state) {
          return ContentZapSplits(
            kind: context.t.curation,
            isZapSplitEnabled: state.isZapSplitEnabled,
            zaps: state.zapsSplits,
            onToggleZapSplit: () {
              context.read<WriteCurationCubit>().toggleZapsSplits();
            },
            onAddZapSplitUser: (pubkey) {
              context.read<WriteCurationCubit>().addZapSplit(pubkey);
            },
            onRemoveZapSplitUser: (pubkey) {
              context.read<WriteCurationCubit>().onRemoveZapSplit(pubkey);
            },
            onSetZapProportions: (index, zap, percentage) {
              context.read<WriteCurationCubit>().setZapPropertion(
                    index: index,
                    zapSplit: zap,
                    newPercentage: percentage,
                  );
            },
          );
        },
      ),
    );

    return BlocBuilder<WriteCurationCubit, WriteCurationState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          controller: scrollController,
          children: components,
        );
      },
    );
  }
}
