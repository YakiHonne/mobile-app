// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class TagContainer extends StatelessWidget {
  const TagContainer({
    super.key,
    required this.title,
    required this.isActive,
    required this.onClick,
    this.style,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  final String title;
  final bool isActive;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final TextStyle? style;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: borderColor != null
              ? Border.all(
                  color: borderColor!,
                  width: 0.5,
                )
              : null,
          color: backgroundColor ??
              (isActive ? Theme.of(context).cardColor : kTransparent),
        ),
        child: Text(
          title,
          style: (style ?? Theme.of(context).textTheme.labelMedium)!.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class DropdownTag extends StatelessWidget {
  const DropdownTag({
    super.key,
    required this.title,
    required this.onClick,
    required this.isActive,
  });

  final String title;
  final bool isActive;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: isActive ? Theme.of(context).cardColor : kTransparent,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    height: 1,
                  ),
            ),
            if (isActive) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.arrowDown,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
