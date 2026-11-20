// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../services/namecoin/namecoin_name_resolver.dart';
import '../../utils/utils.dart';
import 'data_providers.dart';

/// Enhanced NIP-05 component that displays a blockchain icon for Namecoin
/// (.bit) identifiers. Falls back to the standard NIP-05 display for
/// regular identifiers.
class Nip05NamecoinComponent extends StatelessWidget {
  const Nip05NamecoinComponent({
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
        final isNamecoin =
            n05.isNotEmpty && NamecoinNameResolver.isNamecoinIdentifier(n05);

        final displayText = removeSpace != null
            ? useNip05 != null
                ? n05
                : '@$name'
            : useNip05 != null
                ? ' $name'
                : ' @$n05';

        final color = textColor ??
            (isValid
                ? isNamecoin
                    ? const Color(0xFF4A90D9) // Namecoin blue
                    : kRed
                : Theme.of(context).highlightColor);

        if (isNamecoin && isValid) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link,
                size: (fontSize ?? 12) + 2,
                color: color,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: color,
                        fontSize: fontSize,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }

        return Text(
          displayText,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: color,
                fontSize: fontSize,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
