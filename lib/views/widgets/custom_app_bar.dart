import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../repositories/nostr_data_repository.dart';
import '../../utils/utils.dart';
import 'buttons_containers_widgets.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.description,
    this.notElevated,
    this.onBackClicked,
    this.onLogoClicked,
    this.color,
    this.actions,
    this.titleWidget,
    this.leading,
  });

  final String? title;
  final String? description;

  /// Flattens the bar. Used to be checked for null rather than for its value,
  /// so `notElevated: false` also flattened; all 6 call sites passed `true`,
  /// so tightening it to `== true` changed nothing.
  final bool? notElevated;
  final Function()? onBackClicked;
  final Function()? onLogoClicked;
  final Color? color;
  final List<Widget>? actions;

  /// Replaces the [title]/[description] column and takes the bar's full width:
  /// the title stops being centred and loses its leading gap, so a row can run
  /// from the back button to the trailing edge. Wins over [title] when both
  /// are given.
  final Widget? titleWidget;

  /// Replaces the default back chevron. Pass `SizedBox.shrink()` for a bar
  /// with no leading affordance at all.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final hasTitleWidget = titleWidget != null;

    return AppBar(
      backgroundColor: color,
      leading: leading ??
          FadeInRight(
            duration: const Duration(milliseconds: 500),
            from: 30,
            child: Center(
              child: AppIconButton(
                icon: LucideIcons.chevronLeft,
                onClicked: onBackClicked ??
                    () {
                      Navigator.pop(context);
                    },
              ),
            ),
          ),
      centerTitle: !hasTitleWidget,
      titleSpacing: hasTitleWidget ? 0 : null,
      elevation: (notElevated ?? false) ? 0 : null,
      scrolledUnderElevation: (notElevated ?? false) ? 0 : null,
      title: titleWidget ??
          (title != null || description != null ? _column(context) : null),
      actions: actions ??
          [
            _logoClicked(context),
            const SizedBox(
              width: kDefaultPadding,
            ),
          ],
    );
  }

  GestureDetector _logoClicked(BuildContext context) {
    return GestureDetector(
      onTap: onLogoClicked ??
          () {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );

            context.read<NostrDataRepository>().homeViewController.add(true);
          },
      child: SvgPicture.asset(
        LogosIcons.logoMarkPurple,
        height: kToolbarHeight / 1.8,
        fit: BoxFit.scaleDown,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  FadeInDown _column(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      from: 15,
      child: Column(
        children: [
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          if (description != null)
            Text(
              description!,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: Theme.of(context).highlightColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
