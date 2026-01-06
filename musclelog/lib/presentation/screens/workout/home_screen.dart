import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/history/accordion_list.dart';

/// 홈 화면 (운동 목록)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baselinesAsync = ref.watch(baselinesProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MuscleLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/exercise/add');
            },
            tooltip: '운동 추가',
          ),
        ],
      ),
      body: authStateAsync.when(
        data: (isAuthenticated) {
          if (!isAuthenticated) {
            return const Center(
              child: Text('로그인이 필요합니다'),
            );
          }

          return baselinesAsync.when(
            data: (baselines) {
              if (baselines.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '등록된 운동이 없습니다',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '운동 추가 버튼을 눌러 첫 운동을 등록하세요',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: baselines.length,
                itemBuilder: (context, index) {
                  final baseline = baselines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: AccordionList(baseline: baseline),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('오류: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('인증 오류: $error'),
        ),
      ),
    );
  }
}
