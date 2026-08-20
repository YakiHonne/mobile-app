part of 'second_reader_cubit.dart';

class SecondReaderPersona {
  const SecondReaderPersona({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String role;
  final String description;
  final String imageUrl;
}

const secondReaderPersonas = [
  SecondReaderPersona(
    id: 'skeptic',
    name: 'Layla',
    role: 'The Skeptic',
    description:
        'Demands evidence. Flags vague claims and unsupported assertions.',
    imageUrl:
        'https://yakihonne.s3.ap-east-1.amazonaws.com/media/images/Layla.png',
  ),
  SecondReaderPersona(
    id: 'casual',
    name: 'Marcus',
    role: 'The Casual Reader',
    description:
        'Scrolls fast. Loses interest quickly. Reacts emotionally.',
    imageUrl:
        'https://yakihonne.s3.ap-east-1.amazonaws.com/media/images/Marcus.png',
  ),
  SecondReaderPersona(
    id: 'editor',
    name: 'Nora',
    role: 'The Senior Editor',
    description:
        'Cares about structure, flow, and whether the opening earns the close.',
    imageUrl:
        'https://yakihonne.s3.ap-east-1.amazonaws.com/media/images/Nora.png',
  ),
  SecondReaderPersona(
    id: 'investor',
    name: 'Daniel',
    role: 'The Investor',
    description:
        'Looks for clarity of thesis and defensible claims. Flags hype.',
    imageUrl:
        'https://yakihonne.s3.ap-east-1.amazonaws.com/media/images/Daniel.png',
  ),
  SecondReaderPersona(
    id: 'viral',
    name: 'Zara',
    role: 'The Viral Strategist',
    description:
        'Thinks about hooks, shareability, and emotional resonance.',
    imageUrl:
        'https://yakihonne.s3.ap-east-1.amazonaws.com/media/images/Zara.png',
  ),
];

enum ReactionStatus { active, ignored, fixed }

enum ReactionSentiment { positive, negative, neutral }

enum ReactionSeverity { info, warning, critical }

class PersonaReaction {
  const PersonaReaction({
    required this.paragraphIndex,
    required this.comment,
    this.sentiment = ReactionSentiment.neutral,
    this.severity = ReactionSeverity.info,
    this.status = ReactionStatus.active,
  });

  factory PersonaReaction.fromJson(Map<String, dynamic> json) {
    return PersonaReaction(
      paragraphIndex: (json['paragraphIndex'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      sentiment: _parseSentiment(json['sentiment'] as String?),
      severity: _parseSeverity(json['severity'] as String?),
      status: _parseStatus(json['status'] as String?),
    );
  }

  final int paragraphIndex;
  final String comment;
  final ReactionSentiment sentiment;
  final ReactionSeverity severity;
  final ReactionStatus status;

  PersonaReaction copyWith({ReactionStatus? status}) {
    return PersonaReaction(
      paragraphIndex: paragraphIndex,
      comment: comment,
      sentiment: sentiment,
      severity: severity,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'paragraphIndex': paragraphIndex,
        'comment': comment,
        'sentiment': sentiment.name,
        'severity': severity.name,
        'status': status.name,
      };

  static ReactionStatus _parseStatus(String? s) {
    switch (s) {
      case 'ignored':
        return ReactionStatus.ignored;
      case 'fixed':
        return ReactionStatus.fixed;
      default:
        return ReactionStatus.active;
    }
  }

  static ReactionSentiment _parseSentiment(String? s) {
    switch (s) {
      case 'positive':
        return ReactionSentiment.positive;
      case 'negative':
        return ReactionSentiment.negative;
      default:
        return ReactionSentiment.neutral;
    }
  }

  static ReactionSeverity _parseSeverity(String? s) {
    switch (s) {
      case 'warning':
        return ReactionSeverity.warning;
      case 'critical':
        return ReactionSeverity.critical;
      default:
        return ReactionSeverity.info;
    }
  }
}

enum SecondReaderView { picker, active }

class SecondReaderState {
  const SecondReaderState({
    this.view = SecondReaderView.picker,
    this.activePersona,
    this.lastUsedPersonaId,
    this.reactions = const [],
    this.isAnalyzing = false,
    this.error,
  });

  final SecondReaderView view;
  final SecondReaderPersona? activePersona;
  final String? lastUsedPersonaId;
  final List<PersonaReaction> reactions;
  final bool isAnalyzing;
  final String? error;

  List<PersonaReaction> get activeReactions =>
      reactions.where((r) => r.status == ReactionStatus.active).toList();

  List<PersonaReaction> get resolvedReactions =>
      reactions.where((r) => r.status != ReactionStatus.active).toList();

  SecondReaderState copyWith({
    SecondReaderView? view,
    SecondReaderPersona? Function()? activePersona,
    String? Function()? lastUsedPersonaId,
    List<PersonaReaction>? reactions,
    bool? isAnalyzing,
    String? Function()? error,
  }) {
    return SecondReaderState(
      view: view ?? this.view,
      activePersona:
          activePersona != null ? activePersona() : this.activePersona,
      lastUsedPersonaId: lastUsedPersonaId != null
          ? lastUsedPersonaId()
          : this.lastUsedPersonaId,
      reactions: reactions ?? this.reactions,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error != null ? error() : this.error,
    );
  }
}
