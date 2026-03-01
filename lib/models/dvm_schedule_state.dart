import 'dart:convert';

class DvmScheduleState {
  DvmScheduleState({
    required this.v,
    required this.rev,
    required this.relays,
    this.previewKeyCapsules,
    required this.counts,
    required this.support,
    required this.pendingPages,
    required this.bucketOrder,
    required this.buckets,
  });

  factory DvmScheduleState.fromJson(String str) =>
      DvmScheduleState.fromMap(json.decode(str));

  factory DvmScheduleState.fromMap(Map<String, dynamic> json) =>
      DvmScheduleState(
        v: json['v'] as int? ?? 1,
        rev: json['rev'] as int? ?? 2,
        relays: json['relays'] != null
            ? List<String>.from(json['relays'].map((x) => x))
            : [],
        previewKeyCapsules: json['previewKeyCapsules'],
        counts: DvmScheduleCounts.fromMap(json['counts'] ?? {}),
        support: DvmScheduleSupport.fromMap(json['support'] ?? {}),
        pendingPages: json['pending_pages'] != null
            ? List<DvmPendingPage>.from(json['pending_pages']
                .map((x) => DvmPendingPage.fromMap(x as Map<String, dynamic>)))
            : [],
        bucketOrder: json['bucket_order'] as String? ?? 'desc',
        buckets: json['buckets'] != null
            ? List<String>.from(json['buckets'].map((x) => x))
            : [],
      );

  final int v;
  final int rev;
  final List<String> relays;
  final dynamic previewKeyCapsules;
  final DvmScheduleCounts counts;
  final DvmScheduleSupport support;
  final List<DvmPendingPage> pendingPages;
  final String bucketOrder;
  final List<String> buckets;

  Map<String, dynamic> toMap() => {
        'v': v,
        'rev': rev,
        'relays': List<dynamic>.from(relays.map((x) => x)),
        'previewKeyCapsules': previewKeyCapsules,
        'counts': counts.toMap(),
        'support': support.toMap(),
        'pending_pages': List<dynamic>.from(pendingPages.map((x) => x.toMap())),
        'bucket_order': bucketOrder,
        'buckets': List<dynamic>.from(buckets.map((x) => x)),
      };
}

class DvmPendingPage {
  DvmPendingPage({
    required this.d,
    required this.count,
    required this.updatedAt,
    required this.hash,
  });

  factory DvmPendingPage.fromMap(Map<String, dynamic> json) => DvmPendingPage(
        d: json['d'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        updatedAt: json['updated_at'] as int? ?? 0,
        hash: json['hash'] as String? ?? '',
      );

  final String d;
  final int count;
  final int updatedAt;
  final String hash;

  Map<String, dynamic> toMap() => {
        'd': d,
        'count': count,
        'updated_at': updatedAt,
        'hash': hash,
      };
}

class DvmScheduleCounts {
  DvmScheduleCounts({
    required this.queued,
    required this.posted,
    required this.error,
    required this.canceled,
  });

  factory DvmScheduleCounts.fromMap(Map<String, dynamic> json) =>
      DvmScheduleCounts(
        queued: json['queued'] as int? ?? 0,
        posted: json['posted'] as int? ?? 0,
        error: json['error'] as int? ?? 0,
        canceled: json['canceled'] as int? ?? 0,
      );

  final int queued;
  final int posted;
  final int error;
  final int canceled;

  Map<String, dynamic> toMap() => {
        'queued': queued,
        'posted': posted,
        'error': error,
        'canceled': canceled,
      };
}

class DvmScheduleSupport {
  DvmScheduleSupport({
    required this.v,
    required this.policy,
    required this.state,
    this.prompt,
    this.invoice,
  });

  factory DvmScheduleSupport.fromMap(Map<String, dynamic> json) =>
      DvmScheduleSupport(
        v: json['v'] as int? ?? 1,
        policy: DvmSchedulePolicy.fromMap(json['policy'] ?? {}),
        state: DvmScheduleSupportState.fromMap(json['state'] ?? {}),
        prompt: json['prompt'],
        invoice: json['invoice'],
      );

  final int v;
  final DvmSchedulePolicy policy;
  final DvmScheduleSupportState state;
  final dynamic prompt;
  final dynamic invoice;

  Map<String, dynamic> toMap() => {
        'v': v,
        'policy': policy.toMap(),
        'state': state.toMap(),
        'prompt': prompt,
        'invoice': invoice,
      };
}

class DvmSchedulePolicy {
  DvmSchedulePolicy({
    required this.v,
    required this.horizonDays,
    required this.windowSchedules,
    required this.gatedFeatures,
    required this.cta,
    required this.payment,
  });

  factory DvmSchedulePolicy.fromMap(Map<String, dynamic> json) =>
      DvmSchedulePolicy(
        v: json['v'] as int? ?? 2,
        horizonDays: json['horizonDays'] as int? ?? 7,
        windowSchedules: json['windowSchedules'] as int? ?? 10,
        gatedFeatures: json['gatedFeatures'] != null
            ? List<String>.from(json['gatedFeatures'].map((x) => x))
            : [],
        cta: DvmScheduleCta.fromMap(json['cta'] ?? {}),
        payment: DvmSchedulePayment.fromMap(json['payment'] ?? {}),
      );

  final int v;
  final int horizonDays;
  final int windowSchedules;
  final List<String> gatedFeatures;
  final DvmScheduleCta cta;
  final DvmSchedulePayment payment;

  Map<String, dynamic> toMap() => {
        'v': v,
        'horizonDays': horizonDays,
        'windowSchedules': windowSchedules,
        'gatedFeatures': List<dynamic>.from(gatedFeatures.map((x) => x)),
        'cta': cta.toMap(),
        'payment': payment.toMap(),
      };
}

class DvmScheduleCta {
  DvmScheduleCta({
    required this.lud16,
    required this.message,
  });

  factory DvmScheduleCta.fromMap(Map<String, dynamic> json) => DvmScheduleCta(
        lud16: json['lud16'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  final String lud16;
  final String message;

  Map<String, dynamic> toMap() => {
        'lud16': lud16,
        'message': message,
      };
}

class DvmSchedulePayment {
  DvmSchedulePayment({
    required this.mode,
    required this.invoiceSats,
    required this.minSats,
    required this.supporterDays,
    required this.invoiceTtlSec,
  });

  factory DvmSchedulePayment.fromMap(Map<String, dynamic> json) =>
      DvmSchedulePayment(
        mode: json['mode'] as String? ?? 'nwc',
        invoiceSats: json['invoiceSats'] as int? ?? 15000,
        minSats: json['minSats'] as int? ?? 0,
        supporterDays: json['supporterDays'] as int? ?? 100,
        invoiceTtlSec: json['invoiceTtlSec'] as int? ?? 3600,
      );

  final String mode;
  final int invoiceSats;
  final int minSats;
  final int supporterDays;
  final int invoiceTtlSec;

  Map<String, dynamic> toMap() => {
        'mode': mode,
        'invoiceSats': invoiceSats,
        'minSats': minSats,
        'supporterDays': supporterDays,
        'invoiceTtlSec': invoiceTtlSec,
      };
}

class DvmScheduleSupportState {
  DvmScheduleSupportState({
    required this.scheduleCount,
    required this.freeUntilCount,
    required this.nextPromptAtCount,
    required this.supporterUntil,
    required this.isSupporter,
    required this.isUnlocked,
  });

  factory DvmScheduleSupportState.fromMap(Map<String, dynamic> json) =>
      DvmScheduleSupportState(
        scheduleCount: json['scheduleCount'] as int? ?? 0,
        freeUntilCount: json['freeUntilCount'] as int? ?? 0,
        nextPromptAtCount: json['nextPromptAtCount'] as int? ?? 0,
        supporterUntil: json['supporterUntil'] as int? ?? 0,
        isSupporter: json['isSupporter'] as bool? ?? false,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
      );

  final int scheduleCount;
  final int freeUntilCount;
  final int nextPromptAtCount;
  final int supporterUntil;
  final bool isSupporter;
  final bool isUnlocked;

  Map<String, dynamic> toMap() => {
        'scheduleCount': scheduleCount,
        'freeUntilCount': freeUntilCount,
        'nextPromptAtCount': nextPromptAtCount,
        'supporterUntil': supporterUntil,
        'isSupporter': isSupporter,
        'isUnlocked': isUnlocked,
      };
}
