import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selection state for management screen (exercise library + routines)
class SelectionState {
  final bool isSelectionMode;
  final Set<String> selectedBaselineIds;
  final Set<String> selectedRoutineIds;

  const SelectionState({
    required this.isSelectionMode,
    required this.selectedBaselineIds,
    required this.selectedRoutineIds,
  });

  /// Initial state factory
  factory SelectionState.initial({required bool isSelectionMode}) {
    return SelectionState(
      isSelectionMode: isSelectionMode,
      selectedBaselineIds: const {},
      selectedRoutineIds: const {},
    );
  }

  SelectionState copyWith({
    bool? isSelectionMode,
    Set<String>? selectedBaselineIds,
    Set<String>? selectedRoutineIds,
  }) {
    return SelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedBaselineIds: selectedBaselineIds ?? this.selectedBaselineIds,
      selectedRoutineIds: selectedRoutineIds ?? this.selectedRoutineIds,
    );
  }

  /// Check if any exercises are selected
  bool get hasSelectedBaselines => selectedBaselineIds.isNotEmpty;

  /// Check if any routines are selected
  bool get hasSelectedRoutines => selectedRoutineIds.isNotEmpty;

  /// Check if a specific baseline is selected
  bool isBaselineSelected(String id) => selectedBaselineIds.contains(id);

  /// Check if a specific routine is selected
  bool isRoutineSelected(String id) => selectedRoutineIds.contains(id);
}

/// Notifier for managing selection state
class SelectionNotifier extends Notifier<SelectionState> {
  @override
  SelectionState build() {
    // Default to non-selection mode; will be initialized by ManagementScreen
    return SelectionState.initial(isSelectionMode: false);
  }

  /// Initialize with the entry mode (called when ManagementScreen mounts)
  void initialize({required bool isSelectionMode}) {
    state = SelectionState.initial(isSelectionMode: isSelectionMode);
  }

  /// Toggle exercise baseline selection
  void toggleBaselineSelection(String baselineId) {
    final newSet = Set<String>.from(state.selectedBaselineIds);
    if (newSet.contains(baselineId)) {
      newSet.remove(baselineId);
    } else {
      newSet.add(baselineId);
    }
    state = state.copyWith(selectedBaselineIds: newSet);
  }

  /// Clear all baseline selections
  void clearBaselineSelection() {
    state = state.copyWith(selectedBaselineIds: const {});
  }

  /// Toggle routine selection
  void toggleRoutineSelection(String routineId) {
    final newSet = Set<String>.from(state.selectedRoutineIds);
    if (newSet.contains(routineId)) {
      newSet.remove(routineId);
    } else {
      newSet.add(routineId);
    }
    state = state.copyWith(selectedRoutineIds: newSet);
  }

  /// Clear all routine selections
  void clearRoutineSelection() {
    state = state.copyWith(selectedRoutineIds: const {});
  }

  /// Clear all selections (both baselines and routines)
  void clearAllSelections() {
    state = state.copyWith(
      selectedBaselineIds: const {},
      selectedRoutineIds: const {},
    );
  }
}

/// Provider for selection state
final selectionProvider =
    NotifierProvider<SelectionNotifier, SelectionState>(SelectionNotifier.new);
