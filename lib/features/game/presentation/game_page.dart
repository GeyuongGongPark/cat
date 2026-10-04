import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_cubit.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cat Life Sim'),
        actions: [
          BlocBuilder<GameCubit, GameStateUI>(
            builder: (context, state) {
              return state.maybeWhen(
                loaded: (gameState, _, __) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${gameState.coins}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<GameCubit, GameStateUI>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('게임 준비 중...')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (gameState, catState, offlineRewards) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (offlineRewards != null && offlineRewards.coins > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(offlineRewards.message),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 고양이 표시 영역
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Center(
                        child: Text(
                          '🐱',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 상태 표시
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildStatRow('배고픔', catState.hunger, Icons.restaurant),
                            const SizedBox(height: 8),
                            _buildStatRow('행복도', catState.happiness, Icons.emoji_emotions),
                            const SizedBox(height: 8),
                            _buildStatRow('애정도', catState.affection, Icons.favorite),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 인터랙션 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: gameState.coins >= 10
                              ? () => context.read<GameCubit>().feedCat()
                              : null,
                          icon: const Icon(Icons.restaurant),
                          label: const Text('먹이 주기 (10코인)'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<GameCubit>().petCat(),
                          icon: const Icon(Icons.pets),
                          label: const Text('쓰다듬기'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('오류 발생: $message'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          '$value / 100',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
