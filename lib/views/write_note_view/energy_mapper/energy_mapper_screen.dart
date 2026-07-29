import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/widgets/ai_upsell_sheet.dart';
import '../../../logic/energy_mapper_cubit/energy_mapper_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import 'widgets/energy_chart.dart';
import 'widgets/energy_chip_row.dart';
import 'widgets/energy_detail_panel.dart';
import 'widgets/shimmer_box.dart';

export 'widgets/energy_helpers.dart' show energyColor;

Future<void> showEnergyMapper(BuildContext context, String content) {
  if (!subscriptionCubit.isPaid) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiUpsellSheet(
        parentContext: context,
        title: context.t.energy_upsell_title,
        features: [
          context.t.pricing_feature_ai_writing_unlimited,
          context.t.pricing_feature_second_reader_all,
          context.t.pricing_feature_energy_mapper_full,
          context.t.pricing_feature_diff_viewer,
        ],
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnergyMapperSheet(content: content),
  );
}

class _EnergyMapperSheet extends StatefulWidget {
  const _EnergyMapperSheet({required this.content});
  final String content;

  @override
  State<_EnergyMapperSheet> createState() => _EnergyMapperSheetState();
}

class _EnergyMapperSheetState extends State<_EnergyMapperSheet> {
  late final EnergyMapperCubit _cubit;
  final ScrollController _chipScroll = ScrollController();

  static const double _chipWidth = EnergyChipRow.chipWidth;
  static const double _chipGap = EnergyChipRow.chipGap;

  @override
  void initState() {
    super.initState();
    _cubit = EnergyMapperCubit();
    _cubit.analyze(widget.content);
  }

  @override
  void dispose() {
    _chipScroll.dispose();
    _cubit.close();
    super.dispose();
  }

  void _selectSentence(int index) {
    _cubit.selectSentence(index);
    _scrollChipIntoView(index);
  }

  void _scrollChipIntoView(int index) {
    if (!_chipScroll.hasClients) {
      return;
    }
    const itemWidth = _chipWidth + _chipGap;
    final targetOffset = index * itemWidth;
    final viewportWidth = _chipScroll.position.viewportDimension;
    final currentOffset = _chipScroll.offset;
    if (targetOffset < currentOffset ||
        targetOffset + _chipWidth > currentOffset + viewportWidth) {
      final to = (targetOffset - viewportWidth / 2 + _chipWidth / 2).clamp(
        0.0,
        _chipScroll.position.maxScrollExtent,
      );
      _chipScroll.animateTo(
        to,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      child: BlocProvider.value(
        value: _cubit,
        child: BlocBuilder<EnergyMapperCubit, EnergyMapperState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ModalBottomSheetHandle(),
                _buildHeader(context, theme, state),
                const Divider(height: 1),
                if (state.isLoading)
                  _buildSkeleton(theme)
                else if (state.sentences.isEmpty)
                  _buildEmpty(context, theme)
                else ...[
                  EnergyLineChart(
                    sentences: state.sentences,
                    selectedIndex: state.selectedIndex,
                    onSelectSentence: _selectSentence,
                  ),
                  const Divider(height: 1),
                  EnergyChipRow(
                    sentences: state.sentences,
                    selectedIndex: state.selectedIndex,
                    scrollController: _chipScroll,
                    onSelect: _selectSentence,
                    onDeselect: (_) => _cubit.clearSelection(),
                  ),
                  const Divider(height: 1),
                  EnergyDetailPanel(
                    selectedIndex: state.selectedIndex,
                    sentences: state.sentences,
                  ),
                ],
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, EnergyMapperState state) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 4),
      child: Row(
        children: [
          const Icon(
            LucideIcons.zap,
            color: Color(0xFF10B981),
            size: 18,
          ),
          const SizedBox(width: kDefaultPadding / 4),
          Text(
            context.t.energy_mapper_title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Text(
              state.isLoading
                  ? context.t.energy_mapper_loading
                  : state.summary ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ),
          CustomIconButton(
            icon: FeatureIcons.closeRaw,
            size: 15,
            onClicked: () => Navigator.of(context).pop(),
            backgroundColor: kTransparent,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 130,
            radius: kDefaultPadding / 2,
            theme: theme,
          ),
          const SizedBox(height: kDefaultPadding),
          Row(
            children: List.generate(
              5,
              (i) => Padding(
                padding: EdgeInsets.only(
                  right: i < 4 ? EnergyChipRow.chipGap : 0,
                ),
                child: ShimmerBox(
                  width: EnergyChipRow.chipWidth,
                  height: 32,
                  radius: kDefaultPadding / 4,
                  theme: theme,
                ),
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          ShimmerBox(
            width: double.infinity,
            height: 80,
            radius: kDefaultPadding / 2,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding * 1.5,
        horizontal: kDefaultPadding,
      ),
      child: Center(
        child: Text(
          context.t.energy_mapper_empty,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: theme.hintColor),
        ),
      ),
    );
  }
}
