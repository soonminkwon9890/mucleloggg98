import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'workout_log_screen.dart';
import '../../providers/workout_provider.dart';
import '../profile/my_page_screen.dart';
import '../planner/weekly_routine_planner_screen.dart';

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
    const WeeklyRoutinePlannerScreen(selectedBaselineIds: {}),
    const MyPageScreen(),
  ];

  final List<String> _appBarTitles = [
    'MuscleLog',
    '운동 기록',
    'AI 루틴',
    '내 정보',
  ];

  /// 홈 탭 복귀 시 날짜 롤오버 체크.
  /// 날짜가 바뀌었으면 selectedHomeDateProvider를 오늘로 리셋하여
  /// 캘린더가 구날짜를 가리킨 채 빈 목록을 보이는 좀비 템플릿 버그 차단.
  Future<void> _checkDateOnHomeTabSwitch() async {
    final dateChanged =
        await ref.read(homeViewModelProvider.notifier).checkDateAndRefresh();
    if (dateChanged && mounted) {
      final today = DateTime.now();
      ref.read(selectedHomeDateProvider.notifier).state =
          DateTime(today.year, today.month, today.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 운동 기록(1), AI 루틴(2), 내 정보(3) 탭은 자체 Scaffold/AppBar를 가지므로
      // MainScreen AppBar를 숨겨 타이틀 중복을 방지한다.
      appBar: (_currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3)
          ? null
          : AppBar(
              title: Text(_appBarTitles[_currentIndex]),
            ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // 홈 탭(인덱스 0) 클릭 시: Draft 보존을 위해 invalidate 제거
          // 날짜 변경 체크만 수행하여 필요시에만 새로고침 (Draft 유지)
          if (index == 0) {
            _checkDateOnHomeTabSwitch();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동 기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI 루틴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}

