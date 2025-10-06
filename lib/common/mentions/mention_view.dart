import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mentions.dart';

class FlutterMentions extends StatefulWidget {
  const FlutterMentions({
    required this.mentions,
    super.key,
    this.defaultText,
    this.suggestionPosition = SuggestionPosition.bottom,
    this.suggestionListHeight = 300.0,
    this.onMarkupChanged,
    this.onMentionAdd,
    this.onSearchChanged,
    this.leading = const [],
    this.trailing = const [],
    this.suggestionListDecoration,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.readOnly = false,
    this.showCursor,
    this.maxLength,
    this.maxLengthEnforcement = MaxLengthEnforcement.none,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.onTap,
    this.buildCounter,
    this.scrollPhysics,
    this.scrollController,
    this.autofillHints,
    this.appendSpaceOnAdd = true,
    this.hideSuggestionList = false,
    this.onSuggestionVisibleChanged,
  });

  final bool hideSuggestionList;

  /// default text for the Mention Input.
  final String? defaultText;

  /// Triggers when the suggestion list visibility changed.
  final Function(bool)? onSuggestionVisibleChanged;

  /// List of Mention that the user is allowed to triggered
  final List<Mention> mentions;

  /// Leading widgets to show before teh Input box, helps preseve the size
  /// size for the Portal widget size.
  final List<Widget> leading;

  /// Trailing widgets to show before teh Input box, helps preseve the size
  /// size for the Portal widget size.
  final List<Widget> trailing;

  /// Suggestion modal position, can be alligned to top or bottom.
  ///
  /// Defaults to [SuggestionPosition.bottom].
  final SuggestionPosition suggestionPosition;

  /// Triggers when the suggestion was added by tapping on suggestion.
  final Function(Map<String, dynamic>)? onMentionAdd;

  /// Max height for the suggestion list
  ///
  /// Defaults to `300.0`
  final double suggestionListHeight;

  /// A Functioned which is triggered when ever the input changes
  /// but with the markup of the selected mentions
  ///
  /// This is an optional porperty.
  final ValueChanged<String>? onMarkupChanged;

  final void Function(String trigger, String value)? onSearchChanged;

  /// Decoration for the Suggestion list.
  final BoxDecoration? suggestionListDecoration;

  /// Focus node for controlling the focus of the Input.
  final FocusNode? focusNode;

  /// Should selecting a suggestion add a space at the end or not.
  final bool appendSpaceOnAdd;

  /// The decoration to show around the text field.
  final InputDecoration decoration;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  /// {@macro flutter.widgets.editableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to the `subtitle1` text style from the current [Theme].
  final TextStyle? style;

  /// {@macro flutter.widgets.editableText.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.widgets.editableText.textDirection}
  final TextDirection? textDirection;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.services.textInput.enableSuggestions}
  final bool enableSuggestions;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int? maxLines;

  /// {@macro flutter.widgets.editableText.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.editableText.expands}
  final bool expands;

  /// {@macro flutter.widgets.editableText.readOnly}
  final bool readOnly;

  /// {@macro flutter.widgets.editableText.showCursor}
  final bool? showCursor;

  /// If [maxLength] is set to this value, only the "current input length"
  /// part of the character counter is shown.
  static const int noMaxLength = -1;

  /// The maximum number of characters (Unicode scalar values) to allow in the
  /// text field.
  final int? maxLength;

  /// If true, prevents the field from allowing more than [maxLength]
  /// characters.
  ///
  /// If [maxLength] is set, [maxLengthEnforcement] indicates whether or not to
  /// enforce the limit, or merely provide a character counter and warning when
  /// [maxLength] is exceeded.
  final MaxLengthEnforcement maxLengthEnforcement;

  /// {@macro flutter.widgets.editableText.onChanged}
  final ValueChanged<String>? onChanged;

  /// {@macro flutter.widgets.editableText.onEditingComplete}
  final VoidCallback? onEditingComplete;

  /// {@macro flutter.widgets.editableText.onSubmitted}
  final ValueChanged<String>? onSubmitted;

  /// If false the text field is "disabled": it ignores taps and its
  /// [decoration] is rendered in grey.
  ///
  /// If non-null this property overrides the [decoration]'s
  /// [Decoration.enabled] property.
  final bool? enabled;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius? cursorRadius;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to [ThemeData.cursorColor] or [CupertinoTheme.primaryColor]
  /// depending on [ThemeData.platform] .
  final Color? cursorColor;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [ThemeData.primaryColorBrightness].
  final Brightness? keyboardAppearance;

  /// {@macro flutter.widgets.editableText.scrollPadding}
  final EdgeInsets scrollPadding;

  /// {@macro flutter.widgets.editableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// {@macro flutter.rendering.editable.selectionEnabled}
  bool get selectionEnabled => enableInteractiveSelection;

  /// Called for each distinct tap except for every second tap of a double tap.
  final GestureTapCallback? onTap;

  /// Callback that generates a custom [InputDecorator.counter] widget.
  ///
  /// See [InputCounterWidgetBuilder] for an explanation of the passed in
  /// arguments.  The returned widget will be placed below the line in place of
  /// the default widget built when [counterText] is specified.
  ///
  /// The returned widget will be wrapped in a [Semantics] widget for
  /// accessibility, but it also needs to be accessible itself.  For example,
  /// if returning a Text widget, set the [semanticsLabel] property.
  final InputCounterWidgetBuilder? buildCounter;

  /// {@macro flutter.widgets.editableText.scrollPhysics}
  final ScrollPhysics? scrollPhysics;

  /// {@macro flutter.widgets.editableText.scrollController}
  final ScrollController? scrollController;

  /// {@macro flutter.widgets.editableText.autofillHints}
  /// {@macro flutter.services.autofill.autofillHints}
  final Iterable<String>? autofillHints;

  @override
  FlutterMentionsState createState() => FlutterMentionsState();
}

class FlutterMentionsState extends State<FlutterMentions> {
  AnnotationEditingController? controller;
  ValueNotifier<bool> showSuggestions = ValueNotifier(false);
  LengthMap? _selectedMention;
  String _pattern = '';

  // Store selected mentions
  List<Map<String, dynamic>> selectedMentions = [];

  Map<String, Annotation> mapToAnotation() {
    final data = <String, Annotation>{};

    for (final element in widget.mentions) {
      for (final e in element.data) {
        if (!selectedMentions.any((m) => m['id'] == e['id'])) {
          if (e['style'] != null) {
            data["${element.trigger}${e['name']}"] = Annotation(
              style: e['style'],
              id: e['id'],
              display: e['name'],
              trigger: element.trigger,
              disableMarkup: element.disableMarkup,
              markupBuilder: element.markupBuilder,
            );
          } else {
            data["${element.trigger}${e['name']}"] = Annotation(
              style: element.style,
              id: e['id'],
              display: e['name'],
              trigger: element.trigger,
              disableMarkup: element.disableMarkup,
              markupBuilder: element.markupBuilder,
            );
          }
        }
      }
    }

    return data;
  }

  void addMention(Map<String, dynamic> value, [Mention? list]) {
    // Only execute if a mention is selected from the list
    if (_selectedMention == null) {
      return; // Prevent adding if no mention selected
    }

    final selectedMention = _selectedMention!;

    setState(() {
      _selectedMention = null; // Clear selected mention after addition
    });

    final list0 = widget.mentions
        .firstWhere((element) => selectedMention.str.contains(element.trigger));

    // Replace the selected text with the new mention
    controller!.text = controller!.value.text.replaceRange(
      selectedMention.start,
      selectedMention.end,
      "${list0.trigger}${value['name']}${widget.appendSpaceOnAdd ? ' ' : ''}",
    );

    if (widget.onMentionAdd != null) {
      widget.onMentionAdd!(value);
    }

    // Move the cursor to the next position after the new mention
    var nextCursorPosition =
        selectedMention.start + 1 + value['name']?.length as int? ?? 0;
    if (widget.appendSpaceOnAdd) {
      nextCursorPosition++;
    }
    controller!.selection =
        TextSelection.fromPosition(TextPosition(offset: nextCursorPosition));
  }

  void updateControllerMapping() {
    final updatedMapping = mapToAnotation();

    // Include previously selected mentions in the mapping
    for (final mention in selectedMentions) {
      final mentionText = "${mention['name']}";
      updatedMapping[mentionText] = Annotation(
        style: const TextStyle(
            color: Colors.blue), // Use the same style as other mentions
        id: mention['id'],
        display: mention['name'],
        trigger: '@', // Assuming '@' is the trigger for mentions
      );
    }

    controller!.mapping = updatedMapping;
  }

  void suggestionListener() {
    final cursorPos = controller!.selection.baseOffset;

    if (cursorPos >= 0) {
      var pos = 0;

      final lengthMap = <LengthMap>[];

      // Split the text into words and create a list with start & end positions
      controller!.value.text.split(RegExp(r'(\s)')).forEach((element) {
        lengthMap.add(
            LengthMap(str: element, start: pos, end: pos + element.length));

        pos += element.length + 1; // Adjust position for next word
      });

      // Find the word that matches the current position of the cursor
      final val = lengthMap.indexWhere((element) {
        _pattern = widget.mentions.map((e) => e.trigger).join('|');

        // Check if the current word matches the mention pattern
        return element.end == cursorPos &&
            element.str.toLowerCase().contains(RegExp(_pattern));
      });

      // Show suggestions if a match is found
      showSuggestions.value = val != -1;

      // Set _selectedMention based on user typing but without automatic selection
      if (val != -1) {
        _selectedMention =
            lengthMap[val]; // Only update the position for display
      } else {
        _selectedMention = null; // Reset if no valid mention found
      }
    }
  }

  void inputListeners() {
    if (widget.onChanged != null) {
      widget.onChanged!(controller!.text);
    }

    if (widget.onMarkupChanged != null) {
      widget.onMarkupChanged!(controller!.markupText);
    }

    if (widget.onSearchChanged != null && _selectedMention?.str != null) {
      final str = _selectedMention!.str.toLowerCase();

      widget.onSearchChanged!(str[0], str.substring(1));
    }
  }

  @override
  void initState() {
    final data = mapToAnotation();

    controller = AnnotationEditingController(data);

    if (widget.defaultText != null) {
      controller!.text = widget.defaultText!;
    }

    // setup a listener to figure out which suggestions to show based on the trigger
    controller!.addListener(suggestionListener);

    controller!.addListener(inputListeners);

    super.initState();
  }

  @override
  void dispose() {
    controller!.removeListener(suggestionListener);
    controller!.removeListener(inputListeners);

    super.dispose();
  }

  @override
  void didUpdateWidget(widget) {
    super.didUpdateWidget(widget);

    // Update the mapping with selected mentions
    updateControllerMapping();
  }

  @override
  Widget build(BuildContext context) {
    // Filter the list based on the selection
    final list = _selectedMention != null
        ? widget.mentions.firstWhere(
            (element) => _selectedMention!.str.contains(element.trigger))
        : widget.mentions[0];

    return Row(
      children: [
        ...widget.leading,
        Expanded(
          child: Column(
            children: [
              TextField(
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                focusNode: widget.focusNode,
                keyboardType: widget.keyboardType,
                keyboardAppearance: widget.keyboardAppearance,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
                textAlign: widget.textAlign,
                textDirection: widget.textDirection,
                readOnly: widget.readOnly,
                showCursor: widget.showCursor,
                autofocus: widget.autofocus,
                autocorrect: widget.autocorrect,
                maxLengthEnforcement: widget.maxLengthEnforcement,
                cursorColor: widget.cursorColor,
                cursorRadius: widget.cursorRadius,
                cursorWidth: widget.cursorWidth,
                buildCounter: widget.buildCounter,
                autofillHints: widget.autofillHints,
                decoration: widget.decoration,
                expands: widget.expands,
                onEditingComplete: widget.onEditingComplete,
                onTap: widget.onTap,
                onSubmitted: widget.onSubmitted,
                enabled: widget.enabled,
                enableInteractiveSelection: widget.enableInteractiveSelection,
                enableSuggestions: widget.enableSuggestions,
                scrollController: widget.scrollController,
                scrollPadding: widget.scrollPadding,
                scrollPhysics: widget.scrollPhysics,
                controller: controller,
              ),
              if (!widget.hideSuggestionList && showSuggestions.value)
                OptionList(
                  suggestionListHeight: widget.suggestionListHeight,
                  suggestionBuilder: list.suggestionBuilder,
                  suggestionListDecoration: widget.suggestionListDecoration,
                  data: list.data.where((element) {
                    final ele = element['display'].toLowerCase();
                    final str = _selectedMention != null
                        ? _selectedMention!.str
                            .toLowerCase()
                            .replaceAll(RegExp(_pattern), '')
                        : '';

                    // Avoid showing already selected mentions
                    final bool isSelected = selectedMentions
                        .any((mention) => mention['name'].toLowerCase() == ele);

                    // Return true if it matches the input but skip already selected ones
                    return !isSelected &&
                        (ele == str ? false : ele.contains(str));
                  }).toList(),
                  onTap: (value) {
                    addMention(value, list); // Add mention on tap
                    showSuggestions.value =
                        false; // Hide suggestions after selection
                  },
                )
              else
                Container(),
            ],
          ),
        ),
        ...widget.trailing,
      ],
    );
  }
}
