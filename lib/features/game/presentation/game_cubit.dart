import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/cat_state.dart';
import '../domain/entities/game_state.dart';
import '../data/repositories/game_repository.dart';
import '../domain/services/offline_progress_calculator.dart';

part 'game_state_sealed.dart';
part 'game_cubit.freezed.dart';

class GameCubit extends Cubit<GameStateUI> {
  final GameRepository _repository;
  final OfflineProgressCalculator _calculator;

  GameCubit(this._repository, this._calculator)
      : super(const GameStateUI.initial());

  Future<void> initializeGame() async {
    emit(const GameStateUI.loading());
    try {
      final savedState = await _repository.loadGameState();
      final catState = await _repository.loadCatState();

      if (savedState != null && catState != null) {
        final offlineRewards = _calculator.calculateOfflineProgress(
          lastSaveTime: savedState.lastSaveTime,
          currentTime: DateTime.now(),
          baseRewardRate: 10.0,
        );

        final updatedState = savedState.copyWith(
          coins: savedState.coins + offlineRewards.coins,
          lastSaveTime: DateTime.now(),
        );

        await _repository.saveGameState(updatedState);

        emit(GameStateUI.loaded(
          gameState: updatedState,
          catState: catState,
          offlineRewards: offlineRewards,
        ));
      } else {
        final newGameState = GameState.initial();
        final newCatState = CatState.initial();

        await _repository.saveGameState(newGameState);
        await _repository.saveCatState(newCatState);

        emit(GameStateUI.loaded(
          gameState: newGameState,
          catState: newCatState,
          offlineRewards: null,
        ));
      }
    } catch (e) {
      emit(GameStateUI.error(e.toString()));
    }
  }

  Future<void> feedCat() async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    // 코인 부족 시 조기 반환
    if (currentState.gameState.coins < 10) return;

    final updatedCat = currentState.catState.copyWith(
      hunger: (currentState.catState.hunger + 20).clamp(0, 100),
      happiness: (currentState.catState.happiness + 5).clamp(0, 100),
      lastFedTime: DateTime.now(),
    );

    final updatedGame = currentState.gameState.copyWith(
      coins: currentState.gameState.coins - 10,
      lastSaveTime: DateTime.now(),
    );

    await _repository.saveCatState(updatedCat);
    await _repository.saveGameState(updatedGame);

    emit(currentState.copyWith(
      catState: updatedCat,
      gameState: updatedGame,
    ));
  }

  Future<void> petCat() async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    final updatedCat = currentState.catState.copyWith(
      happiness: (currentState.catState.happiness + 15).clamp(0, 100),
      affection: (currentState.catState.affection + 5).clamp(0, 100),
    );

    await _repository.saveCatState(updatedCat);

    emit(currentState.copyWith(catState: updatedCat));
  }
}
