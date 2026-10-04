import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'dart:math';

part 'home_state.dart';
part 'home_cubit.freezed.dart';

class HomeCubit extends Cubit<HomeState> {
  Timer? _behaviorTimer;
  final Random _random = Random();

  HomeCubit() : super(const HomeState.initial()) {
    _startBehaviorLoop();
  }

  void _startBehaviorLoop() {
    _behaviorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final behaviors = [
        CatBehaviorType.sitting,
        CatBehaviorType.sleeping,
        CatBehaviorType.walking,
        CatBehaviorType.eating,
        CatBehaviorType.drinking,
        CatBehaviorType.grooming,
        CatBehaviorType.playingWithFurniture,
        CatBehaviorType.lookingOutWindow,
      ];
      final newBehavior = behaviors[_random.nextInt(behaviors.length)];
      updateBehavior(newBehavior);
    });
  }

  void updateBehavior(CatBehaviorType behavior) {
    emit(HomeState.loaded(
      churuAmount: state.maybeMap(
        loaded: (s) => s.churuAmount,
        orElse: () => 150,
      ),
      goldenFishAmount: state.maybeMap(
        loaded: (s) => s.goldenFishAmount,
        orElse: () => 42,
      ),
      currentBehavior: behavior,
    ));
  }

  void consumeChuru(int amount) {
    state.maybeMap(
      loaded: (s) {
        final newAmount = (s.churuAmount - amount).clamp(0, 9999);
        emit(s.copyWith(churuAmount: newAmount));
      },
      orElse: () {},
    );
  }

  void addGoldenFish(int amount) {
    state.maybeMap(
      loaded: (s) {
        final newAmount = (s.goldenFishAmount + amount).clamp(0, 9999);
        emit(s.copyWith(goldenFishAmount: newAmount));
      },
      orElse: () {},
    );
  }

  void initialize() {
    emit(const HomeState.loaded(
      churuAmount: 150,
      goldenFishAmount: 42,
      currentBehavior: CatBehaviorType.sitting,
    ));
  }

  @override
  Future<void> close() {
    _behaviorTimer?.cancel();
    return super.close();
  }
}