import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({
    super.key,
    this.title,
    required this.description,
    required this.icon,
  });

  final String? title;
  final String description;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding * 2,
        ),
        children: [
          SvgPicture.asset(
            icon,
            width: 45,
            height: 45,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            title ?? context.t.nothingToShowHere.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }
}

class EmptyListWithLogo extends StatelessWidget {
  const EmptyListWithLogo({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding * 2,
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              LogosIcons.logoMarkWhite,
              width: 40,
              height: 40,
              colorFilter: ColorFilter.mode(
                Theme.of(context).highlightColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
