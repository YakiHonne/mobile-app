import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/nostr_data_repository.dart';
import '../../utils/utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.description,
    this.notElevated,
    this.onBackClicked,
    this.onLogoClicked,
    this.color,
  });

  final String? title;
  final String? description;
  final bool? notElevated;
  final Function()? onBackClicked;
  final Function()? onLogoClicked;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: color,
      leading: FadeInRight(
        duration: const Duration(milliseconds: 500),
        from: 30,
        child: IconButton(
          onPressed: onBackClicked ??
              () {
                Navigator.pop(context);
              },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
      ),
      centerTitle: true,
      elevation: notElevated != null ? 0 : null,
      scrolledUnderElevation: notElevated != null ? 0 : null,
      title: title != null || description != null ? _column(context) : null,
      actions: [
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
