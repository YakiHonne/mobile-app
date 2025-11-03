// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../utils/utils.dart';
import 'data_providers.dart';

class Nip05Component extends StatelessWidget {
  const Nip05Component({
    super.key,
    required this.metadata,
    this.textColor,
    this.fontSize,
    this.removeSpace,
    this.useNip05,
  });

  final Metadata metadata;
  final Color? textColor;
  final double? fontSize;
  final bool? removeSpace;
  final bool? useNip05;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: metadata.pubkey,
      child: (metadata, isValid) {
        final n05 = metadata.nip05;
        final name = metadata.getName();

        return Text(
          removeSpace != null
              ? useNip05 != null
                  ? n05
                  : '@$name'
              : useNip05 != null
                  ? ' $name'
                  : ' @$n05',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: textColor ??
                    (isValid ? kRed : Theme.of(context).highlightColor),
                fontSize: fontSize,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
