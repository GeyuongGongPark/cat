import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'core/di/injection.dart';
import 'features/game/presentation/game_page.dart';
import 'features/game/presentation/game_cubit.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox('game_data');
  await Hive.openBox('cat_state');
  
  await Firebase.initializeApp();
  
  setupDI();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Life Sim',
      theme: AppTheme.lightTheme,
      home: BlocProvider(
        create: (_) => getIt<GameCubit>()..initializeGame(),
        child: const GamePage(),
      ),
    );
  }
}
