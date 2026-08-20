import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/http_functions_repository.dart';
import '../../utils/utils.dart';
import '../subscription_cubit/usage_limit.dart';

part 'energy_mapper_state.dart';

class EnergyMapperCubit extends Cubit<EnergyMapperState> {
  EnergyMapperCubit() : super(const EnergyMapperState());

  @override
  void emit(EnergyMapperState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> analyze(String content) async {
    if (content.trim().isEmpty) {
      emit(const EnergyMapperState());
      return;
    }

    // Gate before spending: a blocked user never burns a call to find out.
    final limit = usageLimitFor(kUsageKeyEnergyMapper);
    if (limit != null) {
      emit(state.copyWith(isLoading: false, error: () => limit.message));
      return;
    }

    emit(state.copyWith(isLoading: true, error: () => null));

    try {
      final data =
          await HttpFunctionsRepository.energyMapper(content.trim());

      if (data == null) {
        // The cached snapshot can be stale — a fresh fetch decides whether
        // this was the quota or a generic failure.
        final fresh = await checkUsageLimit(kUsageKeyEnergyMapper);
        emit(state.copyWith(
          isLoading: false,
          error: () => fresh?.message ?? 'Failed',
        ));
        return;
      }

      final rawSentences = data['sentences'] as List<dynamic>? ?? [];
      final sentences = rawSentences.map((s) {
        final energy = (s['energy'] as num?)?.toDouble() ?? 0.0;
        return SentenceEnergy(
          index: (s['index'] as num?)?.toInt() ?? 0,
          text: s['text'] as String? ?? '',
          score: (energy * 100).clamp(0.0, 100.0),
          label: s['label'] as String? ?? '',
          reasons: [
            if ((s['reason'] as String?)?.isNotEmpty ?? false)
              s['reason'] as String,
          ],
        );
      }).toList();

      refreshUsageAfterCall();

      emit(
        EnergyMapperState(
          sentences: sentences,
          summary: data['summary'] as String?,
        ),
      );
    } catch (e) {
      lg.i(e);
      emit(state.copyWith(isLoading: false, error: () => e.toString()));
    }
  }

  void selectSentence(int index) {
    emit(state.copyWith(selectedIndex: () => index));
  }

  void clearSelection() {
    emit(state.copyWith(selectedIndex: () => null));
  }
}
