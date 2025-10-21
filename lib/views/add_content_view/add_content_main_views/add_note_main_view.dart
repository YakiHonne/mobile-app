import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../logic/write_note_cubit/write_note_cubit.dart';
import '../../../models/flash_news_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/parsed_content_display.dart';
import '../../write_note_view/widgets/paid_note_process.dart';
import '../../write_note_view/write_note_view.dart';
import '../widgets/add_content_appbar.dart';

class AddNoteMainView extends HookWidget {
  const AddNoteMainView({
    super.key,
    this.attachedEvent,
    this.isMention,
    this.content,
    this.onSuccess,
    this.selectedExternalRelay,
  });

  final BaseEventModel? attachedEvent;
  final String? content;
  final bool? isMention;
  final String? selectedExternalRelay;
  final Function(Event)? onSuccess;

  @override
  Widget build(BuildContext context) {
    final isPaid = useState(false);
    final useSourceRelay =
        useState(appSettingsManagerCubit.getNoteSourceRelay() != null);
    final controller = useMemoized(() => MentionTagTextEditingController(), []);
    final signer = useState(currentSigner!);

    useEffect(() {
      return () {
        controller.dispose();
      };
    }, [controller]);

    useEffect(
      () {
        if (controller.text.isEmpty) {
          try {
            final text =
                (content ?? nostrRepository.userDrafts?.noteDraft ?? '')
                    .replaceAll('‡', '');

            controller.setText = text;
          } catch (e) {
            lg.i(e);
          }
        }
        return null;
      },
      [],
    );

    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteNoteCubit, WriteNoteState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: AddContentAppbar(
              actionButtonText: context.t.publish.capitalize(),
              isActionButtonEnabled: true,
              extra: _titleRow(controller, context),
              onActionClicked: () {
                context.read<WriteNoteCubit>().postNote(
                      content: getRawText(controller),
                      signer: signer.value,
                      isPaid: isPaid.value,
                      useSourceRelay: useSourceRelay.value,
                      selectedExternalRelay: selectedExternalRelay,
                      onPaymentProcess: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) {
                            return BlocProvider.value(
                              value: context.read<WriteNoteCubit>(),
                              child: const PaidNoteProcess(),
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          elevation: 0,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                      onSuccess: (ev) {
                        Navigator.pop(context);
                        onSuccess?.call(ev);
                      },
                    );
              },
            ),
          );
        },
      ),
    );

    components.add(
      Expanded(
        child: BlocBuilder<AddContentCubit, AddContentState>(
          builder: (context, state) {
            return NoteWritingComponent(
              isPaid: isPaid,
              useSourceRelay: useSourceRelay,
              isNewNote:
                  state.displayBottomNavigationBar && attachedEvent == null,
              controller: controller,
              isMention: isMention,
              attachedEvent: attachedEvent,
              signer: signer,
              onSignerChanged: (s) {
                signer.value = s;
              },
            );
          },
        ),
      ),
    );

    return BlocProvider(
      create: (context) => WriteNoteCubit(
        attachedEvent,
        isMention: isMention ?? false,
      ),
      child: Column(
        children: components,
      ),
    );
  }

  Row _titleRow(
    MentionTagTextEditingController controller,
    BuildContext context,
  ) {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            final content = getRawText(controller);

            if (content.trim().isNotEmpty) {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return ParsedContentDisplay(content: content);
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            context.t.preview,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
      ],
    );
  }

  String getRawText(MentionTagTextEditingController controller) {
    final text = controller.text;
    final mentions = controller.mentions;

    final rawContent = text.replaceAllMapped(mentionToken, (match) {
      final removedMention = mentions.removeAt(0);

      if (removedMention is Metadata) {
        return 'nostr:${Nip19.encodePubkey(removedMention.pubkey)}';
      } else {
        return '#$removedMention';
      }
    });

    return rawContent;
  }
}
