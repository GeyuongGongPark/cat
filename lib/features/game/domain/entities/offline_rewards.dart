class OfflineRewards {
  final int coins;
  final Duration duration;
  final String message;

  const OfflineRewards({
    required this.coins,
    required this.duration,
    required this.message,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineRewards &&
        other.coins == coins &&
        other.duration == duration &&
        other.message == message;
  }

  @override
  int get hashCode => coins.hashCode ^ duration.hashCode ^ message.hashCode;
}
