import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat_state.freezed.dart';

@freezed
class CatState with _$CatState {
  const factory CatState({
    required int hunger,
    required int happiness,
    required int affection,
    required DateTime? lastFedTime,
  }) = _CatState;

  factory CatState.initial() => CatState(
        hunger: 50,
        happiness: 50,
        affection: 0,
        lastFedTime: null,
      );

  const CatState._();

  CatState copyWith({
    int? hunger,
    int? happiness,
    int? affection,
    DateTime? lastFedTime,
  }) {
    return CatState(
      hunger: hunger ?? this.hunger,
      happiness: happiness ?? this.happiness,
      affection: affection ?? this.affection,
      lastFedTime: lastFedTime ?? this.lastFedTime,
    );
  }
}
