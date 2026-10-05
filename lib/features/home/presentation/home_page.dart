import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math';
import 'home_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  CatBehavior _currentBehavior = CatBehavior.sitting;
  Timer? _behaviorTimer;
  Offset _catPosition = const Offset(150, 200);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startBehaviorLoop();
  }

  @override
  void dispose() {
    _behaviorTimer?.cancel();
    super.dispose();
  }

  void _startBehaviorLoop() {
    _behaviorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        _currentBehavior = CatBehavior.values[_random.nextInt(CatBehavior.values.length)];
        if (_currentBehavior == CatBehavior.walking) {
          _catPosition = Offset(
            _random.nextDouble() * 250,
            _random.nextDouble() * 300 + 100,
          );
        }
      });
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: SafeArea(
        child: Column(
          children: [
            const _ResourceBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildRoom(),
                  AnimatedPositioned(
                    duration: const Duration(seconds: 2),
                    left: _catPosition.dx,
                    top: _catPosition.dy,
                    child: _CatWidget(behavior: _currentBehavior),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 80,
                    child: _WalkButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('산책 기능 준비 중')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: '고양이'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: '기억'),
        ],
      ),
    );
  }

  Widget _buildRoom() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8D4B8),
            Color(0xFFD4C4A8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 50,
            child: _buildWindow(),
          ),
          Positioned(
            right: 30,
            top: 200,
            child: _buildFurniture('🛋️'),
          ),
          Positioned(
            left: 30,
            bottom: 100,
            child: _buildFurniture('🍽️'),
          ),
          Positioned(
            right: 50,
            bottom: 150,
            child: _buildFurniture('💧'),
          ),
        ],
      ),
    );
  }

  Widget _buildWindow() {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        border: Border.all(color: const Color(0xFF8B4513), width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text('☁️', style: TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildFurniture(String emoji) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const _ResourceItem(icon: '🥣', amount: 150),
              const SizedBox(width: 16),
              const _ResourceItem(icon: '🐟', amount: 42),
            ],
          ),
          Text(
            _getCurrentTime(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _ResourceItem extends StatelessWidget {
  final String icon;
  final int amount;

  const _ResourceItem({required this.icon, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            amount.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatWidget extends StatelessWidget {
  final CatBehavior behavior;

  const _CatWidget({required this.behavior});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(behavior),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getCatEmoji(),
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getBehaviorText(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B4513),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCatEmoji() {
    return switch (behavior) {
      CatBehavior.sitting => '🐱',
      CatBehavior.sleeping => '😴',
      CatBehavior.walking => '🐈',
      CatBehavior.eating => '😋',
      CatBehavior.drinking => '🥛',
      CatBehavior.grooming => '🧼',
      CatBehavior.playingWithFurniture => '🎾',
      CatBehavior.lookingOutWindow => '👀',
    };
  }

  String _getBehaviorText() {
    return switch (behavior) {
      CatBehavior.sitting => '앉아있어요',
      CatBehavior.sleeping => '잠자는 중',
      CatBehavior.walking => '걷는 중',
      CatBehavior.eating => '밥 먹는 중',
      CatBehavior.drinking => '물 마시는 중',
      CatBehavior.grooming => '그루밍 중',
      CatBehavior.playingWithFurniture => '가구로 놀고 있어요',
      CatBehavior.lookingOutWindow => '창밖을 봐요',
    };
  }
}

class _WalkButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _WalkButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF8B4513),
      icon: const Text('🐾', style: TextStyle(fontSize: 24)),
      label: const Text(
        '산책',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum CatBehavior {
  sitting,
  sleeping,
  walking,
  eating,
  drinking,
  grooming,
  playingWithFurniture,
  lookingOutWindow,
}