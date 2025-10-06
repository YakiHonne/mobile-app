import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

class TitleDescriptionComponent extends StatelessWidget {
  const TitleDescriptionComponent({
    super.key,
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 6,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (description != null)
          Text(
            description!,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
      ],
    );
  }
}
