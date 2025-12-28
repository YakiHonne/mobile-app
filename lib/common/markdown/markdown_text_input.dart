// ignore_for_file: public_member_api_docs, sort_constructors_first, no_default_cases
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../utils/utils.dart';
import '../../views/add_content_view/related_adding_views/article_widgets/article_image_selector.dart';
import '../../views/add_content_view/related_adding_views/article_widgets/gpt_chat.dart';
import '../../views/widgets/custom_icon_buttons.dart';
import '../../views/widgets/smart_widget_selection.dart';
import '../common_regex.dart';
import 'format_markdown.dart';

/// Widget with markdown buttons
class MarkdownTextInput extends StatefulWidget {
  /// Callback called when text changed
  final Function onTextChanged;

  /// Initial value you want to display
  final String initialValue;

  /// Validator for the TextFormField
  final String? Function(String? value)? validators;

  /// Title changed
  final Function(String) onTitleChanged;

  /// Title controller
  final TextEditingController titleController;

  /// String displayed at hintText in TextFormField
  final String? label;

  /// Change the text direction of the input (RTL / LTR)
  final TextDirection textDirection;

  /// The maximum of lines that can be display in the input
  final int? maxLines;

  /// List of action the component can handle
  final List<MarkdownType> actions;

  /// Optional controller to manage the input
  final TextEditingController? controller;

  /// Overrides input text style
  final TextStyle? textStyle;

  /// If you prefer to use the dialog to insert links, you can choose to use the markdown syntax directly by setting [insertLinksByDialog] to false. In this case, the selected text will be used as label and link.
  /// Default value is true.
  final bool insertLinksByDialog;

  final bool isMenuDismissed;

  final Widget previewWidget;

  final ValueNotifier<ArticleWritingState> toggleArticleContent;

  /// Constructor for [MarkdownTextInput]
  const MarkdownTextInput(
    this.onTextChanged,
    this.onTitleChanged,
    this.titleController,
    this.initialValue,
    this.isMenuDismissed, {
    super.key,
    required this.toggleArticleContent,
    required this.previewWidget,
    this.label = '',
    this.validators,
    this.textDirection = TextDirection.ltr,
    this.maxLines = 10,
    this.actions = const [
      MarkdownType.bold,
      MarkdownType.italic,
      MarkdownType.title,
      MarkdownType.link,
      MarkdownType.list
    ],
    this.textStyle,
    this.controller,
    this.insertLinksByDialog = true,
  });

  @override
  MarkdownTextInputState createState() => MarkdownTextInputState();
}

class MarkdownTextInputState extends State<MarkdownTextInput> {
  late TextEditingController _controller;
  TextSelection textSelection =
      const TextSelection(baseOffset: 0, extentOffset: 0);
  FocusNode focusNode = FocusNode();
  final _scrollController = ScrollController();

  void onTap(
    MarkdownType type, {
    int titleSize = 1,
    String? link,
    String? selectedText,
  }) {
    final basePosition = textSelection.baseOffset;
    final noTextSelected =
        (textSelection.baseOffset - textSelection.extentOffset) == 0;

    final fromIndex = textSelection.baseOffset;
    final toIndex = textSelection.extentOffset;

    final result = FormatMarkdown.convertToMarkdown(
      type,
      _controller.text,
      fromIndex,
      toIndex,
      titleSize: titleSize,
      link: link,
      selectedText:
          selectedText ?? _controller.text.substring(fromIndex, toIndex),
    );

    _controller.value = _controller.value.copyWith(
        text: result.data,
        selection:
            TextSelection.collapsed(offset: basePosition + result.cursorIndex));

    if (noTextSelected) {
      _controller.selection = TextSelection.collapsed(
          offset: _controller.selection.end - result.replaceCursorIndex);
      focusNode.requestFocus();
    }

    widget.onTextChanged(_controller.text);
  }

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController();
    _controller.text = widget.initialValue;
    _controller.addListener(() {
      if (_controller.selection.baseOffset != -1) {
        textSelection = _controller.selection;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Scrollbar(
        controller: _scrollController,
        child: Column(
          children: [
            Expanded(
              child: widget.toggleArticleContent.value ==
                      ArticleWritingState.preview
                  ? widget.previewWidget
                  : widget.toggleArticleContent.value ==
                          ArticleWritingState.edit
                      ? _editingScrollView(context)
                      : Row(
                          children: [
                            Expanded(
                              child: _editingScrollView(context),
                            ),
                            const VerticalDivider(
                              indent: kDefaultPadding,
                              endIndent: kDefaultPadding,
                              thickness: 0.5,
                            ),
                            Expanded(
                              child: widget.previewWidget,
                            ),
                          ],
                        ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            const Divider(
              thickness: 0.3,
              height: 0,
            ),
            markdownMenu(isTablet),
          ],
        ),
      ),
    );
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

  CustomScrollView _editingScrollView(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: TextFormField(
            minLines: 1,
            maxLines: 2,
            textDirection: _detectTextDirection(widget.titleController.text),
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (event) => focusNode.requestFocus(),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            controller: widget.titleController,
            decoration: InputDecoration(
              hintText: context.t.giveMeCatchyTitle,
              hintStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).highlightColor,
                  ),
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              focusColor: Theme.of(context).primaryColorLight,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 2,
                horizontal: kDefaultPadding / 1.5,
              ),
            ),
            onChanged: widget.onTitleChanged,
          ),
        ),
        SliverToBoxAdapter(
          child: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, child) => TextFormField(
              focusNode: focusNode,
              textInputAction: TextInputAction.newline,
              controller: _controller,
              onChanged: (value) {
                widget.onTextChanged(_controller.text);
              },
              contextMenuBuilder: (
                BuildContext context,
                EditableTextState editableTextState,
              ) {
                return AdaptiveTextSelectionToolbar.editable(
                  anchors: editableTextState.contextMenuAnchors,
                  onLookUp: () {},
                  onSearchWeb: () {},
                  onShare: () {},
                  clipboardStatus: ClipboardStatus.pasteable,
                  onCopy: () => editableTextState
                      .copySelection(SelectionChangedCause.toolbar),
                  onCut: () => editableTextState
                      .cutSelection(SelectionChangedCause.toolbar),
                  onPaste: () async {
                    final String pastableText = await getPastableString();

                    final cursorPos = _controller.selection.base.offset;

                    final String suffixText =
                        _controller.text.substring(cursorPos);

                    final String specialChars = pastableText;
                    final int length = specialChars.length;

                    final String prefixText =
                        _controller.text.substring(0, cursorPos);

                    _controller.text = prefixText + specialChars + suffixText;
                    _controller.selection = TextSelection(
                      baseOffset: cursorPos + length,
                      extentOffset: cursorPos + length,
                    );

                    editableTextState.updateEditingValue(
                      editableTextState.currentTextEditingValue.copyWith(
                        text: prefixText + specialChars + suffixText,
                      ),
                    );

                    editableTextState.hideToolbar();
                  },
                  onSelectAll: () => editableTextState.selectAll(
                    SelectionChangedCause.toolbar,
                  ),
                  onLiveTextInput: () {},
                );
              },
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: widget.validators != null
                  ? (value) => widget.validators!(value)
                  : null,
              style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
              cursorColor: Theme.of(context).primaryColorDark,
              textDirection: _detectTextDirection(_controller.text),
              decoration: InputDecoration(
                hintText: widget.label,
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Theme.of(context).highlightColor),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                fillColor: kTransparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget markdownMenu(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          bottom: MediaQuery.of(context).viewInsets.bottom == 0 &&
                  widget.isMenuDismissed
              ? MediaQuery.of(context).viewPadding.bottom
              : 0,
        ),
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              Expanded(
                child: ScrollShadow(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: AbsorbPointer(
                    absorbing: widget.toggleArticleContent.value ==
                        ArticleWritingState.preview,
                    child: Opacity(
                      opacity: widget.toggleArticleContent.value ==
                              ArticleWritingState.preview
                          ? 1
                          : 0.5,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...widget.actions.map(
                            (type) {
                              switch (type) {
                                case MarkdownType.title:
                                  return ExpandableNotifier(
                                    child: Expandable(
                                      key: const Key('H#_button'),
                                      collapsed: ExpandableButton(
                                        child: const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(
                                              'H#',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      expanded: ColoredBox(
                                        color: Colors.white10,
                                        child: Row(
                                          children: [
                                            for (int i = 1; i <= 6; i++)
                                              InkWell(
                                                key: Key('H${i}_button'),
                                                onTap: () => onTap(
                                                  MarkdownType.title,
                                                  titleSize: i,
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: Text(
                                                    'H$i',
                                                    style: TextStyle(
                                                      fontSize:
                                                          (18 - i).toDouble(),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ExpandableButton(
                                              child: const Padding(
                                                padding: EdgeInsets.all(10),
                                                child: Icon(
                                                  Icons.close,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                case MarkdownType.link:
                                  return _basicInkwell(
                                    type,
                                    customOnTap: !widget.insertLinksByDialog
                                        ? null
                                        : () => setLink(type),
                                  );
                                case MarkdownType.uploadedImage:
                                  return _basicInkwell(
                                    type,
                                    customOnTap: !widget.insertLinksByDialog
                                        ? null
                                        : () => selectImage(type, context),
                                  );
                                case MarkdownType.smartWidgets:
                                  return _basicInkwell(
                                    type,
                                    customOnTap: !widget.insertLinksByDialog
                                        ? null
                                        : () =>
                                            selectSmartWidget(type, context),
                                  );
                                case MarkdownType.gpt:
                                  return _basicInkwell(
                                    type,
                                    customOnTap: () =>
                                        addGptPrompt(type, context),
                                  );
                                default:
                                  return _basicInkwell(type);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(
                endIndent: 10,
                indent: 10,
              ),
              if (isTablet)
                _writingState(context)
              else
                CustomIconButton(
                  onClicked: () {
                    widget.toggleArticleContent.value =
                        widget.toggleArticleContent.value ==
                                ArticleWritingState.edit
                            ? ArticleWritingState.preview
                            : ArticleWritingState.edit;
                  },
                  icon: widget.toggleArticleContent.value ==
                          ArticleWritingState.edit
                      ? FeatureIcons.visible
                      : FeatureIcons.notVisible,
                  size: 25,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  vd: -2,
                ),
              IconButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                icon: Icon(
                  CupertinoIcons.keyboard_chevron_compact_down,
                  color: Theme.of(context).primaryColorDark,
                  size: 25,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PullDownButton _writingState(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) {
        return ArticleWritingState.values
            .map(
              (e) => PullDownMenuItem.selectable(
                onTap: () {
                  widget.toggleArticleContent.value = e;
                },
                title: getStateTitle(e, context),
                selected: e == widget.toggleArticleContent.value,
                iconWidget: SvgPicture.asset(
                  getStateIcon(
                    e,
                    context,
                  ),
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            )
            .toList();
      },
      buttonBuilder: (context, showMenu) => CustomIconButton(
        onClicked: showMenu,
        icon: getStateIcon(widget.toggleArticleContent.value, context),
        size: 20,
        backgroundColor: kTransparent,
      ),
    );
  }

  String getStateTitle(ArticleWritingState state, BuildContext context) {
    switch (state) {
      case ArticleWritingState.edit:
        return context.t.editCode;
      case ArticleWritingState.preview:
        return context.t.previewCode;
      case ArticleWritingState.editPreview:
        return context.t.liveCode;
    }
  }

  String getStateIcon(ArticleWritingState state, BuildContext context) {
    switch (state) {
      case ArticleWritingState.edit:
        return FeatureIcons.editCode;
      case ArticleWritingState.preview:
        return FeatureIcons.previewCode;
      case ArticleWritingState.editPreview:
        return FeatureIcons.liveCode;
    }
  }

  Future<String> getPastableString() async {
    String pastableText = '';

    await Clipboard.getData('text/plain').then(
      (data) => pastableText = data?.text?.trim() ?? '',
    );

    if (pastableText.startsWith('http')) {
      if (pastableText.endsWith(Pastables.IMAGE_FORMAT_JPEG) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_JPG) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_GIF) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_PNG) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_WEBP)) {
        pastableText = '![image]($pastableText)';
      } else if (pastableText.contains(Pastables.NOSTR_SCHEME_NPROFILE)) {
        final String newPastableText = pastableText.substring(
            pastableText.indexOf(
              Pastables.NOSTR_SCHEME_NPROFILE,
            ),
            pastableText.length);

        pastableText = 'nostr:$newPastableText';
      } else if (pastableText.contains(Pastables.NOSTR_SCHEME_NADDR)) {
        final String newPastableText = pastableText.substring(
            pastableText.indexOf(
              Pastables.NOSTR_SCHEME_NADDR,
            ),
            pastableText.length);

        pastableText = 'nostr:$newPastableText';
      }
    }

    return pastableText;
  }

  Future<void> setLink(MarkdownType type) async {
    final text = _controller.text
        .substring(textSelection.baseOffset, textSelection.extentOffset);

    final textController = TextEditingController()..text = text;
    final linkController = TextEditingController();
    final textFocus = FocusNode();
    final linkFocus = FocusNode();

    final color = Theme.of(context).colorScheme.secondary;

    const textLabel = 'Text';
    const linkLabel = 'Link';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                  child: const Icon(Icons.close),
                  onTap: () => Navigator.pop(context))
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'example',
                  label: const Text(textLabel),
                  labelStyle: TextStyle(color: color),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color, width: 2)),
                ),
                autofocus: text.isEmpty,
                focusNode: textFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (value) {
                  textFocus.unfocus();
                  FocusScope.of(context).requestFocus(linkFocus);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  label: const Text(linkLabel),
                  labelStyle: TextStyle(color: color),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                autofocus: text.isNotEmpty,
                focusNode: linkFocus,
              ),
              const SizedBox(height: 10),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          actions: [
            TextButton(
              onPressed: () {
                onTap(
                  type,
                  link: linkController.text,
                  selectedText: textController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> selectImage(MarkdownType type, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ImageSelector(
          onTap: (link) {
            onTap(
              type,
              link: link,
            );
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Future<void> selectSmartWidget(
      MarkdownType type, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SmartWidgetSelection(
          onWidgetAdded: (sw) {
            onTap.call(type, link: sw.getScheme());
            Navigator.pop(context);
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Future<void> addGptPrompt(MarkdownType type, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ChatGpt(
          insertText: (text) {
            onTap(
              type,
              link: text,
            );
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _basicInkwell(MarkdownType type, {Function? customOnTap}) {
    final isSvg = type == MarkdownType.uploadedImage ||
        type == MarkdownType.gpt ||
        type == MarkdownType.image ||
        type == MarkdownType.smartWidgets;

    return InkWell(
      key: Key(type.key),
      onTap: () => customOnTap != null ? customOnTap() : onTap(type),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: isSvg
            ? SvgPicture.asset(
                getSvgIcon(type),
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  type == MarkdownType.gpt
                      ? Colors.green.shade400
                      : Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              )
            : Icon(type.icon),
      ),
    );
  }

  String getSvgIcon(MarkdownType type) {
    if (type == MarkdownType.uploadedImage) {
      return FeatureIcons.imageUpload;
    } else if (type == MarkdownType.gpt) {
      return FeatureIcons.gpt;
    } else if (type == MarkdownType.image) {
      return FeatureIcons.imageLink;
    } else {
      return FeatureIcons.smartWidget;
    }
  }
}
