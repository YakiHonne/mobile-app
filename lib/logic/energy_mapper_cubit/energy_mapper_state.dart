part of 'energy_mapper_cubit.dart';

class SentenceEnergy {
  const SentenceEnergy({
    required this.index,
    required this.text,
    required this.score,
    required this.label,
    required this.reasons,
  });

  final int index;
  final String text;
  final double score; // 0–100 (API energy 0–1 × 100)
  final String label;
  final List<String> reasons;
}

class EnergyMapperState {
  const EnergyMapperState({
    this.sentences = const [],
    this.summary,
    this.isLoading = false,
    this.selectedIndex,
    this.error,
  });

  final List<SentenceEnergy> sentences;
  final String? summary;
  final bool isLoading;
  final int? selectedIndex;
  final String? error;

  bool get isEmpty => sentences.isEmpty;

  EnergyMapperState copyWith({
    List<SentenceEnergy>? sentences,
    String? summary,
    bool? isLoading,
    int? Function()? selectedIndex,
    String? Function()? error,
  }) {
    return EnergyMapperState(
      sentences: sentences ?? this.sentences,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      selectedIndex:
          selectedIndex != null ? selectedIndex() : this.selectedIndex,
      error: error != null ? error() : this.error,
    );
  }
}
