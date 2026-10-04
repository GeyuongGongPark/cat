import '../entities/offline_rewards.dart';

class OfflineProgressCalculator {
  const OfflineProgressCalculator();

  OfflineRewards calculateOfflineProgress({
    required DateTime lastSaveTime,
    required DateTime currentTime,
    required double baseRewardRate,
  }) {
    final offlineDuration = currentTime.difference(lastSaveTime);
    
    // 음수 시간 차이 방어 (시스템 시간 변경 등)
    if (offlineDuration.isNegative) {
      return OfflineRewards(
        coins: 0,
        duration: Duration.zero,
        message: '시간 오류가 감지되었습니다',
      );
    }

    final offlineHours = offlineDuration.inMinutes / 60.0;

    if (offlineHours < 0.0166) {
      return OfflineRewards(
        coins: 0,
        duration: offlineDuration,
        message: '오프라인 보상이 없습니다',
      );
    }

    final maxOfflineHours = 12.0;
    final effectiveHours = offlineHours > maxOfflineHours ? maxOfflineHours : offlineHours;

    final coinsEarned = (effectiveHours * baseRewardRate).round();

    final hoursText = effectiveHours < 1
        ? '${(effectiveHours * 60).round()}분'
        : '${effectiveHours.toStringAsFixed(1)}시간';

    return OfflineRewards(
      coins: coinsEarned,
      duration: offlineDuration,
      message: '$hoursText 동안 $coinsEarned 코인을 획득했습니다!',
    );
  }

  Duration calculateNextRewardTime(DateTime lastRewardTime) {
    final nextReward = lastRewardTime.add(const Duration(minutes: 1));
    final now = DateTime.now();

    if (now.isAfter(nextReward)) {
      return Duration.zero;
    }

    return nextReward.difference(now);
  }

  int calculateIdleCoinsPerHour(int level) {
    return (10 * (1 + level * 0.1)).round();
  }
}
