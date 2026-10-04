import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:your_app/domain/game/game_cubit.dart';
import 'package:your_app/domain/game/game_state.dart';
import 'package:your_app/data/game_repository.dart';
import 'package:your_app/domain/offline/offline_progress_calculator.dart';
import 'package:your_app/domain/cat/cat_traits.dart';
import 'package:your_app/domain/cat/cat_personality.dart';
import 'package:your_app/domain/dialogue/dialogue_cubit.dart';
import 'package:your_app/data/dialogue_repository.dart';
import 'package:your_app/models/cat_state.dart';
import 'package:your_app/models/offline_rewards.dart';

class MockGameRepository extends Mock implements GameRepository {}
class MockDialogueRepository extends Mock implements DialogueRepository {}

void main() {
  group('TC_U001-U003: GameCubit 기본 플로우', () {
    late GameCubit cubit;
    late MockGameRepository repository;

    setUp(() {
      repository = MockGameRepository();
      final mockState = CatState(
        id: '1',
        name: 'test',
        level: 1,
        energy: 50,
        hunger: 30,
        affection: 50,
        experience: 0,
      );
      when(() => repository.getCatState()).thenAnswer((_) async => mockState);
      cubit = GameCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    blocTest<GameCubit, GameStateSealed>(
      'TC_U001: 초기화 시 getCatState 호출 및 GameLoaded 전환',
      build: () => cubit,
      act: (_) async => await Future.delayed(Duration(milliseconds: 100)),
      verify: (_) {
        verify(() => repository.getCatState()).called(1);
      },
      expect: () => [isA<GameLoaded>()],
    );

    blocTest<GameCubit, GameStateSealed>(
      'TC_U002: feedCat 호출 시 레포지토리 호출 및 상태 갱신',
      build: () {
        final updatedState = CatState(
          id: '1',
          name: 'test',
          level: 1,
          energy: 40,
          hunger: 20,
          affection: 50,
          experience: 0,
        );
        when(() => repository.feedCat()).thenAnswer((_) async => updatedState);
        return cubit;
      },
      act: (c) async {
        await Future.delayed(Duration(milliseconds: 100));
        await c.feedCat();
      },
      verify: (_) {
        verify(() => repository.feedCat()).called(1);
      },
      expect: () => [
        isA<GameLoaded>(),
        isA<GameLoaded>().having((s) => s.catState.energy, 'energy', 40),
      ],
    );

    blocTest<GameCubit, GameStateSealed>(
      'TC_U003: playCat 호출 시 레포지토리 호출 및 상태 갱신',
      build: () {
        final updatedState = CatState(
          id: '1',
          name: 'test',
          level: 1,
          energy: 30,
          hunger: 30,
          affection: 60,
          experience: 10,
        );
        when(() => repository.playCat()).thenAnswer((_) async => updatedState);
        return cubit;
      },
      act: (c) async {
        await Future.delayed(Duration(milliseconds: 100));
        await c.playCat();
      },
      verify: (_) {
        verify(() => repository.playCat()).called(1);
      },
      expect: () => [
        isA<GameLoaded>(),
        isA<GameLoaded>().having((s) => s.catState.affection, 'affection', 60),
      ],
    );
  });

  group('TC_U004-U006: GameCubit 에러 처리', () {
    late GameCubit cubit;
    late MockGameRepository repository;

    setUp(() {
      repository = MockGameRepository();
      final mockState = CatState(
        id: '1',
        name: 'test',
        level: 1,
        energy: 5,
        hunger: 30,
        affection: 50,
        experience: 0,
      );
      when(() => repository.getCatState()).thenAnswer((_) async => mockState);
      cubit = GameCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    blocTest<GameCubit, GameStateSealed>(
      'TC_U004: feedCat INSUFFICIENT_ENERGY 시 GameError 전환',
      build: () {
        when(() => repository.feedCat()).thenThrow(
          InsufficientEnergyException('에너지 부족'),
        );
        return cubit;
      },
      act: (c) async {
        await Future.delayed(Duration(milliseconds: 100));
        await c.feedCat();
      },
      expect: () => [
        isA<GameLoaded>(),
        isA<GameError>().having(
          (s) => s.message,
          'message',
          contains('에너지'),
        ),
      ],
    );

    blocTest<GameCubit, GameStateSealed>(
      'TC_U005: feedCat NO_ITEM 시 GameError 전환',
      build: () {
        when(() => repository.feedCat()).thenThrow(
          NoItemException('아이템 부족'),
        );
        return cubit;
      },
      act: (c) async {
        await Future.delayed(Duration(milliseconds: 100));
        await c.feedCat();
      },
      expect: () => [
        isA<GameLoaded>(),
        isA<GameError>().having(
          (s) => s.message,
          'message',
          contains('아이템'),
        ),
      ],
    );

    blocTest<GameCubit, GameStateSealed>(
      'TC_U006: playCat INSUFFICIENT_ENERGY 시 GameError 전환',
      build: () {
        when(() => repository.playCat()).thenThrow(
          InsufficientEnergyException('에너지 부족'),
        );
        return cubit;
      },
      act: (c) async {
        await Future.delayed(Duration(milliseconds: 100));
        await c.playCat();
      },
      expect: () => [
        isA<GameLoaded>(),
        isA<GameError>().having(
          (s) => s.message,
          'message',
          contains('에너지'),
        ),
      ],
    );
  });

  group('TC_U007-U009: OfflineProgressCalculator', () {
    late OfflineProgressCalculator calculator;

    setUp(() {
      calculator = OfflineProgressCalculator();
    });

    test('TC_U007: 5분 오프라인 시 보상 계산', () {
      final lastAccessTime = DateTime.now().subtract(Duration(minutes: 5));
      final rewards = calculator.calculate(lastAccessTime);

      expect(rewards, isA<OfflineRewards>());
      expect(rewards.energy, greaterThan(0));
      expect(rewards.affection, greaterThanOrEqualTo(0));
    });

    test('TC_U008: 0분 오프라인 시 보상 없음', () {
      final lastAccessTime = DateTime.now();
      final rewards = calculator.calculate(lastAccessTime);

      expect(rewards.energy, equals(0));
      expect(rewards.affection, equals(0));
      expect(rewards.experience, equals(0));
    });

    test('TC_U009: 24시간 오프라인 시 상한선 적용', () {
      final lastAccessTime = DateTime.now().subtract(Duration(hours: 24));
      final rewards = calculator.calculate(lastAccessTime);

      expect(rewards.energy, lessThanOrEqualTo(100));
      expect(rewards.affection, lessThanOrEqualTo(50));
    });
  });

  group('TC_U010-U011: CatTraits', () {
    test('TC_U010: cheeseTabi 특성 반환', () {
      final traits = CatTraits.forPersonality(CatPersonality.cheeseTabi);

      expect(traits.playfulness, inInclusiveRange(1, 5));
      expect(traits.affection, inInclusiveRange(1, 5));
      expect(traits.independence, inInclusiveRange(1, 5));
      expect(traits.curiosity, inInclusiveRange(1, 5));
      expect(traits.sleepiness, inInclusiveRange(1, 5));
      expect(traits.appetite, inInclusiveRange(1, 5));
      expect(traits.chattiness, inInclusiveRange(1, 5));
      expect(traits.grooming, inInclusiveRange(1, 5));
    });

    test('TC_U011: 전체 성격 유효성 검증', () {
      for (final personality in CatPersonality.values) {
        final traits = CatTraits.forPersonality(personality);

        expect(traits.playfulness, inInclusiveRange(1, 5));
        expect(traits.affection, inInclusiveRange(1, 5));
        expect(traits.independence, inInclusiveRange(1, 5));
        expect(traits.curiosity, inInclusiveRange(1, 5));
        expect(traits.sleepiness, inInclusiveRange(1, 5));
        expect(traits.appetite, inInclusiveRange(1, 5));
        expect(traits.chattiness, inInclusiveRange(1, 5));
        expect(traits.grooming, inInclusiveRange(1, 5));
      }
    });
  });

  group('TC_U012: DialogueCubit', () {
    late DialogueCubit cubit;
    late MockDialogueRepository repository;

    setUp(() {
      repository = MockDialogueRepository();
      when(() => repository.getDialogue()).thenAnswer(
        (_) async => ['안녕하세요', '만나서 반가워요'],
      );
      cubit = DialogueCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    blocTest<DialogueCubit, DialogueState>(
      'TC_U012: startDialogue 시 초기 메시지 로드',
      build: () => cubit,
      act: (c) => c.startDialogue(),
      verify: (_) {
        verify(() => repository.getDialogue()).called(1);
      },
      expect: () => [
        isA<DialogueLoaded>().having(
          (s) => s.messages.length,
          'messages length',
          equals(2),
        ),
      ],
    );
  });
}

class InsufficientEnergyException implements Exception {
  final String message;
  InsufficientEnergyException(this.message);
}

class NoItemException implements Exception {
  final String message;
  NoItemException(this.message);
}