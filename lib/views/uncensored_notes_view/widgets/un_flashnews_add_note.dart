// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/profile_picture.dart';

class UnFlashNewsAddNote extends HookWidget {
  const UnFlashNewsAddNote({
    super.key,
    required this.onAdd,
  });

  final Function(String, String, bool) onAdd;

  @override
  Widget build(BuildContext context) {
    final content = useTextEditingController();
    final source = useTextEditingController();
    final isCorrect = useState(false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          children: [
            const Center(child: ModalBottomSheetHandle()),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: kRed,
                  ),
                  child: Text(
                    context.t.cancel.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kWhite,
                        ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (content.text.trim().isEmpty) {
                      BotToastUtils.showError(
                        context.t.emptyVerifiedNote.capitalizeFirst(),
                      );
                    } else {
                      onAdd.call(
                        content.text.trim(),
                        source.text.trim(),
                        isCorrect.value,
                      );
                    }
                  },
                  label: SvgPicture.asset(
                    FeatureIcons.add,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorLight,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.scaleDown,
                  ),
                  icon: Text(
                    context.t.post.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorDark,
                  ),
                ),
              ],
            ),
            const Divider(
              height: kDefaultPadding,
              thickness: 0.5,
            ),
            _seeAnything(),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              controller: content,
              decoration: const InputDecoration(
                hintText: 'What do you think about this ?',
              ),
              maxLength: 500,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: source,
              decoration: InputDecoration(
                hintText: context.t.sourceRecommended.capitalizeFirst(),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isCorrect.value
                        ? context.t.findPaidNoteCorrect.capitalizeFirst()
                        : context.t.findPaidNoteMisleading.capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                CupertinoSwitch(
                  value: isCorrect.value,
                  onChanged: (value) => isCorrect.value = value,
                  inactiveTrackColor: kRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Padding _seeAnything() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: Row(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final pubKey = nostrRepository.currentMetadata.pubkey;

                return MetadataProvider(
                  key: ValueKey(pubKey),
                  pubkey: pubKey,
                  child: (metadata, nip05) => Row(
                    children: [
                      ProfilePicture2(
                        size: 40,
                        image: metadata.picture,
                        pubkey: metadata.pubkey,
                        padding: 0,
                        strokeWidth: 1,
                        reduceSize: true,
                        strokeColor: kWhite,
                        onClicked: () {
                          openProfileFastAccess(
                            context: context,
                            pubkey: metadata.pubkey,
                          );
                        },
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t.seeAnything.capitalizeFirst(),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              context.t.writeNote.capitalizeFirst(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
