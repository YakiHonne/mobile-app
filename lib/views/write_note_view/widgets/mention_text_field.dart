// ignore_for_file: library_private_types_in_public_api

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../common/common_regex.dart';
import '../../../logic/write_note_cubit/write_note_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';

class ClipboardPasteMentionTextField extends StatefulWidget {
  const ClipboardPasteMentionTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onMention,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines,
    this.focusNode,
    required this.mentionTagDecoration,
    required this.style,
    required this.decoration,
  });

  final MentionTagTextEditingController controller;
  final Function(String) onChanged;
  final Function(String?)? onMention;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final int minLines;
  final int? maxLines;
  final MentionTagDecoration mentionTagDecoration;
  final TextStyle style;
  final FocusNode? focusNode;
  final InputDecoration decoration;

  @override
  State<ClipboardPasteMentionTextField> createState() =>
      _ClipboardPasteMentionTextFieldState();
}

class _ClipboardPasteMentionTextFieldState
    extends State<ClipboardPasteMentionTextField> {
  Widget _contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];
    final TextEditingValue value = editableTextState.textEditingValue;

    // Cut
    if (!editableTextState.widget.readOnly && !value.selection.isCollapsed) {
      buttonItems.add(ContextMenuButtonItem(
        label: 'Cut',
        onPressed: () {
          editableTextState.cutSelection(SelectionChangedCause.toolbar);
          ContextMenuController.removeAny();
        },
      ));
    }

    // Copy
    if (!value.selection.isCollapsed) {
      buttonItems.add(ContextMenuButtonItem(
        label: 'Copy',
        onPressed: () {
          editableTextState.copySelection(SelectionChangedCause.toolbar);
          ContextMenuController.removeAny();
        },
      ));
    }

    // Paste - ALWAYS show this (key change!)
    buttonItems.add(ContextMenuButtonItem(
      label: 'Paste',
      onPressed: () {
        _handlePaste();
        ContextMenuController.removeAny();
      },
    ));

    // Select All
    if (value.text.isNotEmpty && value.selection.isCollapsed) {
      buttonItems.add(ContextMenuButtonItem(
        label: 'Select All',
        onPressed: () {
          editableTextState.selectAll(SelectionChangedCause.toolbar);
        },
      ));
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Future<void> _handlePaste() async {
    late Function() cancel;

    final imageUrl = await mediaServersCubit.pasteImage(
      _pasteText,
      (status) {
        if (status) {
          cancel = BotToast.showLoading();
        } else {
          cancel.call();
        }
      },
    );

    if (imageUrl != null) {
      if (mounted) {
        context.read<WriteNoteCubit>().addImage([imageUrl]);
      }

      appendTextToPosition(
        controller: widget.controller,
        textToAppend: imageUrl,
      );

      widget.onChanged(widget.controller.text);
    }
  }

  Future<void> _pasteText() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final text = clipboardData!.text!;
        final selection = widget.controller.selection;
        final currentText = widget.controller.text;

        final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          text,
        );

        widget.controller.text = newText;
        widget.controller.selection = TextSelection.collapsed(
          offset: selection.start + text.length,
        );

        widget.onChanged(widget.controller.text);
      }
    } catch (e) {
      lg.i(e);
    }
  }

  TextDirection _detectTextDirection(String text) {
    // ignore: always_put_control_body_on_new_line
    if (text.isEmpty) return TextDirection.ltr;
    final first = text.split(' ').first;

    if (rtlPattern.hasMatch(first)) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final textDirection = _detectTextDirection(value.text);

        return MentionTagTextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          onMention: widget.onMention,
          onChanged: widget.onChanged,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          mentionTagDecoration: widget.mentionTagDecoration,
          style: widget.style,
          textDirection: textDirection,
          decoration: widget.decoration,
          contextMenuBuilder: _contextMenuBuilder,
        );
      },
    );
  }
}

String? getFileExtension(SimpleFileFormat format) {
  if (format == Formats.png) {
    return 'png';
  }
  if (format == Formats.jpeg) {
    return 'jpg';
  }
  if (format == Formats.gif) {
    return 'gif';
  }
  if (format == Formats.bmp) {
    return 'bmp';
  }
  if (format == Formats.tiff) {
    return 'tiff';
  }

  return null;
}
