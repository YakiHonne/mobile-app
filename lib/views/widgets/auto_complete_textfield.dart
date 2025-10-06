// ignore_for_file: no_logic_in_create_state, overridden_fields

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AutoCompleteOverlayItemBuilder<T> = Widget Function(
    BuildContext context, T suggestion);

typedef Filter<T> = bool Function(T suggestion, String query);

typedef InputEventCallback<T> = Function(T data);

typedef StringCallback = Function(String data);

class AutoCompleteTextField<T> extends StatefulWidget {
  const AutoCompleteTextField({
    required this.itemSubmitted, //Callback on item selected, this is the item selected of type <T>
    required this.key, //GlobalKey used to enable addSuggestion etc
    required this.suggestions, //Suggestions that will be displayed
    required this.itemBuilder, //Callback to build each item, return a Widget
    required this.itemSorter, //Callback to sort items in the form (a of type <T>, b of type <T>)
    required this.itemFilter, //Callback to filter item: return true or false depending on input text
    this.inputFormatters,
    this.style,
    this.decoration = const InputDecoration(),
    this.textChanged, //Callback on input text changed, this is a string
    this.textSubmitted, //Callback on input text submitted, this is also a string
    this.onFocusChanged,
    this.cursorRadius,
    this.cursorWidth,
    this.cursorColor,
    this.showCursor,
    this.keyboardType = TextInputType.text,
    this.suggestionsAmount =
        5, //The amount of suggestions to show, larger values may result in them going off screen
    this.submitOnSuggestionTap =
        true, //Call textSubmitted on suggestion tap, itemSubmitted will be called no matter what
    this.clearOnSubmit = true, //Clear autoCompleteTextfield on submit
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect =
        false, //set the autoroccection on the internal text input field
    this.minLength = 1,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.unFocusOnItemSubmitted = true,
    this.isBottom = true,
  }) : super(key: key);
  final List<T> suggestions;
  final Filter<T>? itemFilter;
  final Comparator<T>? itemSorter;
  final StringCallback? textChanged, textSubmitted;
  final ValueSetter<bool>? onFocusChanged;
  final InputEventCallback<T>? itemSubmitted;
  final AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  final int suggestionsAmount;
  @override
  final GlobalKey<AutoCompleteTextFieldState<T>> key;
  final bool submitOnSuggestionTap, clearOnSubmit, unFocusOnItemSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int minLength;
  final InputDecoration decoration;
  final TextStyle? style;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color? cursorColor;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final bool? showCursor;
  final bool autofocus;
  final bool autocorrect;
  final bool isBottom;

  void clear() => key.currentState!.clear();

  void addSuggestion(T suggestion) =>
      key.currentState!.addSuggestion(suggestion);

  void removeSuggestion(T suggestion) =>
      key.currentState!.removeSuggestion(suggestion);

  void updateSuggestions(List<T> suggestions) =>
      key.currentState!.updateSuggestions(suggestions);

  void triggerSubmitted() => key.currentState!.triggerSubmitted();

  void updateDecoration(
          {InputDecoration? decoration,
          List<TextInputFormatter>? inputFormatters,
          TextCapitalization? textCapitalization,
          TextStyle? style,
          TextInputType? keyboardType,
          TextInputAction? textInputAction}) =>
      key.currentState!.updateDecoration(decoration, inputFormatters,
          textCapitalization, style, keyboardType, textInputAction);

  TextField? get textField => key.currentState!.textField;

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<T>(
        suggestions,
        textChanged,
        textSubmitted,
        onFocusChanged,
        itemSubmitted,
        itemBuilder,
        itemSorter,
        itemFilter,
        suggestionsAmount,
        submitOnSuggestionTap,
        clearOnSubmit,
        minLength,
        inputFormatters,
        textCapitalization,
        decoration,
        style,
        keyboardType,
        textInputAction,
        controller,
        cursorColor,
        cursorRadius,
        cursorWidth,
        showCursor,
        focusNode,
        autofocus,
        unFocusOnItemSubmitted,
        autocorrect,
        isBottom,
      );
}

class AutoCompleteTextFieldState<T> extends State<AutoCompleteTextField> {
  AutoCompleteTextFieldState(
    this.suggestions,
    this.textChanged,
    this.textSubmitted,
    this.onFocusChanged,
    this.itemSubmitted,
    this.itemBuilder,
    this.itemSorter,
    this.itemFilter,
    this.suggestionsAmount,
    this.submitOnSuggestionTap,
    this.clearOnSubmit,
    this.minLength,
    this.inputFormatters,
    this.textCapitalization,
    this.decoration,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.cursorColor,
    this.cursorRadius,
    this.cursorWidth,
    this.showCursor,
    this.focusNode,
    this.autofocus,
    this.unFocusOnItemSubmitted,
    this.autocorrect,
    this.isBottom,
  ) {
    textField = TextField(
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: decoration,
      style: style,
      cursorColor: cursorColor ?? Colors.black,
      showCursor: showCursor ?? true,
      cursorWidth: cursorWidth ?? 1,
      cursorRadius: cursorRadius ?? const Radius.circular(2.0),
      keyboardType: keyboardType,
      focusNode: focusNode ?? FocusNode(),
      autofocus: autofocus,
      controller: controller ?? TextEditingController(),
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      onChanged: (newText) {
        currentText = newText;
        updateOverlay(newText);

        if (textChanged != null) {
          textChanged!(newText);
        }
      },
      onTap: () {
        updateOverlay(currentText);
      },
      onSubmitted: (submittedText) =>
          triggerSubmitted(submittedText: submittedText),
    );

    if (this.controller != null) {
      currentText = this.controller!.text;
    }

    textField!.focusNode!.addListener(() {
      if (onFocusChanged != null) {
        onFocusChanged!(textField!.focusNode!.hasFocus);
      }

      if (!textField!.focusNode!.hasFocus) {
        filteredSuggestions = [];
        updateOverlay();
      } else if (currentText != '') {
        updateOverlay(currentText);
      }
    });
  }
  final LayerLink _layerLink = LayerLink();

  TextField? textField;
  List<T> suggestions;
  StringCallback? textChanged, textSubmitted;
  ValueSetter<bool>? onFocusChanged;
  InputEventCallback<T>? itemSubmitted;
  AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  Comparator<T>? itemSorter;
  OverlayEntry? listSuggestionsEntry;
  List<T>? filteredSuggestions;
  Filter<T>? itemFilter;
  int suggestionsAmount;
  int minLength;
  bool submitOnSuggestionTap, clearOnSubmit, unFocusOnItemSubmitted;
  TextEditingController? controller;
  FocusNode? focusNode;
  bool autofocus;

  String currentText = '';
  Color? cursorColor;
  double? cursorWidth;
  Radius? cursorRadius;
  bool? showCursor;
  InputDecoration decoration;
  List<TextInputFormatter>? inputFormatters;
  TextCapitalization textCapitalization;
  TextStyle? style;
  TextInputType keyboardType;
  TextInputAction textInputAction;
  bool autocorrect;
  bool isBottom;

  void updateDecoration(
      InputDecoration? decoration,
      List<TextInputFormatter>? inputFormatters,
      TextCapitalization? textCapitalization,
      TextStyle? style,
      TextInputType? keyboardType,
      TextInputAction? textInputAction) {
    if (decoration != null) {
      this.decoration = decoration;
    }

    if (inputFormatters != null) {
      this.inputFormatters = inputFormatters;
    }

    if (textCapitalization != null) {
      this.textCapitalization = textCapitalization;
    }

    if (style != null) {
      this.style = style;
    }

    if (keyboardType != null) {
      this.keyboardType = keyboardType;
    }

    if (textInputAction != null) {
      this.textInputAction = textInputAction;
    }

    setState(() {
      textField = TextField(
        inputFormatters: this.inputFormatters,
        textCapitalization: this.textCapitalization,
        decoration: this.decoration,
        style: this.style,
        keyboardType: this.keyboardType,
        focusNode: focusNode ?? FocusNode(),
        autofocus: autofocus,
        controller: controller ?? TextEditingController(),
        textInputAction: this.textInputAction,
        onChanged: (newText) {
          currentText = newText;
          updateOverlay(newText);

          if (textChanged != null) {
            textChanged!(newText);
          }
        },
        onTap: () {
          updateOverlay(currentText);
        },
        onSubmitted: (submittedText) =>
            triggerSubmitted(submittedText: submittedText),
      );
    });
  }

  void triggerSubmitted({submittedText}) {
    submittedText == null
        ? textSubmitted!(currentText)
        : textSubmitted!(submittedText);

    if (clearOnSubmit) {
      clear();
    }
  }

  void clear() {
    textField!.controller!.clear();
    currentText = '';
    updateOverlay();
  }

  void addSuggestion(T suggestion) {
    suggestions.add(suggestion);
    updateOverlay(currentText);
  }

  void removeSuggestion(T suggestion) {
    suggestions.contains(suggestion)
        ? suggestions.remove(suggestion)
        : throw Exception(
            'List does not contain suggestion and therefore cannot be removed',
          );
    updateOverlay(currentText);
  }

  void updateSuggestions(List<T> suggestions) {
    this.suggestions = suggestions;
    updateOverlay(currentText);
  }

  void updateOverlay([String? query]) {
    if (listSuggestionsEntry == null && filteredSuggestions != null) {
      final Size textFieldSize =
          (context.findRenderObject()! as RenderBox).size;
      final width = textFieldSize.width;
      final height = textFieldSize.height;

      listSuggestionsEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            width: width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, isBottom ? height : -height - 140),
              child: SizedBox(
                width: width,
                child: Card(
                  elevation: 4,
                  shadowColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: filteredSuggestions!.map(
                      (suggestion) {
                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                child: itemBuilder!(context, suggestion),
                                onTap: () {
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(
                                    () {
                                      if (submitOnSuggestionTap) {
                                        final String newText =
                                            suggestion.toString();
                                        textField!.controller!.text = newText;
                                        if (unFocusOnItemSubmitted) {
                                          textField!.focusNode!.unfocus();
                                        }
                                        itemSubmitted!(suggestion);
                                        if (clearOnSubmit) {
                                          clear();
                                        }
                                      } else {
                                        final String newText =
                                            suggestion.toString();
                                        textField!.controller!.text = newText;
                                        textChanged!(newText);
                                      }
                                    },
                                  );
                                },
                              ),
                            )
                          ],
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      );

      Overlay.of(context).insert(listSuggestionsEntry!);
    }

    filteredSuggestions = getSuggestions(
        suggestions, itemSorter, itemFilter, suggestionsAmount, query);

    listSuggestionsEntry?.markNeedsBuild();
  }

  List<T> getSuggestions(List<T> suggestions, Comparator<T>? sorter,
      Filter<T>? filter, int maxAmount, String? query) {
    if (null == query || query.length < minLength) {
      return [];
    }

    suggestions = suggestions.where((item) => filter!(item, query)).toList();
    suggestions.sort(sorter);
    if (suggestions.length > maxAmount) {
      suggestions = suggestions.sublist(0, maxAmount);
    }
    return suggestions;
  }

  @override
  void dispose() {
    // if we created our own focus node and controller, dispose of them
    // otherwise, let the caller dispose of their own instances
    if (focusNode == null) {
      textField!.focusNode!.dispose();
    }
    if (controller == null) {
      textField!.controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _layerLink, child: textField);
  }
}

class SimpleAutoCompleteTextField extends AutoCompleteTextField<String> {
  const SimpleAutoCompleteTextField({
    super.style,
    super.decoration,
    this.onFocusChanged,
    this.textChanged,
    this.textSubmitted,
    this.minLength = 1,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.cursorColor,
    this.cursorWidth,
    this.cursorRadius,
    this.showCursor,
    this.isBottom = true,
    super.keyboardType,
    required super.key,
    required super.suggestions,
    super.suggestionsAmount,
    super.submitOnSuggestionTap,
    super.clearOnSubmit,
    super.textInputAction,
    super.textCapitalization,
  }) : super(
          textChanged: textChanged,
          textSubmitted: textSubmitted,
          itemSubmitted: textSubmitted,
          itemBuilder: null,
          itemSorter: null,
          itemFilter: null,
          cursorColor: cursorColor,
          cursorWidth: cursorWidth,
          cursorRadius: cursorRadius,
          showCursor: showCursor,
        );

  @override
  final StringCallback? textChanged, textSubmitted;
  @override
  final int minLength;
  @override
  final ValueSetter<bool>? onFocusChanged;
  @override
  final TextEditingController? controller;
  @override
  final FocusNode? focusNode;
  @override
  final Color? cursorColor;
  @override
  final double? cursorWidth;
  @override
  final Radius? cursorRadius;
  @override
  final bool? showCursor;
  @override
  final bool autofocus;
  @override
  final bool isBottom;

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<String>(
        suggestions,
        textChanged,
        textSubmitted,
        onFocusChanged,
        itemSubmitted,
        (context, item) {
          return Padding(padding: const EdgeInsets.all(8.0), child: Text(item));
        },
        (a, b) {
          return a.compareTo(b);
        },
        (item, query) {
          final regex = RegExp(query, caseSensitive: false);
          return regex.hasMatch(item.toLowerCase());
        },
        suggestionsAmount,
        submitOnSuggestionTap,
        clearOnSubmit,
        minLength,
        [],
        textCapitalization,
        decoration,
        style,
        keyboardType,
        textInputAction,
        controller,
        cursorColor,
        cursorRadius,
        cursorWidth,
        showCursor,
        focusNode,
        autofocus,
        unFocusOnItemSubmitted,
        autocorrect,
        isBottom,
      );
}
