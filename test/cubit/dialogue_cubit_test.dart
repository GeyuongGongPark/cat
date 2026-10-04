import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cat/features/game/presentation/dialogue_cubit.dart';
import 'package:cat/features/game/data/repositories/dialogue_repository.dart';
import 'package:cat/features/game/domain/entities/cat_personality.dart';

class MockDialogueRepository extends Mock implements DialogueRepository {}

void main() {
  late DialogueCubit cubit;
  late MockDialogueRepository mockRepository;

  setUp(() {
    mockRepository = MockDialogueRepository();
    cubit = DialogueCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('TC_U001: selectWeather 상태 전이', () {
    test('날씨 선택 시 DialogueProgress로 전이', () {
      cubit.selectWeather('sunny');

      expect(cubit.state, isA<DialogueProgress>());
      final state = cubit.state as DialogueProgress;
      expect(state.currentDialogueIndex, 0);
    });
  });

  group('TC_U002-TC_U004: updateTraits 점수 계산', () {
    test('TC_U002: 단일 trait 업데이트', () {
      cubit.updateTraits({'playful': 5});

      expect(cubit.dialogueTraits['playful'], 5);
    });

    test('TC_U003: 복수 trait 동시 업데이트', () {
      cubit.updateTraits({'playful': 5, 'independent': 3});

      expect(cubit.dialogueTraits['playful'], 5);
      expect(cubit.dialogueTraits['independent'], 3);
    });

    test('TC_U004: 기존 점수에 누적', () {
      cubit.updateTraits({'playful': 5});
      cubit.updateTraits({'playful': 3});

      expect(cubit.dialogueTraits['playful'], 8);
    });
  });

  group('TC_U005-TC_U006: Repository 호출', () {
    test('TC_U005: matchPersonality가 정확한 파라미터로 호출됨', () async {
      when(() => mockRepository.matchPersonality(any()))
          .thenAnswer((_) async => CatPersonality.cheeseTabi);

      cubit.updateTraits({'playful': 15, 'independent': 10});
      await cubit.completeDialogue();

      final captured = verify(() => mockRepository.matchPersonality(captureAny())).captured;
      expect(captured.single, {'playful': 15, 'independent': 10});
    });

    test('TC_U006: Repository 반환값이 state에 설정됨', () async {
      when(() => mockRepository.matchPersonality(any()))
          .thenAnswer((_) async => CatPersonality.cheeseTabi);

      await cubit.completeDialogue();

      expect(cubit.state, isA<MatchingResult>());
      final state = cubit.state as MatchingResult;
      expect(state.matchedPersonality, CatPersonality.cheeseTabi);
    });
  });

  group('TC_U007-TC_U009: 예외 처리', () {
    test('TC_U007: null choiceId 입력 시 에러 처리', () {
      cubit.selectWeather('sunny');
      cubit.selectChoice(choiceId: null);

      expect(cubit.state, isA<DialogueError>());
    });

    test('TC_U008: 빈 traits Map으로 완료', () async {
      when(() => mockRepository.matchPersonality(any()))
          .thenAnswer((_) async => CatPersonality.allBlack);

      await cubit.completeDialogue();

      final captured = verify(() => mockRepository.matchPersonality(captureAny())).captured;
      expect(captured.single, {});
    });

    test('TC_U009: Repository 예외 발생 시 Error 상태', () async {
      when(() => mockRepository.matchPersonality(any()))
          .thenThrow(Exception('Repository error'));

      await cubit.completeDialogue();

      expect(cubit.state, isA<DialogueError>());
    });
  });

  group('TC_U010-TC_U011: 경계값', () {
    test('TC_U010: 음수 점수 감소', () {
      cubit.updateTraits({'playful': 10});
      cubit.updateTraits({'playful': -3});

      expect(cubit.dialogueTraits['playful'], 7);
    });

    test('TC_U011: 점수 0 업데이트 시 값 유지', () {
      cubit.updateTraits({'playful': 5});
      cubit.updateTraits({'playful': 0});

      expect(cubit.dialogueTraits['playful'], 5);
    });
  });

  group('TC_U012: 마지막 대화 완료 플로우', () {
    test('마지막 선택 시 completeDialogue 호출', () async {
      when(() => mockRepository.matchPersonality(any()))
          .thenAnswer((_) async => CatPersonality.mackerelTabi);

      cubit.selectWeather('sunny');
      cubit.updateTraits({'playful': 10});
      cubit.setDialogueIndex(4);
      await cubit.selectChoice(choiceId: 'final_choice');

      verify(() => mockRepository.matchPersonality(any())).called(1);
      expect(cubit.state, isA<MatchingResult>());
    });
  });

  group('TC_U013-TC_U014: 복구/재시작', () {
    test('TC_U013: reset 호출 시 초기화 및 재시작', () {
      cubit.updateTraits({'playful': 10});
      cubit.setDialogueIndex(3);
      cubit.reset();

      expect(cubit.dialogueTraits, {});
      expect(cubit.currentDialogueIndex, 0);

      cubit.selectWeather('rainy');
      expect(cubit.state, isA<DialogueProgress>());
    });

    test('TC_U014: Repository 실패 후 재시도', () async {
      when(() => mockRepository.matchPersonality(any()))
          .thenThrow(Exception('First failure'));

      await cubit.completeDialogue();
      expect(cubit.state, isA<DialogueError>());

      when(() => mockRepository.matchPersonality(any()))
          .thenAnswer((_) async => CatPersonality.calico);

      await cubit.completeDialogue();
      expect(cubit.state, isA<MatchingResult>());
      final state = cubit.state as MatchingResult;
      expect(state.matchedPersonality, CatPersonality.calico);
    });
  });
}