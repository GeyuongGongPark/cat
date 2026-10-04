part of 'home_cubit.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loaded({
    required int churuAmount,
    required int goldenFishAmount,
    required CatBehaviorType currentBehavior,
  }) = _Loaded;
}

enum CatBehaviorType {
  sitting,
  sleeping,
  walking,
  eating,
  drinking,
  grooming,
  playingWithFurniture,
  lookingOutWindow,
}