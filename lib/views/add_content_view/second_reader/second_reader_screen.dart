import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/widgets/ai_upsell_sheet.dart';
import '../../../logic/second_reader_cubit/second_reader_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/modal_sheet_container.dart';
import 'widgets/active_view.dart';
import 'widgets/picker_view.dart';

Future<void> showSecondReader(
  BuildContext context,
  String content, {
  required void Function(String prefill) onFixWithAi,
}) {
  if (!subscriptionCubit.isPremium) {
    return showAdaptiveModal<void>(
      context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AiUpsellSheet(
        parentContext: context,
        title: context.t.second_reader_title,
        features: [
          context.t.pricing_feature_second_reader_all,
          context.t.pricing_feature_energy_mapper_full,
          context.t.pricing_feature_ai_writing_unlimited,
        ],
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _SecondReaderSheet(content: content, onFixWithAi: onFixWithAi),
  );
}

class _SecondReaderSheet extends StatefulWidget {
  const _SecondReaderSheet({required this.content, required this.onFixWithAi});
  final String content;
  final void Function(String prefill) onFixWithAi;

  @override
  State<_SecondReaderSheet> createState() => _SecondReaderSheetState();
}

class _SecondReaderSheetState extends State<_SecondReaderSheet> {
  late final SecondReaderCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SecondReaderCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SecondReaderCubit, SecondReaderState>(
        buildWhen: (p, c) => p.view != c.view,
        builder: (_, state) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: ModalSheetContainer(
            child: state.view == SecondReaderView.picker
                ? SecondReaderPickerView(content: widget.content)
                : SecondReaderActiveView(
                    content: widget.content,
                    onFixWithAi: widget.onFixWithAi,
                  ),
          ),
        ),
      ),
    );
  }
}
