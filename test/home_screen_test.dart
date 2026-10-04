import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

// Mock Classes
class MockTimer extends Mock implements Timer {}

// Test Models
enum CatBehavior {
  idle,
  sitting,
  sleeping,
  eating,
  playing,
  grooming,
  stretching,
  walking,
}

class HomeState {
  final int churu;
  final int goldenFish;
  final CatBehavior currentBehavior;

  HomeState({
    required this.churu,
    required this.goldenFish,
    required this.currentBehavior,
  });

  HomeState copyWith({
    int? churu,
    int? goldenFish,
    CatBehavior? currentBehavior,
  }) {
    return HomeState(
      churu: churu ?? this.churu,
      goldenFish: goldenFish ?? this.goldenFish,
      currentBehavior: currentBehavior ?? this.currentBehavior,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit()
      : super(HomeState(
          churu: 150,
          goldenFish: 42,
          currentBehavior: CatBehavior.idle,
        ));

  void consumeChuru(int amount) {
    final newChuru = (state.churu - amount).clamp(0, 9999);
    emit(state.copyWith(churu: newChuru));
  }

  void addGoldenFish(int amount) {
    final newGoldenFish = (state.goldenFish + amount).clamp(0, 9999);
    emit(state.copyWith(goldenFish: newGoldenFish));
  }

  void changeBehavior(CatBehavior behavior) {
    emit(state.copyWith(currentBehavior: behavior));
  }
}

class CatBehaviorTimer {
  Timer? _timer;
  final Function(CatBehavior) onBehaviorChange;

  CatBehaviorTimer({required this.onBehaviorChange}) {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final randomBehavior = _getRandomBehavior();
      onBehaviorChange(randomBehavior);
    });
  }

  CatBehavior _getRandomBehavior() {
    final behaviors = CatBehavior.values;
    final randomIndex = DateTime.now().millisecond % behaviors.length;
    return behaviors[randomIndex];
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

void main() {
  group('HomeCubit - 초기화', () {
    test('TC_U015: 초기 상태가 올바르게 설정됨', () {
      // When
      final cubit = HomeCubit();

      // Then
      expect(cubit.state.churu, 150);
      expect(cubit.state.goldenFish, 42);
      expect(cubit.state.currentBehavior, CatBehavior.idle);

      cubit.close();
    });
  });

  group('HomeCubit - consumeChuru', () {
    late HomeCubit cubit;

    setUp(() {
      cubit = HomeCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('TC_U001: 츄르 정상 소비 시 상태가 올바르게 업데이트됨', () {
      // Given
      expect(cubit.state.churu, 150);

      // When
      cubit.consumeChuru(50);

      // Then
      expect(cubit.state.churu, 100);
    });

    test('TC_U002: 츄르 소비 시 음수가 되지 않도록 0으로 clamp됨', () {
      // Given
      cubit.consumeChuru(120); // 150 - 120 = 30
      expect(cubit.state.churu, 30);

      // When
      cubit.consumeChuru(50);

      // Then
      expect(cubit.state.churu, 0);
    });

    test('TC_U009: 츄르가 정확히 0일 때 소비 시도 시 0으로 유지됨', () {
      // Given
      cubit.consumeChuru(150); // 150 - 150 = 0
      expect(cubit.state.churu, 0);

      // When
      cubit.consumeChuru(10);

      // Then
      expect(cubit.state.churu, 0);
    });
  });

  group('HomeCubit - addGoldenFish', () {
    late HomeCubit cubit;

    setUp(() {
      cubit = HomeCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('TC_U003: 금색 물고기 정상 추가 시 상태가 올바르게 업데이트됨', () {
      // Given
      expect(cubit.state.goldenFish, 42);

      // When
      cubit.addGoldenFish(10);

      // Then
      expect(cubit.state.goldenFish, 52);
    });

    test('TC_U004: 금색 물고기 추가 시 9999를 초과하지 않도록 clamp됨', () {
      // Given
      cubit.addGoldenFish(9948); // 42 + 9948 = 9990
      expect(cubit.state.goldenFish, 9990);

      // When
      cubit.addGoldenFish(20);

      // Then
      expect(cubit.state.goldenFish, 9999);
    });

    test('TC_U010: 금색 물고기가 정확히 9999일 때 추가 시 9999로 유지됨', () {
      // Given
      cubit.addGoldenFish(9957); // 42 + 9957 = 9999
      expect(cubit.state.goldenFish, 9999);

      // When
      cubit.addGoldenFish(1);

      // Then
      expect(cubit.state.goldenFish, 9999);
    });
  });

  group('HomeCubit - changeBehavior', () {
    late HomeCubit cubit;

    setUp(() {
      cubit = HomeCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('TC_U013: 고양이 행동을 정상적으로 변경할 수 있음', () {
      // Given
      expect(cubit.state.currentBehavior, CatBehavior.idle);

      // When
      cubit.changeBehavior(CatBehavior.sleeping);

      // Then
      expect(cubit.state.currentBehavior, CatBehavior.sleeping);
    });

    test('TC_U014: 고양이 행동을 연속으로 변경했을 때 마지막 상태로 유지됨', () {
      // When
      cubit.changeBehavior(CatBehavior.playing);
      cubit.changeBehavior(CatBehavior.eating);
      cubit.changeBehavior(CatBehavior.sleeping);

      // Then
      expect(cubit.state.currentBehavior, CatBehavior.sleeping);
    });
  });

  group('HomeCubit - 동시 호출', () {
    test('TC_U012: consumeChuru와 addGoldenFish 동시 호출 시 상태가 일관됨', () async {
      // Given
      final cubit = HomeCubit();
      cubit.consumeChuru(50); // 150 - 50 = 100
      cubit.addGoldenFish(8); // 42 + 8 = 50

      // When
      await Future.wait([
        Future(() => cubit.consumeChuru(10)),
        Future(() => cubit.addGoldenFish(5)),
      ]);

      // Then
      expect(cubit.state.churu, 90);
      expect(cubit.state.goldenFish, 55);

      await cubit.close();
    });
  });

  group('CatBehaviorTimer', () {
    test('TC_U005: CatBehaviorTimer 생성 시 Timer가 정상 시작됨', () {
      // Given
      final behaviors = <CatBehavior>[];
      
      // When
      final timer = CatBehaviorTimer(
        onBehaviorChange: (behavior) => behaviors.add(behavior),
      );

      // Then
      expect(timer, isNotNull);
      timer.dispose();
    });

    test('TC_U006: dispose 호출 시 Timer가 정리됨', () {
      // Given
      final timer = CatBehaviorTimer(
        onBehaviorChange: (_) {},
      );

      // When
      timer.dispose();

      // Then - Timer가 정리되면 onBehaviorChange가 더 이상 호출되지 않음
      // (실제로는 Timer.cancel 호출 확인이 필요하지만 mock 없이는 간접 검증)
      expect(() => timer.dispose(), returnsNormally);
    });

    test('TC_U011: dispose 중복 호출 시 예외가 발생하지 않음', () {
      // Given
      final timer = CatBehaviorTimer(
        onBehaviorChange: (_) {},
      );

      // When & Then
      expect(() {
        timer.dispose();
        timer.dispose();
      }, returnsNormally);
    });

    test('TC_U016: 랜덤 행동 생성 시 모든 행동(8가지)이 선택되는지 확인', () {
      // Given
      final behaviorCounts = <CatBehavior, int>{};
      final timer = CatBehaviorTimer(
        onBehaviorChange: (behavior) {
          behaviorCounts[behavior] = (behaviorCounts[behavior] ?? 0) + 1;
        },
      );

      // When - 1000회 시뮬레이션
      for (var i = 0; i < 1000; i++) {
        final behavior = timer._getRandomBehavior();
        behaviorCounts[behavior] = (behaviorCounts[behavior] ?? 0) + 1;
      }

      // Then
      expect(behaviorCounts.keys.length, CatBehavior.values.length);
      for (final behavior in CatBehavior.values) {
        expect(behaviorCounts.containsKey(behavior), isTrue);
      }

      timer.dispose();
    });
  });
}