import 'package:freezed_annotation/freezed_annotation.dart';
import 'cat_personality.dart';

part 'cat_state.freezed.dart';

@freezed
class CatState with _$CatState {
  const factory CatState({
    required String name,
    required int affection,
    required int hunger,
    required int happiness,
    required int energy,
    required DateTime lastFedTime,
    required DateTime lastPlayedTime,
    required CatPersonality personality,
    required CatTraits traits,
    required WeatherPreference weatherPreference,
    required FirstMeeting firstMeeting,
  }) = _CatState;

  factory CatState.initial() {
    return CatState(
      name: '고양이',
      affection: 50,
      hunger: 50,
      happiness: 50,
      energy: 100,
      lastFedTime: DateTime.now().subtract(const Duration(hours: 2)),
      lastPlayedTime: DateTime.now().subtract(const Duration(hours: 1)),
      personality: CatPersonality.cheeseTabi,
      traits: CatTraits.forPersonality(CatPersonality.cheeseTabi),
      weatherPreference: WeatherPreference.forPersonality(CatPersonality.cheeseTabi),
      firstMeeting: FirstMeeting.forPersonality(CatPersonality.cheeseTabi),
    );
  }

  factory CatState.withPersonality(CatPersonality personality) {
    return CatState(
      name: _getDefaultName(personality),
      affection: 50,
      hunger: 50,
      happiness: 50,
      energy: 100,
      lastFedTime: DateTime.now().subtract(const Duration(hours: 2)),
      lastPlayedTime: DateTime.now().subtract(const Duration(hours: 1)),
      personality: personality,
      traits: CatTraits.forPersonality(personality),
      weatherPreference: WeatherPreference.forPersonality(personality),
      firstMeeting: FirstMeeting.forPersonality(personality),
    );
  }

  static String _getDefaultName(CatPersonality personality) {
    switch (personality) {
      case CatPersonality.cheeseTabi:
        return '치즈';
      case CatPersonality.mackerelTabi:
        return '고등어';
      case CatPersonality.calico:
        return '삼색';
      case CatPersonality.chaos:
        return '카오스';
      case CatPersonality.tuxedo:
        return '턱시';
      case CatPersonality.cow:
        return '젖소';
      case CatPersonality.allBlack:
        return '까망';
    }
  }
}

const _CatState = _$CatStateImpl;