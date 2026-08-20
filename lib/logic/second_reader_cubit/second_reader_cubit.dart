import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/http_functions_repository.dart';
import '../../repositories/localdatabase_repository.dart';
import '../subscription_cubit/usage_limit.dart';

part 'second_reader_state.dart';

/// `error` carries codes, not copy — this one tells the view to render the
/// live quota message instead of the generic failure text.
const kSecondReaderUsageError = 'usage_limit';

const _kLastPersonaKey = 'sr_last_persona_id';
const _kReactionsPrefix = 'sr_reactions_';

class SecondReaderCubit extends Cubit<SecondReaderState> {
  SecondReaderCubit()
      : super(SecondReaderState(
          lastUsedPersonaId: prefs.getString(_kLastPersonaKey),
        ));

  final Map<String, List<PersonaReaction>> _cache = {};

  @override
  void emit(SecondReaderState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> selectPersona(
      SecondReaderPersona persona, String article) async {
    final cached = _cache[persona.id];
    if (cached != null && cached.isNotEmpty) {
      emit(state.copyWith(
        view: SecondReaderView.active,
        activePersona: () => persona,
        lastUsedPersonaId: () => persona.id,
        reactions: cached,
        error: () => null,
      ));
      prefs.setString(_kLastPersonaKey, persona.id);
      return;
    }

    final persisted = _loadCached(persona.id);
    if (persisted.isNotEmpty) {
      _cache[persona.id] = persisted;
      emit(state.copyWith(
        view: SecondReaderView.active,
        activePersona: () => persona,
        lastUsedPersonaId: () => persona.id,
        reactions: persisted,
        error: () => null,
      ));
      prefs.setString(_kLastPersonaKey, persona.id);
      return;
    }

    final wordCount = article
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (wordCount < 50) {
      emit(state.copyWith(error: () => 'min_words'));
      return;
    }

    // Only a *new* analysis spends quota — cached personas above stay readable.
    if (isUsageBlocked(kUsageKeySecondReader)) {
      emit(state.copyWith(error: () => kSecondReaderUsageError));
      return;
    }

    emit(state.copyWith(
      activePersona: () => persona,
      lastUsedPersonaId: () => persona.id,
      isAnalyzing: true,
      error: () => null,
      reactions: [],
    ));

    try {
      final result = await HttpFunctionsRepository.secondReaderAnalyze(
        article: article,
        personaId: persona.id,
      );

      final rawList = result?['reactions'];
      final reactions = (rawList is List)
          ? rawList
              .whereType<Map<String, dynamic>>()
              .map(PersonaReaction.fromJson)
              .toList()
          : <PersonaReaction>[];

      _cache[persona.id] = reactions;
      _persist(persona.id, reactions);
      prefs.setString(_kLastPersonaKey, persona.id);
      refreshUsageAfterCall();

      emit(state.copyWith(
        view: SecondReaderView.active,
        reactions: reactions,
        isAnalyzing: false,
      ));
    } on DioException catch (e) {
      final fresh = await checkUsageLimit(kUsageKeySecondReader);
      emit(state.copyWith(
        isAnalyzing: false,
        error: () =>
            fresh != null ? kSecondReaderUsageError : (e.message ?? 'error'),
      ));
    } catch (_) {
      final fresh = await checkUsageLimit(kUsageKeySecondReader);
      emit(state.copyWith(
        isAnalyzing: false,
        error: () => fresh != null ? kSecondReaderUsageError : 'error',
      ));
    }
  }

  void switchToPicker() {
    emit(state.copyWith(view: SecondReaderView.picker));
  }

  void ignore(PersonaReaction reaction) {
    final updated = state.reactions
        .map((r) =>
            r == reaction ? r.copyWith(status: ReactionStatus.ignored) : r)
        .toList();
    final id = state.activePersona?.id ?? '';
    _cache[id] = updated;
    _persist(id, updated);
    emit(state.copyWith(reactions: updated));
  }

  void markFixed(PersonaReaction reaction) {
    final updated = state.reactions
        .map((r) =>
            r == reaction ? r.copyWith(status: ReactionStatus.fixed) : r)
        .toList();
    final id = state.activePersona?.id ?? '';
    _cache[id] = updated;
    _persist(id, updated);
    emit(state.copyWith(reactions: updated));
  }

  void clearReactions() {
    final id = state.activePersona?.id;
    if (id != null) {
      _cache.remove(id);
      prefs.remove('$_kReactionsPrefix$id');
    }
    emit(state.copyWith(reactions: [], error: () => null));
  }

  void dismissError() {
    emit(state.copyWith(error: () => null));
  }

  void _persist(String personaId, List<PersonaReaction> reactions) {
    final json = jsonEncode(reactions.map((r) => r.toJson()).toList());
    prefs.setString('$_kReactionsPrefix$personaId', json);
  }

  List<PersonaReaction> _loadCached(String personaId) {
    final raw = prefs.getString('$_kReactionsPrefix$personaId');
    if (raw == null) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PersonaReaction.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
