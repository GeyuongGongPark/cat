enum CatPersonality {
  cheeseTabi,
  mackerelTabi,
  calico,
  chaos,
  tuxedo,
  cow,
  allBlack,
}

class CatTraits {
  final int humanFriendliness;
  final int affectionExpression;
  final int curiosity;
  final int activeness;
  final int independence;
  final int waterAffinity;
  final int sunlightPreference;
  final int rainDislike;

  const CatTraits({
    required this.humanFriendliness,
    required this.affectionExpression,
    required this.curiosity,
    required this.activeness,
    required this.independence,
    required this.waterAffinity,
    required this.sunlightPreference,
    required this.rainDislike,
  });

  factory CatTraits.forPersonality(CatPersonality personality) {
    switch (personality) {
      case CatPersonality.cheeseTabi:
        return const CatTraits(
          humanFriendliness: 5,
          affectionExpression: 5,
          curiosity: 4,
          activeness: 4,
          independence: 2,
          waterAffinity: 2,
          sunlightPreference: 5,
          rainDislike: 4,
        );
      case CatPersonality.mackerelTabi:
        return const CatTraits(
          humanFriendliness: 3,
          affectionExpression: 3,
          curiosity: 5,
          activeness: 5,
          independence: 4,
          waterAffinity: 3,
          sunlightPreference: 4,
          rainDislike: 3,
        );
      case CatPersonality.calico:
        return const CatTraits(
          humanFriendliness: 4,
          affectionExpression: 5,
          curiosity: 3,
          activeness: 3,
          independence: 3,
          waterAffinity: 1,
          sunlightPreference: 5,
          rainDislike: 5,
        );
      case CatPersonality.chaos:
        return const CatTraits(
          humanFriendliness: 2,
          affectionExpression: 2,
          curiosity: 5,
          activeness: 5,
          independence: 5,
          waterAffinity: 4,
          sunlightPreference: 3,
          rainDislike: 2,
        );
      case CatPersonality.tuxedo:
        return const CatTraits(
          humanFriendliness: 4,
          affectionExpression: 4,
          curiosity: 4,
          activeness: 4,
          independence: 3,
          waterAffinity: 3,
          sunlightPreference: 4,
          rainDislike: 3,
        );
      case CatPersonality.cow:
        return const CatTraits(
          humanFriendliness: 3,
          affectionExpression: 3,
          curiosity: 3,
          activeness: 2,
          independence: 4,
          waterAffinity: 2,
          sunlightPreference: 3,
          rainDislike: 4,
        );
      case CatPersonality.allBlack:
        return const CatTraits(
          humanFriendliness: 5,
          affectionExpression: 4,
          curiosity: 3,
          activeness: 3,
          independence: 2,
          waterAffinity: 2,
          sunlightPreference: 4,
          rainDislike: 4,
        );
    }
  }
}

class WeatherPreference {
  final String sunnyBehavior;
  final String rainyBehavior;

  const WeatherPreference({
    required this.sunnyBehavior,
    required this.rainyBehavior,
  });

  factory WeatherPreference.forPersonality(CatPersonality personality) {
    switch (personality) {
      case CatPersonality.cheeseTabi:
        return const WeatherPreference(
          sunnyBehavior: '햇살 가득한 창가에서 느긋하게 낮잠을 즐기며, 따뜻한 햇빛을 온몸으로 받아들입니다.',
          rainyBehavior: '빗소리에 불안해하며 주인 곁에 바짝 붙어 안정감을 찾으려 합니다.',
        );
      case CatPersonality.mackerelTabi:
        return const WeatherPreference(
          sunnyBehavior: '창밖 새와 벌레를 관찰하며 사냥 본능을 자극받아 활발하게 움직입니다.',
          rainyBehavior: '빗소리를 흥미롭게 듣지만, 젖는 것은 싫어해 실내에서 탐험을 계속합니다.',
        );
      case CatPersonality.calico:
        return const WeatherPreference(
          sunnyBehavior: '햇빛 아래에서 우아하게 그루밍하며 자신만의 여왕 시간을 보냅니다.',
          rainyBehavior: '비 오는 날을 극도로 싫어하며 가장 안전한 곳에 숨어 하루를 보냅니다.',
        );
      case CatPersonality.chaos:
        return const WeatherPreference(
          sunnyBehavior: '햇빛보다는 그늘진 곳을 찾아 비밀스러운 탐험을 이어갑니다.',
          rainyBehavior: '빗소리와 빗방울을 신기하게 관찰하며 오히려 더 활동적이 됩니다.',
        );
      case CatPersonality.tuxedo:
        return const WeatherPreference(
          sunnyBehavior: '적당한 햇빛 아래에서 균형잡힌 활동과 휴식을 반복합니다.',
          rainyBehavior: '비 오는 날도 평소와 비슷하게 행동하며 안정적인 루틴을 유지합니다.',
        );
      case CatPersonality.cow:
        return const WeatherPreference(
          sunnyBehavior: '햇빛이 너무 강하지 않은 시간에만 잠깐 나와 휴식을 취합니다.',
          rainyBehavior: '비 오는 날을 싫어하며 조용한 곳에서 혼자만의 시간을 보냅니다.',
        );
      case CatPersonality.allBlack:
        return const WeatherPreference(
          sunnyBehavior: '따뜻한 햇살을 사랑하며 주인 곁에서 함께 햇빛을 즐깁니다.',
          rainyBehavior: '빗소리에 불안해하며 주인의 무릎이나 품 안에서 안정을 찾습니다.',
        );
    }
  }
}

class FirstMeeting {
  final String signatureStory;
  final String memoryTitle;

  const FirstMeeting({
    required this.signatureStory,
    required this.memoryTitle,
  });

  factory FirstMeeting.forPersonality(CatPersonality personality) {
    switch (personality) {
      case CatPersonality.cheeseTabi:
        return const FirstMeeting(
          signatureStory: '공원 벤치 아래에서 떨고 있던 작은 치즈태비. 당신이 다가가자 조심스럽게 다가와 당신의 손을 핥았습니다. 그 순간, 서로의 눈을 마주치며 특별한 인연이 시작되었습니다.',
          memoryTitle: '벤치 아래의 따뜻한 만남',
        );
      case CatPersonality.mackerelTabi:
        return const FirstMeeting(
          signatureStory: '골목길을 탐험하던 고등어태비가 휙 지나가다 멈춰 섰습니다. 호기심 가득한 눈으로 당신을 관찰하더니, 갑자기 당신의 신발끈을 가지고 놀기 시작했습니다. 그렇게 첫 만남은 놀이로 시작되었습니다.',
          memoryTitle: '골목길의 장난꾸러기',
        );
      case CatPersonality.calico:
        return const FirstMeeting(
          signatureStory: '정원 담장 위에서 우아하게 앉아있던 삼색이. 당신을 발견하고도 도도하게 외면하다가, 당신이 간식을 꺼내자 천천히 다가와 품위있게 받아먹었습니다. 그날부터 당신은 그녀의 신하가 되었습니다.',
          memoryTitle: '담장 위의 여왕님',
        );
      case CatPersonality.chaos:
        return const FirstMeeting(
          signatureStory: '빗속을 뛰어다니던 카오스 고양이를 우연히 발견했습니다. 다른 고양이들과 달리 비를 즐기는 듯 보였죠. 당신이 우산을 씌워주려 하자 오히려 도망갔다가, 다음 날 당신 집 창문 앞에 나타났습니다.',
          memoryTitle: '빗속의 자유로운 영혼',
        );
      case CatPersonality.tuxedo:
        return const FirstMeeting(
          signatureStory: '동네 카페 앞에서 신사처럼 앉아있던 턱시도 고양이. 당신이 다가가자 정중하게 인사하듯 꼬리를 흔들었습니다. 마치 오래 기다린 친구를 만난 것처럼 자연스럽게 당신을 따라왔습니다.',
          memoryTitle: '카페 앞의 신사',
        );
      case CatPersonality.cow:
        return const FirstMeeting(
          signatureStory: '골목 구석 박스 안에서 조용히 쉬고 있던 젖소 고양이. 당신이 발견했을 때도 침착하게 당신을 바라보기만 했습니다. 며칠간 같은 자리에서 만나다가 어느 날, 스스로 당신을 따라왔습니다.',
          memoryTitle: '박스 안의 조용한 만남',
        );
      case CatPersonality.allBlack:
        return const FirstMeeting(
          signatureStory: '비 오는 밤, 현관 앞에서 떨고 있던 새까만 고양이. 당신이 문을 열자 주저없이 안으로 들어와 당신 발 옆에 바짝 붙었습니다. 그날 밤 내내 당신 곁을 지키며 안정을 찾았습니다.',
          memoryTitle: '빗속의 검은 천사',
        );
    }
  }
}