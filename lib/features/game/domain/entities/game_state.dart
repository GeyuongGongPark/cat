import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    required int coins,
    required int level,
    required DateTime lastSaveTime,
  }) = _GameState;

  factory GameState.initial() => GameState(
        coins: 100,
        level: 1,
        lastSaveTime: DateTime.now(),
      );

  const GameState._();

  GameState copyWith({
    int? coins,
    int? level,
    DateTime? lastSaveTime,
  }) {
    return GameState(
      coins: coins ?? this.coins,
      level: level ?? this.level,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
    );
  }
}
