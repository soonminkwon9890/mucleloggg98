import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/selection_provider.dart';
import 'tabs/exercise_library_tab.dart';
import 'tabs/routine_management_tab.dart';

/// 관리 페이지 (운동 보관함 및 루틴 관리)
class ManagementScreen extends ConsumerStatefulWidget {
  /// [Phase 1] 진입 경로에 따른 모드 설정
  /// - true: Selection Mode (Path A: "+ 운동 추가하기" → "내 보관함에서 불러오기")
  /// - false: Management Mode (Path B: "보관함" 버튼)
  final bool isSelectionMode;

  const ManagementScreen({
    super.key,
    required this.isSelectionMode,
  });

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize selection provider with entry mode
    // Using addPostFrameCallback to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectionProvider.notifier).initialize(
            isSelectionMode: widget.isSelectionMode,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '운동 보관함'),
            Tab(text: '나만의 루틴'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ExerciseLibraryTab(),
          RoutineManagementTab(),
        ],
      ),
    );
  }
}
