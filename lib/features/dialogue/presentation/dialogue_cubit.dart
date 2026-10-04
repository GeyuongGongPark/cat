import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cat/features/dialogue/presentation/dialogue_state.dart';
import 'package:cat/features/dialogue/domain/dialogue_repository.dart';

class DialogueCubit extends Cubit<DialogueState> {
  final DialogueRepository _repository;
  final Map<DialogueTraits, int> _accumulatedScores = {};
  List<DialogueStep> _dialogueSteps = [];
  int _currentStepIndex = 0;

  DialogueCubit(this._repository) : super(const DialogueState.initial());

  Future<void> startDialogue() async {
    emit(DialogueState.weatherSelection(
      options: [
        WeatherOption(
          id: 'sunny',
          label: '맑음',
          emoji: '☀️',
          traitScores: {DialogueTraits.energy: 2, DialogueTraits.playfulness: 1},
        ),
        WeatherOption(
          id: 'cloudy',
          label: '흐림',
          emoji: '☁️',
          traitScores: {DialogueTraits.calmness: 2, DialogueTraits.independence: 1},
        ),
        WeatherOption(
          id: 'rainy',
          label: '비',
          emoji: '🌧️',
          traitScores: {DialogueTraits.affection: 2, DialogueTraits.calmness: 1},
        ),
        WeatherOption(
          id: 'snowy',
          label: '눈',
          emoji: '❄️',
          traitScores: {DialogueTraits.curiosity: 2, DialogueTraits.playfulness: 1},
        ),
      ],
    ));
  }

  Future<void> selectWeather(WeatherOption option) async {
    _addScores(option.traitScores);
    
    emit(const DialogueState.loading());
    
    try {
      _dialogueSteps = await _repository.getDialogueSteps(option.id);
      _currentStepIndex = 0;
      _emitCurrentDialogueStep();
    } catch (e) {
      emit(DialogueState.error(e.toString()));
    }
  }

  Future<void> selectChoice(DialogueChoice choice) async {
    _addScores(choice.traitScores);
    
    try {
      await _repository.sendChoiceEvent(
        stepIndex: _currentStepIndex,
        choiceId: choice.id,
        currentScores: Map.from(_accumulatedScores),
      );
    } catch (e) {
      print('선택 이벤트 전송 실패: $e');
    }
    
    _currentStepIndex++;
    
    if (_currentStepIndex >= _dialogueSteps.length) {
      await _completeDialogue();
    } else {
      _emitCurrentDialogueStep();
    }
  }

  void _addScores(Map<DialogueTraits, int> scores) {
    scores.forEach((trait, score) {
      _accumulatedScores[trait] = (_accumulatedScores[trait] ?? 0) + score;
    });
  }

  void _emitCurrentDialogueStep() {
    emit(DialogueState.dialogue(
      currentStep: _dialogueSteps[_currentStepIndex],
      accumulatedScores: Map.from(_accumulatedScores),
      stepNumber: _currentStepIndex + 1,
      totalSteps: _dialogueSteps.length,
    ));
  }

  Future<void> _completeDialogue() async {
    emit(const DialogueState.loading());
    
    try {
      final result = await _repository.getMatchingResult(_accumulatedScores);
      
      emit(DialogueState.matchingResult(
        matchedCat: result.personality,
        finalScores: Map.from(_accumulatedScores),
        matchingReason: result.reason,
      ));
    } catch (e) {
      emit(DialogueState.error('매칭 결과를 가져올 수 없습니다: $e'));
    }
  }

  void reset() {
    _accumulatedScores.clear();
    _dialogueSteps = [];
    _currentStepIndex = 0;
    emit(const DialogueState.initial());
  }
}
