import 'package:cat/features/dialogue/presentation/dialogue_state.dart';
import 'package:cat/features/game/domain/entities/cat_personality.dart';

abstract class DialogueRepository {
  /// 날씨 선택에 따른 대화 스텝 목록 조회
  /// 
  /// GET /api/dialogue/steps?weather={weatherId}
  /// Response: [
  ///   {
  ///     "question": "질문 텍스트",
  ///     "choices": [
  ///       {
  ///         "id": "choice_1",
  ///         "text": "선택지 텍스트",
  ///         "traitScores": {"energy": 2, "playfulness": 1}
  ///       }
  ///     ]
  ///   }
  /// ]
  Future<List<DialogueStep>> getDialogueSteps(String weatherId);

  /// 사용자 선택 이벤트 전송 (분석/로깅용)
  /// 
  /// POST /api/dialogue/events
  /// Body: {
  ///   "stepIndex": 0,
  ///   "choiceId": "choice_1",
  ///   "currentScores": {"energy": 4, "playfulness": 2}
  /// }
  Future<void> sendChoiceEvent({
    required int stepIndex,
    required String choiceId,
    required Map<DialogueTraits, int> currentScores,
  });

  /// 최종 점수 기반 고양이 매칭 결과 조회
  /// 
  /// POST /api/dialogue/matching
  /// Body: {
  ///   "scores": {"energy": 8, "playfulness": 6, "affection": 5, ...}
  /// }
  /// Response: {
  ///   "personality": {
  ///     "id": "bengal",
  ///     "name": "벵갈",
  ///     "dominantTraits": ["energy", "playfulness"],
  ///     "description": "활발하고 장난기 많은"
  ///   },
  ///   "reason": "당신의 에너지 넘치는 선택들이 벵갈과 잘 맞습니다."
  /// }
  Future<MatchingResult> getMatchingResult(Map<DialogueTraits, int> finalScores);
}

class MatchingResult {
  final CatPersonality personality;
  final String reason;

  const MatchingResult({
    required this.personality,
    required this.reason,
  });
}
