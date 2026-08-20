import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/blossom_cubit/blossom_cubit.dart';
import '../../../logic/blossom_cubit/blossom_state.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import 'blossom_server_card.dart';

/// Consumed storage for whatever the filter row currently has in scope, plus
/// the local search field.
class BlossomSummaryHeader extends StatefulWidget {
  const BlossomSummaryHeader({super.key, required this.state});

  final BlossomState state;

  @override
  State<BlossomSummaryHeader> createState() => _BlossomSummaryHeaderState();
}

class _BlossomSummaryHeaderState extends State<BlossomSummaryHeader> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consumed = widget.state.allMedia
        .where(
          (m) =>
              widget.state.selectedServerIndex == -1 ||
              m.serverUrls.contains(
                widget.state.servers[widget.state.selectedServerIndex],
              ),
        )
        .fold<int>(0, (sum, m) => sum + m.media.size);

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.t.media_consumed_storage,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: kDefaultPadding / 4),
              Text(
                formatMediaBytes(consumed),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.primaryColorDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 4),
          TextField(
            controller: _controller,
            onChanged: context.read<BlossomCubit>().search,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: context.t.media_search_hint,
              suffixIcon: widget.state.searchQuery.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () {
                        _controller.clear();
                        context.read<BlossomCubit>().search('');
                      },
                      child: const AppIcon(LucideIcons.x, size: 16),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultPadding * 2),
                borderSide: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultPadding * 2),
                borderSide: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultPadding * 2),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2 + 4,
                vertical: kDefaultPadding / 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
