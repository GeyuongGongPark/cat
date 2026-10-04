part of 'game_cubit.dart';

@freezed
class GameStateUI with _$GameStateUI {
  const factory GameStateUI.initial() = _Initial;
  const factory GameStateUI.loading() = _Loading;
  const factory GameStateUI.loaded({
    required GameState gameState,
    required CatState catState,
    OfflineRewards? offlineRewards,
  }) = _Loaded;
  const factory GameStateUI.error(String message) = _Error;
}
