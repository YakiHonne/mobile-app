import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../logic/second_reader_cubit/second_reader_cubit.dart';
import '../../../../utils/utils.dart';
import 'sheet_header.dart';

class SecondReaderPickerView extends StatelessWidget {
  const SecondReaderPickerView({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SecondReaderCubit, SecondReaderState>(
      builder: (ctx, state) {
        final cubit = ctx.read<SecondReaderCubit>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SecondReaderSheetHeader(title: context.t.second_reader_title),
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  kDefaultPadding / 2,
                  kDefaultPadding,
                  0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    state.error == 'min_words'
                        ? context.t.second_reader_min_words
                        : context.t.second_reader_error,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Flexible(
              child: state.isAnalyzing
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(kDefaultPadding * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SpinKitCircle(color: theme.primaryColor, size: 32),
                            const SizedBox(height: kDefaultPadding),
                            Text(
                              context.t.second_reader_loading,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        kDefaultPadding,
                        kDefaultPadding * 0.75,
                        kDefaultPadding,
                        kDefaultPadding * 2,
                      ),
                      itemCount: secondReaderPersonas.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: kDefaultPadding / 2),
                      itemBuilder: (_, i) {
                        final persona = secondReaderPersonas[i];
                        return PersonaCard(
                          persona: persona,
                          isLastUsed: persona.id == state.lastUsedPersonaId,
                          onTap: () => cubit.selectPersona(persona, content),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class PersonaCard extends StatelessWidget {
  const PersonaCard({
    super.key,
    required this.persona,
    required this.isLastUsed,
    required this.onTap,
  });

  final SecondReaderPersona persona;
  final bool isLastUsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding * 0.75),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: isLastUsed ? theme.primaryColor : theme.dividerColor,
            width: isLastUsed ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kDefaultPadding * 1.5),
              child: ExtendedImage.network(
                persona.imageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                loadStateChanged: (s) {
                  if (s.extendedImageLoadState == LoadState.failed) {
                    return CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          theme.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        persona.name[0],
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: kDefaultPadding * 0.75),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        persona.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.primaryColorDark,
                        ),
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 2,
                          vertical: kDefaultPadding / 4 - 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                        ),
                        child: Text(
                          persona.role,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isLastUsed)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding / 4 - 3,
                            ),
                            margin: const EdgeInsets.only(
                                left: kDefaultPadding / 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(kDefaultPadding),
                            ),
                            child: Text(
                              context.t.second_reader_last_used,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: kDefaultPadding / 4),
                  Text(
                    persona.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Icon(LucideIcons.chevronRight, size: 18, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
