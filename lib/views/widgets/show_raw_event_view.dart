import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import 'custom_icon_buttons.dart';
import 'data_providers.dart';
import 'dotted_container.dart';
import 'profile_picture.dart';

/// A widget that displays raw event data in a formatted JSON view
/// with syntax highlighting and copy functionality
class ShowRawEventView extends StatelessWidget {
  const ShowRawEventView({super.key, required this.attachedEvent});

  final String attachedEvent;

  // Constants
  static const double _borderRadius = 8.0;
  static const double _borderWidth = 0.5;
  static const double _initialChildSize = 0.95;
  static const double _minChildSize = 0.7;
  static const double _maxChildSize = 0.95;
  static const double _jsonWidthMultiplier = 2.0;
  static const double _profilePictureSize = 20.0;
  static const String _fontFamily = 'monospace';
  static const double _fontSize = 14.0;
  static const double _lineHeight = 1.4;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _buildContainerDecoration(context),
      child: DraggableScrollableSheet(
        initialChildSize: _initialChildSize,
        minChildSize: _minChildSize,
        maxChildSize: _maxChildSize,
        expand: false,
        builder: (_, controller) => _buildContent(context, controller),
      ),
    );
  }

  // MARK: - Container & Layout Building

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: _borderWidth,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildContent(BuildContext context, ScrollController controller) {
    final jsonString = _JsonFormatter.format(attachedEvent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: Column(
        children: [
          const ModalBottomSheetHandle(),
          _buildTitle(context),
          const SizedBox(height: kDefaultPadding / 1.5),
          _buildEventInfo(context, jsonString),
          const SizedBox(height: kDefaultPadding / 4),
          Expanded(
            child: _buildJsonDisplay(context, controller, jsonString),
          ),
          const SizedBox(height: kBottomNavigationBarHeight),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      context.t.rawEventData,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  // MARK: - Event Information Section

  Widget _buildEventInfo(BuildContext context, String jsonString) {
    final event = Event.fromString(attachedEvent);
    if (event == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: _buildInfoContainerDecoration(context),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        spacing: kDefaultPadding / 4,
        children: [
          _buildAuthorInfo(context, event),
          _buildDateInfo(context, event),
          _buildKindInfo(context, event),
        ],
      ),
    );
  }

  BoxDecoration _buildInfoContainerDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_borderRadius),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: _borderWidth,
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context, Event event) {
    return Row(
      children: [
        Text(
          '${context.t.postedBy}:',
          style: _getLabelStyle(context),
        ),
        Flexible(
          child: MetadataProvider(
            pubkey: event.pubkey,
            child: (metadata, n05) =>
                _buildAuthorTile(context, event, metadata),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorTile(BuildContext context, Event event, dynamic metadata) {
    return GestureDetector(
      onTap: () => openProfileFastAccess(
        context: context,
        pubkey: event.pubkey,
      ),
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 4,
            ),
            child: ProfilePicture3(
              size: _profilePictureSize,
              pubkey: event.pubkey,
              image: metadata.picture,
              onClicked: () => openProfileFastAccess(
                context: context,
                pubkey: event.pubkey,
              ),
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
            ),
          ),
          Flexible(
            child: Text(
              metadata.name,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context, Event event) {
    return Row(
      children: [
        Text(
          '${context.t.postedOnDate}: ',
          style: _getLabelStyle(context),
        ),
        Text(
          dateFormat3.format(
            DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
          ),
          style: _getValueStyle(context),
        ),
      ],
    );
  }

  Widget _buildKindInfo(BuildContext context, Event event) {
    return Row(
      children: [
        Text(
          '${context.t.kind}: ',
          style: _getLabelStyle(context),
        ),
        Text(
          EventKindHelper.getKindDisplayName(context, event.kind)
              .capitalizeFirst(),
          style: _getValueStyle(context),
        ),
      ],
    );
  }

  // MARK: - JSON Display Section

  Widget _buildJsonDisplay(
      BuildContext context, ScrollController controller, String jsonString) {
    final jsonWidth = MediaQuery.of(context).size.width * _jsonWidthMultiplier;
    final horizontalController = ScrollController();

    return Container(
      decoration: _buildJsonContainerDecoration(context),
      child: Column(
        children: [
          _buildJsonHeader(context, jsonString),
          Expanded(
            child: _buildScrollableJsonContent(
              context,
              controller,
              horizontalController,
              jsonString,
              jsonWidth,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildJsonContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(_borderRadius),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: _borderWidth,
      ),
    );
  }

  Widget _buildJsonHeader(BuildContext context, String jsonString) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding / 2),
          topRight: Radius.circular(kDefaultPadding / 2),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 3,
        horizontal: kDefaultPadding / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Json',
              style: _getLabelStyle(context),
            ),
          ),
          CustomIconButton(
            onClicked: () => _copyToClipboard(context, jsonString),
            icon: FeatureIcons.copy,
            size: 17,
            backgroundColor: kTransparent,
            iconColor: Theme.of(context).highlightColor,
            vd: -4,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableJsonContent(
    BuildContext context,
    ScrollController verticalController,
    ScrollController horizontalController,
    String jsonString,
    double jsonWidth,
  ) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Theme.of(context).primaryColor),
        trackColor: WidgetStateProperty.all(Theme.of(context).primaryColor),
      ),
      child: Scrollbar(
        controller: verticalController,
        thumbVisibility: true,
        trackVisibility: true,
        child: Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.top,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: verticalController,
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: jsonWidth,
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: _JsonSyntaxHighlighter.highlight(context, jsonString),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Styling Helpers

  TextStyle _getLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: Theme.of(context).highlightColor,
        );
  }

  TextStyle _getValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w500,
        );
  }

  // MARK: - Actions

  void _copyToClipboard(BuildContext context, String jsonString) {
    Clipboard.setData(ClipboardData(text: jsonString));
    BotToastUtils.showSuccess(context.t.copyRawEventData.capitalizeFirst());
  }
}

// MARK: - Helper Classes

/// Helper class for formatting JSON strings
class _JsonFormatter {
  static String format(String rawJson) {
    try {
      final Map<String, dynamic> eventMap = jsonDecode(rawJson.trim());
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(eventMap);
    } catch (e) {
      return 'Error converting event to JSON: $e';
    }
  }
}

/// Helper class for event kind display names
class EventKindHelper {
  static String getKindDisplayName(BuildContext context, int kind) {
    switch (kind) {
      case EventKind.TEXT_NOTE:
        return context.t.shortNote;
      case EventKind.LONG_FORM:
        return context.t.article;
      case EventKind.VIDEO_VERTICAL:
      case EventKind.VIDEO_HORIZONTAL:
        return context.t.video;
      case EventKind.CURATION_ARTICLES:
      case EventKind.CURATION_VIDEOS:
        return context.t.curation;
      case EventKind.CATEGORIZED_BOOKMARK:
        return context.t.bookmarkLists;
      case EventKind.SMART_WIDGET_ENH:
        return context.t.smartWidget;
      case EventKind.METADATA:
        return context.t.metadata;
      case EventKind.EVENT_DELETION:
        return context.t.delete;
      case EventKind.REACTION:
        return context.t.reactions;
      case EventKind.REPOST:
        return context.t.reposts;
      case EventKind.APP_CUSTOM:
        return context.t.appCustom;
      case EventKind.DIRECT_MESSAGE:
        return context.t.message;
      case EventKind.PRIVATE_DIRECT_MESSAGE:
        return context.t.message;
      case EventKind.GIFT_WRAP:
        return context.t.message;
      case EventKind.MUTE_LIST:
        return context.t.muteList;
      case EventKind.INTEREST_SET:
        return context.t.interests;
      case EventKind.DM_RELAYS:
        return context.t.relays;
      case EventKind.RELAY_LIST_METADATA:
        return context.t.relays;
      case EventKind.CONTACT_LIST:
        return context.t.contacts;
      case EventKind.POLL:
        return context.t.poll;
      default:
        return context.t.shortNote;
    }
  }
}

/// Helper class for JSON syntax highlighting
class _JsonSyntaxHighlighter {
  // GitHub color scheme constants
  static const _githubDarkText = Color(0xFFe6edf3);
  static const _githubLightText = Color(0xFF24292f);
  static const _githubDarkBlue = Color(0xFF79c0ff);
  static const _githubLightBlue = Color(0xFF0969da);
  static const _githubDarkString = Color(0xFFa5d6ff);
  static const _githubLightString = Color(0xFF0a3069);
  static const _githubDarkPurple = Color(0xFFd2a8ff);
  static const _githubLightPurple = Color(0xFF8250df);
  static const _githubDarkGray = Color(0xFF7d8590);
  static const _githubLightGray = Color(0xFF656d76);

  static final _jsonRegex = RegExp(
    r'("(?:[^"\\]|\\.)*")|(\btrue\b|\bfalse\b|\bnull\b)|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|([{}[\],:])',
    multiLine: true,
  );

  static Widget highlight(BuildContext context, String jsonString) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SelectableText.rich(
      _parseJsonToTextSpan(jsonString, isDark),
      style: const TextStyle(
        fontFamily: ShowRawEventView._fontFamily,
        fontSize: ShowRawEventView._fontSize,
        height: ShowRawEventView._lineHeight,
      ),
    );
  }

  static TextSpan _parseJsonToTextSpan(String jsonString, bool isDark) {
    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (final match in _jsonRegex.allMatches(jsonString)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: jsonString.substring(lastEnd, match.start),
          style: TextStyle(
            color: isDark ? _githubDarkText : _githubLightText,
          ),
        ));
      }

      final matchText = match.group(0)!;
      final color = _getColorForMatch(match, jsonString, isDark);

      spans.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < jsonString.length) {
      spans.add(TextSpan(
        text: jsonString.substring(lastEnd),
        style: TextStyle(
          color: isDark ? _githubDarkText : _githubLightText,
        ),
      ));
    }

    return TextSpan(children: spans);
  }

  static Color _getColorForMatch(Match match, String jsonString, bool isDark) {
    if (match.group(1) != null) {
      // String values and keys
      final isKey = _isJsonKey(jsonString, match.start);
      if (isKey) {
        return isDark ? _githubDarkBlue : _githubLightBlue;
      } else {
        return isDark ? _githubDarkString : _githubLightString;
      }
    } else if (match.group(2) != null) {
      // Boolean and null values
      return isDark ? _githubDarkPurple : _githubLightPurple;
    } else if (match.group(3) != null) {
      // Numbers
      return isDark ? _githubDarkPurple : _githubLightPurple;
    } else {
      // Punctuation
      return isDark ? _githubDarkGray : _githubLightGray;
    }
  }

  static bool _isJsonKey(String jsonString, int position) {
    final afterMatch = jsonString.indexOf(':', position);
    final nextQuote = jsonString.indexOf('"', position + 1);
    return afterMatch != -1 && (nextQuote == -1 || afterMatch < nextQuote);
  }
}
