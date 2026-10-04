import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/game/data/repositories/game_repository.dart';
import '../../features/game/domain/services/offline_progress_calculator.dart';
import '../../features/game/presentation/game_cubit.dart';

final getIt = GetIt.instance;

void setupDI() {
  // Services
  getIt.registerLazySingleton(() => const OfflineProgressCalculator());

  // Repositories
  getIt.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(
      gameBox: Hive.box('game_data'),
      catBox: Hive.box('cat_state'),
    ),
  );

  // Cubits
  getIt.registerFactory(
    () => GameCubit(
      getIt<GameRepository>(),
      getIt<OfflineProgressCalculator>(),
    ),
  );
}
