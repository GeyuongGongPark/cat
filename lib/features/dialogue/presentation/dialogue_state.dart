import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cat/features/game/domain/entities/cat_personality.dart';

part 'dialogue_state.freezed.dart';

enum DialogueTraits {
  energy,
  playfulness,
  calmness,
  independence,
  affection,
  curiosity,
}

@freezed
class DialogueState with _$DialogueState {
  const factory DialogueState.initial() = _Initial;
  
  const factory DialogueState.weatherSelection({
    required List<WeatherOption> options,
  }) = _WeatherSelection;
  
  const factory DialogueState.dialogue({
    required DialogueStep currentStep,
    required Map<DialogueTraits, int> accumulatedScores,
    required int stepNumber,
    required int totalSteps,
  }) = _Dialogue;
  
  const factory DialogueState.loading() = _Loading;
  
  const factory DialogueState.matchingResult({
    required CatPersonality matchedCat,
    required Map<DialogueTraits, int> finalScores,
    required String matchingReason,
  }) = _MatchingResult;
  
  const factory DialogueState.error(String message) = _Error;
}

class WeatherOption {
  final String id;
  final String label;
  final String emoji;
  final Map<DialogueTraits, int> traitScores;

  const WeatherOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.traitScores,
  });
}

class DialogueStep {
  final String question;
  final List<DialogueChoice> choices;

  const DialogueStep({
    required this.question,
    required this.choices,
  });
}

class DialogueChoice {
  final String id;
  final String text;
  final Map<DialogueTraits, int> traitScores;

  const DialogueChoice({
    required this.id,
    required this.text,
    required this.traitScores,
  });
}
