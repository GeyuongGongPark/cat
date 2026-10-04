import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/cat_state.dart';

abstract class GameRepository {
  Future<GameState?> loadGameState();
  Future<void> saveGameState(GameState state);
  Future<CatState?> loadCatState();
  Future<void> saveCatState(CatState state);
}

class GameRepositoryImpl implements GameRepository {
  final Box gameBox;
  final Box catBox;

  const GameRepositoryImpl({
    required this.gameBox,
    required this.catBox,
  });

  @override
  Future<GameState?> loadGameState() async {
    final coins = gameBox.get('coins') as int?;
    final level = gameBox.get('level') as int?;
    final lastSaveTimeStr = gameBox.get('lastSaveTime') as String?;

    if (coins == null || level == null || lastSaveTimeStr == null) {
      return null;
    }

    return GameState(
      coins: coins,
      level: level,
      lastSaveTime: DateTime.parse(lastSaveTimeStr),
    );
  }

  @override
  Future<void> saveGameState(GameState state) async {
    await gameBox.put('coins', state.coins);
    await gameBox.put('level', state.level);
    await gameBox.put('lastSaveTime', state.lastSaveTime.toIso8601String());
  }

  @override
  Future<CatState?> loadCatState() async {
    final hunger = catBox.get('hunger') as int?;
    final happiness = catBox.get('happiness') as int?;
    final affection = catBox.get('affection') as int?;
    final lastFedTimeStr = catBox.get('lastFedTime') as String?;

    if (hunger == null || happiness == null || affection == null) {
      return null;
    }

    return CatState(
      hunger: hunger,
      happiness: happiness,
      affection: affection,
      lastFedTime: lastFedTimeStr != null ? DateTime.parse(lastFedTimeStr) : null,
    );
  }

  @override
  Future<void> saveCatState(CatState state) async {
    await catBox.put('hunger', state.hunger);
    await catBox.put('happiness', state.happiness);
    await catBox.put('affection', state.affection);
    if (state.lastFedTime != null) {
      await catBox.put('lastFedTime', state.lastFedTime!.toIso8601String());
    }
  }
}
