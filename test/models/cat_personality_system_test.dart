import 'package:test/test.dart';
import 'package:cat/models/cat_personality.dart';
import 'package:cat/models/cat_traits.dart';
import 'package:cat/models/weather_preference.dart';
import 'package:cat/models/first_meeting.dart';
import 'package:cat/features/game/domain/entities/cat_state.dart';

void main() {
  group('CatTraits.forPersonality()', () {
    test('TC_U001: TSUNDERE 성격의 정확한 수치 반환', () {
      final traits = CatTraits.forPersonality(CatPersonality.TSUNDERE);
      expect(traits.affection, equals(0.3));
      expect(traits.energy, equals(0.6));
      expect(traits.playfulness, equals(0.4));
    });

    test('TC_U002: GRUMPY 성격의 정확한 수치 반환 (최소 affection)', () {
      final traits = CatTraits.forPersonality(CatPersonality.GRUMPY);
      expect(traits.affection, equals(0.1));
      expect(traits.energy, equals(0.5));
      expect(traits.playfulness, equals(0.2));
    });

    test('TC_U010: 모든 성격의 traits 수치가 0.0~1.0 범위 내', () {
      for (final personality in CatPersonality.values) {
        final traits = CatTraits.forPersonality(personality);
        expect(traits.affection, greaterThanOrEqualTo(0.0),
            reason: '$personality affection이 0.0 미만');
        expect(traits.affection, lessThanOrEqualTo(1.0),
            reason: '$personality affection이 1.0 초과');
        expect(traits.energy, greaterThanOrEqualTo(0.0),
            reason: '$personality energy가 0.0 미만');
        expect(traits.energy, lessThanOrEqualTo(1.0),
            reason: '$personality energy가 1.0 초과');
        expect(traits.playfulness, greaterThanOrEqualTo(0.0),
            reason: '$personality playfulness가 0.0 미만');
        expect(traits.playfulness, lessThanOrEqualTo(1.0),
            reason: '$personality playfulness가 1.0 초과');
      }
    });
  });

  group('WeatherPreference.forPersonality()', () {
    test('TC_U003: HYPERACTIVE 성격의 모든 날씨 필드 존재', () {
      final pref = WeatherPreference.forPersonality(CatPersonality.HYPERACTIVE);
      expect(pref.sunny, isNotNull);
      expect(pref.rainy, isNotNull);
      expect(pref.cloudy, isNotNull);
      expect(pref.snowy, isNotNull);
    });

    test('TC_U004: LAZY 성격의 날씨 텍스트가 최소 5자 이상', () {
      final pref = WeatherPreference.forPersonality(CatPersonality.LAZY);
      expect(pref.sunny.length, greaterThanOrEqualTo(5),
          reason: 'LAZY sunny 텍스트가 너무 짧음');
      expect(pref.rainy.length, greaterThanOrEqualTo(5),
          reason: 'LAZY rainy 텍스트가 너무 짧음');
      expect(pref.cloudy.length, greaterThanOrEqualTo(5),
          reason: 'LAZY cloudy 텍스트가 너무 짧음');
      expect(pref.snowy.length, greaterThanOrEqualTo(5),
          reason: 'LAZY snowy 텍스트가 너무 짧음');
    });

    test('TC_U011: TSUNDERE와 GRUMPY 성격의 날씨 텍스트 차별화', () {
      final pref1 = WeatherPreference.forPersonality(CatPersonality.TSUNDERE);
      final pref2 = WeatherPreference.forPersonality(CatPersonality.GRUMPY);
      expect(pref1.sunny, isNot(equals(pref2.sunny)),
          reason: 'TSUNDERE와 GRUMPY의 sunny 텍스트가 동일함');
      expect(pref1.rainy, isNot(equals(pref2.rainy)),
          reason: 'TSUNDERE와 GRUMPY의 rainy 텍스트가 동일함');
    });
  });

  group('FirstMeeting.forPersonality()', () {
    test('TC_U005: CURIOUS 성격의 스토리 필드가 최소 20자 이상', () {
      final meeting = FirstMeeting.forPersonality(CatPersonality.CURIOUS);
      expect(meeting.story, isNotNull);
      expect(meeting.story.isNotEmpty, isTrue);
      expect(meeting.story.length, greaterThanOrEqualTo(20),
          reason: 'CURIOUS 스토리가 너무 짧음');
    });

    test('TC_U006: SHY와 CLINGY 성격의 스토리 고유성', () {
      final meeting1 = FirstMeeting.forPersonality(CatPersonality.SHY);
      final meeting2 = FirstMeeting.forPersonality(CatPersonality.CLINGY);
      expect(meeting1.story, isNot(equals(meeting2.story)),
          reason: 'SHY와 CLINGY의 스토리가 동일함');
    });
  });

  group('CatState.withPersonality()', () {
    test('TC_U007: CLINGY 성격으로 완전한 CatState 객체 생성', () {
      final state = CatState.withPersonality(CatPersonality.CLINGY);
      expect(state, isNotNull);
      expect(state.personality, equals(CatPersonality.CLINGY));
      expect(state.traits, isNotNull);
      expect(state.traits.affection, equals(0.95));
    });

    test('TC_U008: 7종 모든 성격에 대해 CatState 생성 성공', () {
      for (final personality in CatPersonality.values) {
        final state = CatState.withPersonality(personality);
        expect(state, isNotNull,
            reason: '$personality로 생성한 CatState가 null');
        expect(state.personality, equals(personality),
            reason: '$personality 성격이 일치하지 않음');
        expect(state.traits, isNotNull,
            reason: '$personality의 traits가 null');
      }
    });

    test('TC_U012: 동일 입력에 대해 일관된 출력 (멱등성)', () {
      final state1 = CatState.withPersonality(CatPersonality.HYPERACTIVE);
      final state2 = CatState.withPersonality(CatPersonality.HYPERACTIVE);
      expect(state1.personality, equals(state2.personality));
      expect(state1.traits.affection, equals(state2.traits.affection));
      expect(state1.traits.energy, equals(state2.traits.energy));
      expect(state1.traits.playfulness, equals(state2.traits.playfulness));
    });
  });

  group('CatState.initial() - 회귀 테스트', () {
    test('TC_U009: 기존 기본값 유지 검증', () {
      final state = CatState.initial();
      expect(state, isNotNull);
      expect(state.hunger, equals(50));
      expect(state.happiness, equals(50));
      expect(state.affection, equals(0));
      expect(state.lastFedTime, isNull);
    });
  });
}
