import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'workout_log_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/workout_provider.dart';
import '../management/management_screen.dart';

/// 메인 화면 (3단 탭 구조)
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutLogScreen(),
    const ProfileScreen(),
  ];

  final List<String> _appBarTitles = [
    'MuscleLog',
    '운동 분석',
    '내 프로필',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex]),
        leading: _currentIndex == 2
            ? IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  ref.read(isProfileSearchOpenProvider.notifier).state = true;
                },
              )
            : null,
        // 홈 탭(Index 0)일 때만 설정 버튼 표시
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManagementScreen(),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동 분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

