// ignore_for_file: public_member_api_docs, sort_constructors_first, use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:markdown/markdown.dart' as md;

import '../../logic/smart_widget_search_cubit/smart_widget_search_cubit.dart';
import '../../models/ai_chat_model.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../widgets/custom_icon_buttons.dart';
import 'widgets/smart_widget_search_container.dart';
import 'widgets/smart_widget_search_suggestion.dart';
import 'widgets/smart_widgets_list.dart';

class SmartWidgetsSearch extends HookWidget {
  SmartWidgetsSearch({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Smart widgets');
  }

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final isSearchEnabled = useState(true);

    return BlocProvider(
      create: (context) => SmartWidgetSearchCubit(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  child: isSearchEnabled.value
                      ? const WidgetSearch()
                      : const GetInspired(),
                ),
              ),
              Positioned(
                top: isSearchEnabled.value ? 0 : null,
                bottom: !isSearchEnabled.value ? 0 : null,
                left: 0,
                right: 0,
                child: SmartWidgetSearchContainer(
                  isSearchEnabled: isSearchEnabled,
                  searchController: searchController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WidgetSearch extends HookWidget {
  const WidgetSearch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTools = useState(true);

    return SlideInUp(
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          const SizedBox(height: 120),
          Expanded(
            child: ScrollShadow(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: CustomScrollView(
                key: const ValueKey('get_inspired'),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  const SmartWidgetSearchSuggestionRow(),
                  _dvmSearch(),
                  _smartWidgetTypeBox(isTools, context),
                  const SmartWidgetsList(),
                  _seeMore(isTools),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BlocBuilder<SmartWidgetSearchCubit, SmartWidgetSearchState> _seeMore(
      ValueNotifier<bool> isTools) {
    return BlocBuilder<SmartWidgetSearchCubit, SmartWidgetSearchState>(
      builder: (context, state) {
        if (state.isSmartWidgetLoading || state.dvmSearch.isNotEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(),
          );
        }

        if (state.isAddingLoading == UpdatingState.success) {
          return SliverToBoxAdapter(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: kTransparent,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                context.read<SmartWidgetSearchCubit>().loadSmartWidgets(
                      isAdding: true,
                      isTools: isTools.value,
                    );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    context.t.seeMore.capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                  SvgPicture.asset(
                    FeatureIcons.arrowDown,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).highlightColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state.isAddingLoading == UpdatingState.progress) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding,
              ),
              child: SpinKitThreeBounce(
                color: Theme.of(context).primaryColorDark,
                size: 15,
              ),
            ),
          );
        } else {
          return const SliverToBoxAdapter(child: SizedBox());
        }
      },
    );
  }

  SliverPadding _smartWidgetTypeBox(
      ValueNotifier<bool> isTools, BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(
        top: kDefaultPadding,
        bottom: kDefaultPadding / 2,
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          spacing: kDefaultPadding / 4,
          children: [
            SmartWidgetTypeBox(
              isActive: isTools.value,
              onClicked: () {
                isTools.value = true;

                context.read<SmartWidgetSearchCubit>().loadSmartWidgets(
                      isTools: isTools.value,
                    );
              },
              title: context.t.tools.capitalizeFirst(),
            ),
            SmartWidgetTypeBox(
              isActive: !isTools.value,
              onClicked: () {
                isTools.value = false;

                context.read<SmartWidgetSearchCubit>().loadSmartWidgets(
                      isTools: isTools.value,
                    );
              },
              title: context.t.basic.capitalizeFirst(),
            ),
          ],
        ),
      ),
    );
  }

  BlocBuilder<SmartWidgetSearchCubit, SmartWidgetSearchState> _dvmSearch() {
    return BlocBuilder<SmartWidgetSearchCubit, SmartWidgetSearchState>(
      buildWhen: (previous, current) => previous.dvmSearch != current.dvmSearch,
      builder: (context, state) {
        if (state.dvmSearch.isNotEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: kDefaultPadding / 2,
              ),
              child: Row(
                spacing: kDefaultPadding / 2,
                children: [
                  Expanded(
                    child: Text(
                      context.t.searchingFor(name: state.dvmSearch),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Theme.of(context).highlightColor),
                    ),
                  ),
                  CustomIconButton(
                    onClicked: () {
                      context.read<SmartWidgetSearchCubit>().clearSearch();
                    },
                    icon: FeatureIcons.closeRaw,
                    size: 15,
                    vd: -2,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ],
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(
          child: SizedBox(),
        );
      },
    );
  }
}

class GetInspired extends StatefulWidget {
  // Changed to StatefulWidget
  const GetInspired({super.key});

  @override
  GetInspiredState createState() => GetInspiredState();
}

class GetInspiredState extends State<GetInspired> {
  final ScrollController _scrollController = ScrollController();
  Set<String> animatedMessage = {};
  Set<String> currentlyAnimating = {};
  String? _lastMessageId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideInDown(
      duration: const Duration(milliseconds: 200),
      child: BlocConsumer<SmartWidgetSearchCubit, SmartWidgetSearchState>(
        listenWhen: (previous, current) {
          // Only listen when a NEW message is actually added
          if (previous.messages.length != current.messages.length &&
              current.messages.isNotEmpty) {
            final newMessage = current.messages.last;
            // Check if this is truly a new message that hasn't been animated yet
            return _lastMessageId != newMessage.id && !newMessage.isCurrentUser;
          }
          return false;
        },
        listener: (context, state) async {
          if (state.messages.isNotEmpty) {
            final newMessage = state.messages.last;
            if (!newMessage.isCurrentUser) {
              // Update the last message ID and mark as currently animating
              _lastMessageId = newMessage.id;
              currentlyAnimating.add(newMessage.id);
            }
          }
        },
        buildWhen: (previous, current) =>
            previous.messages != current.messages ||
            previous.isAiLoading != current.isAiLoading,
        builder: (context, state) {
          // Initialize animation state for existing messages when view is first built
          if (animatedMessage.isEmpty &&
              currentlyAnimating.isEmpty &&
              state.messages.isNotEmpty) {
            for (final message in state.messages) {
              if (!message.isCurrentUser) {
                animatedMessage.add(message.id);
              }
            }
          }

          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (_scrollController.hasClients && state.messages.isNotEmpty) {
                _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          );

          return Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.messages.isEmpty) {
                      return const Center(child: SizedBox());
                    }

                    return _smartWidgetMessagesList(context, state);
                  },
                ),
              ),
              // ... rest remains the same
              _isAiLoading(context, state),
              _aiErrorMessage(state, context),
              const SizedBox(height: 120),
            ],
          );
        },
      ),
    );
  }

  AnimatedCrossFade _aiErrorMessage(
      SmartWidgetSearchState state, BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(
        width: double.infinity,
      ),
      secondChild: Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          margin: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(state.aiErrorMessage)),
              CustomIconButton(
                onClicked: () {
                  context.read<SmartWidgetSearchCubit>().removeAiErrorMessage();
                },
                icon: FeatureIcons.closeRaw,
                size: 15,
                backgroundColor: kTransparent,
                vd: -2,
              ),
            ],
          )),
      crossFadeState: state.aiErrorMessage.isNotEmpty
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  AnimatedCrossFade _isAiLoading(
      BuildContext context, SmartWidgetSearchState state) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(
        width: double.infinity,
      ),
      secondChild: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 2,
              horizontal: kDefaultPadding,
            ),
            margin: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding),
            ),
            child: SpinKitThreeBounce(
              color: Theme.of(context).primaryColorDark,
              size: 10,
            ),
          ),
        ],
      ),
      crossFadeState: state.isAiLoading
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  ScrollShadow _smartWidgetMessagesList(
      BuildContext context, SmartWidgetSearchState state) {
    return ScrollShadow(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.custom(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding,
        ),
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            final message = state.messages[state.messages.length - 1 - index];

            // Only animate if this message is currently supposed to be animating
            final shouldAnimate = currentlyAnimating.contains(message.id);

            return SmartWidgetMessageContainer(
              key: ValueKey(message.id),
              message: message,
              animate: shouldAnimate,
              onAnimationComplete: () {
                // Only process completion if the message was actually animating
                if (currentlyAnimating.contains(message.id)) {
                  setState(() {
                    currentlyAnimating.remove(message.id);
                    animatedMessage.add(message.id);
                  });
                }
              },
            );
          },
          childCount: state.messages.length,
          findChildIndexCallback: (Key key) {
            final valueKey = key as ValueKey<String>;
            final val = state.messages.indexWhere(
              (message) => message.id == valueKey.value,
            );
            return state.messages.length - 1 - val;
          },
        ),
      ),
    );
  }
}

class SmartWidgetMessageContainer extends StatelessWidget {
  const SmartWidgetMessageContainer({
    super.key,
    required this.message,
    required this.animate,
    this.onAnimationComplete, // Add this line
  });

  final AiChatMessage message;
  final bool animate;
  final VoidCallback? onAnimationComplete; // Add this line

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: !message.isCurrentUser
                  ? null
                  : const EdgeInsets.all(kDefaultPadding / 2),
              decoration: !message.isCurrentUser
                  ? null
                  : BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    ),
              margin: EdgeInsets.only(
                left: message.isCurrentUser ? kDefaultPadding : 0,
                right: !message.isCurrentUser ? kDefaultPadding : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isCurrentUser)
                    SelectableText(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    TypingText(
                      markdownText: message.content,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      animate: animate,
                      onLinkClicked: (url) {
                        openWebPage(url: url);
                      },
                      onAnimationComplete: onAnimationComplete, // Add this line
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingText extends StatefulWidget {
  final String markdownText;
  final Duration speed;
  final TextStyle? textStyle;
  final bool animate;
  final void Function(String)? onLinkClicked;
  final VoidCallback? onAnimationComplete;

  const TypingText({
    super.key,
    required this.markdownText,
    required this.animate,
    this.speed = const Duration(milliseconds: 30),
    this.textStyle,
    this.onLinkClicked,
    this.onAnimationComplete,
  });

  @override
  TypingTextState createState() => TypingTextState();
}

class TypingTextState extends State<TypingText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _hasCompletedAnimation = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If text content changed, reset
    if (oldWidget.markdownText != widget.markdownText) {
      _timer?.cancel();
      _currentIndex = 0;
      _displayedText = '';
      _hasCompletedAnimation = false;
      _startTyping();
    }
  }

  void _startTyping() {
    if (widget.animate && !_hasCompletedAnimation) {
      _timer = Timer.periodic(widget.speed, (timer) {
        if (_currentIndex < widget.markdownText.length) {
          setState(() {
            _displayedText =
                widget.markdownText.substring(0, _currentIndex + 1);
            _currentIndex++;
          });
        } else {
          timer.cancel();
          _hasCompletedAnimation = true;
          // Call the completion callback
          widget.onAnimationComplete?.call();
        }
      });
    } else {
      setState(() {
        _displayedText = widget.markdownText;
      });
      if (!_hasCompletedAnimation) {
        _hasCompletedAnimation = true;
        widget.onAnimationComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomMarkdownWidget(markdownData: _displayedText);
  }
}

class CustomMarkdownWidget extends StatelessWidget {
  final String markdownData;
  final double kDefaultPadding;

  const CustomMarkdownWidget({
    super.key,
    required this.markdownData,
    this.kDefaultPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdownData,
      selectable: true,
      builders: {
        'code': CodeElementBuilder(context: context), // Back to 'code' builder
      },
      styleSheet: MarkdownStyleSheet(
        // Disable the default code styling since we're handling it in the builder
        code: const TextStyle(),

        codeblockPadding: EdgeInsets.all(kDefaultPadding),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CodeElementBuilder({required this.context});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Check if this is a code block (has class attribute) or inline code
    final hasLanguageClass = element.attributes['class'] != null &&
        element.attributes['class']!.startsWith('language-');

    if (!hasLanguageClass) {
      // This is inline code - return styled widget without line jumping
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Text(
          element.textContent,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
    }

    // This is a code block - use your original structure
    var language = '';
    final className = element.attributes['class'] ?? '';
    language = className.substring(9); // Remove 'language-' prefix

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language label (optional)
        if (language.isNotEmpty) _languageRow(language, element),
        _highlightView(element, language),
      ],
    );
  }

  Container _highlightView(md.Element element, String language) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(kDefaultPadding / 2),
          bottomLeft: Radius.circular(kDefaultPadding / 2),
        ),
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HighlightView(
          element.textContent,
          language: language.isEmpty ? 'plaintext' : language,
          theme: getCurrentTheme(context),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Padding _languageRow(String language, md.Element element) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
        horizontal: kDefaultPadding / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              language.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).highlightColor,
              ),
            ),
          ),
          CustomIconButton(
            onClicked: () async {
              await Clipboard.setData(
                ClipboardData(text: element.textContent),
              );
              BotToastUtils.showSuccess(context.t.textSuccesfulyCopied);
            },
            icon: FeatureIcons.copy,
            size: 17,
            backgroundColor: kTransparent,
            vd: -4,
          ),
        ],
      ),
    );
  }
}

Map<String, TextStyle> getCurrentTheme(BuildContext context) {
  return {
    'root': Theme.of(context).textTheme.bodyMedium!.copyWith(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
    'comment': TextStyle(
      color: Theme.of(context).highlightColor,
      fontStyle: FontStyle.italic,
    ),
    'quote': TextStyle(
      color: Theme.of(context).highlightColor,
      fontStyle: FontStyle.italic,
    ),
    'keyword':
        const TextStyle(color: Color(0xff333333), fontWeight: FontWeight.bold),
    'selector-tag':
        const TextStyle(color: Color(0xff333333), fontWeight: FontWeight.bold),
    'subst': const TextStyle(
        color: Color(0xff333333), fontWeight: FontWeight.normal),
    'number': const TextStyle(color: kGreen),
    'literal': const TextStyle(color: kGreen),
    'variable': const TextStyle(color: kGreen),
    'template-variable': const TextStyle(
      color: kGreen,
    ),
    'string': const TextStyle(
      color: Color(0xffdd1144),
    ),
    'doctag': const TextStyle(
      color: Color(0xffdd1144),
    ),
    'title': const TextStyle(
      color: Color(0xff990000),
      fontWeight: FontWeight.bold,
    ),
    'section': const TextStyle(
      color: Color(0xff990000),
      fontWeight: FontWeight.bold,
    ),
    'selector-id': const TextStyle(
      color: Color(0xff990000),
      fontWeight: FontWeight.bold,
    ),
    'type': const TextStyle(
      color: Color(0xff445588),
      fontWeight: FontWeight.bold,
    ),
    'tag': const TextStyle(
      color: Color(0xff000080),
      fontWeight: FontWeight.normal,
    ),
    'name': const TextStyle(
      color: Color(0xff000080),
      fontWeight: FontWeight.normal,
    ),
    'attribute': const TextStyle(
      color: Color(0xff000080),
      fontWeight: FontWeight.normal,
    ),
    'regexp': const TextStyle(
      color: Color(0xff009926),
    ),
    'link': const TextStyle(
      color: Color(0xff009926),
    ),
    'symbol': const TextStyle(
      color: Color(0xff990073),
    ),
    'bullet': const TextStyle(
      color: Color(0xff990073),
    ),
    'built_in': const TextStyle(
      color: Color(0xff0086b3),
    ),
    'builtin-name': const TextStyle(
      color: Color(0xff0086b3),
    ),
    'meta': const TextStyle(
      color: Color(0xff999999),
      fontWeight: FontWeight.bold,
    ),
    'deletion': const TextStyle(
      backgroundColor: Color(0xffffdddd),
    ),
    'addition': const TextStyle(
      backgroundColor: Color(0xffddffdd),
    ),
    'emphasis': const TextStyle(
      fontStyle: FontStyle.italic,
    ),
    'strong': const TextStyle(
      fontWeight: FontWeight.bold,
    ),
  };
}
