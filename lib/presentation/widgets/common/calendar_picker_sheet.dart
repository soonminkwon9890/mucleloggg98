import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/models/planned_workout.dart';
import 'bottom_sheet_container.dart';

/// 날짜 선택 캘린더 바텀시트 위젯
///
/// 운동 스케줄링 등에서 날짜를 선택할 때 사용합니다.
/// BottomSheetContainer와 TableCalendar를 통합하여 일관된 UI를 제공합니다.
///
/// 사용 예시:
/// ```dart
/// final selectedDate = await CalendarPickerSheet.show(
///   context: context,
///   headerTitle: '3개 운동 선택됨',
///   headerSubtitle: '운동할 날짜를 선택하세요',
///   confirmButtonBuilder: (date) => Text(_formatDateLabel(date)),
///   onPageChanged: (month) => loadPlannedWorkouts(month),
///   plannedWorkouts: plannedWorkoutsByDate,
/// );
/// ```
class CalendarPickerSheet extends StatefulWidget {
  final String headerTitle;
  final String headerSubtitle;
  final Map<DateTime, PlannedWorkout> plannedWorkouts;
  final Future<void> Function(DateTime month)? onPageChanged;
  final Widget Function(DateTime selectedDate) confirmButtonBuilder;
  final DateTime? initialFocusedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;

  const CalendarPickerSheet({
    super.key,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.confirmButtonBuilder,
    this.plannedWorkouts = const {},
    this.onPageChanged,
    this.initialFocusedDay,
    this.firstDay,
    this.lastDay,
  });

  /// 캘린더 바텀시트를 표시하고 선택된 날짜를 반환합니다.
  ///
  /// 사용자가 날짜를 선택하고 확인 버튼을 누르면 해당 날짜를 반환합니다.
  /// 취소하거나 외부를 탭하면 null을 반환합니다.
  static Future<DateTime?> show({
    required BuildContext context,
    required String headerTitle,
    required String headerSubtitle,
    required Widget Function(DateTime selectedDate) confirmButtonBuilder,
    Map<DateTime, PlannedWorkout> plannedWorkouts = const {},
    Future<void> Function(DateTime month)? onPageChanged,
    DateTime? initialFocusedDay,
    DateTime? firstDay,
    DateTime? lastDay,
  }) {
    return BottomSheetContainer.show<DateTime>(
      context: context,
      maxHeightRatio: 2 / 3,
      builder: (sheetContext) {
        return _CalendarPickerContent(
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle,
          confirmButtonBuilder: confirmButtonBuilder,
          plannedWorkouts: plannedWorkouts,
          onPageChanged: onPageChanged,
          initialFocusedDay: initialFocusedDay,
          firstDay: firstDay,
          lastDay: lastDay,
        );
      },
    );
  }

  @override
  State<CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<CalendarPickerSheet> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, PlannedWorkout> _plannedWorkouts;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
    _plannedWorkouts = Map.from(widget.plannedWorkouts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Divider(),
        Expanded(child: _buildCalendar(context)),
        if (_selectedDay != null) _buildConfirmButton(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.headerTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.headerSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return SingleChildScrollView(
      child: TableCalendar(
        firstDay: widget.firstDay ?? DateTime.now(),
        lastDay: widget.lastDay ?? DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) =>
            _selectedDay != null && isSameDay(_selectedDay!, day),
        locale: 'ko_KR',
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: (day) {
          final dayDate = DateTime(day.year, day.month, day.day);
          final plannedWorkout = _plannedWorkouts[dayDate];
          return plannedWorkout != null ? [plannedWorkout] : [];
        },
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) async {
          setState(() {
            _focusedDay = focused;
          });
          if (widget.onPageChanged != null) {
            await widget.onPageChanged!(focused);
            // Refresh to show updated planned workouts
            if (mounted) setState(() {});
          }
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final plannedWorkout = events.whereType<PlannedWorkout>().firstOrNull;
            if (plannedWorkout != null) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(int.parse(plannedWorkout.colorHex)),
                  shape: BoxShape.circle,
                ),
              );
            }
            return null;
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, _selectedDay),
            icon: const Icon(Icons.calendar_today),
            label: widget.confirmButtonBuilder(_selectedDay!),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}

/// CalendarPickerSheet의 내부 컨텐츠 위젯 (StatefulBuilder 대체)
class _CalendarPickerContent extends StatefulWidget {
  final String headerTitle;
  final String headerSubtitle;
  final Widget Function(DateTime selectedDate) confirmButtonBuilder;
  final Map<DateTime, PlannedWorkout> plannedWorkouts;
  final Future<void> Function(DateTime month)? onPageChanged;
  final DateTime? initialFocusedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;

  const _CalendarPickerContent({
    required this.headerTitle,
    required this.headerSubtitle,
    required this.confirmButtonBuilder,
    required this.plannedWorkouts,
    this.onPageChanged,
    this.initialFocusedDay,
    this.firstDay,
    this.lastDay,
  });

  @override
  State<_CalendarPickerContent> createState() => _CalendarPickerContentState();
}

class _CalendarPickerContentState extends State<_CalendarPickerContent> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, PlannedWorkout> _plannedWorkouts;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
    _plannedWorkouts = Map.from(widget.plannedWorkouts);
  }

  void updatePlannedWorkouts(Map<DateTime, PlannedWorkout> newWorkouts) {
    setState(() {
      _plannedWorkouts = Map.from(newWorkouts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Divider(),
        Expanded(child: _buildCalendar(context)),
        if (_selectedDay != null) _buildConfirmButton(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.headerTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.headerSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return SingleChildScrollView(
      child: TableCalendar(
        firstDay: widget.firstDay ?? DateTime.now(),
        lastDay: widget.lastDay ?? DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) =>
            _selectedDay != null && isSameDay(_selectedDay!, day),
        locale: 'ko_KR',
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: (day) {
          final dayDate = DateTime(day.year, day.month, day.day);
          final plannedWorkout = _plannedWorkouts[dayDate];
          return plannedWorkout != null ? [plannedWorkout] : [];
        },
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) async {
          setState(() {
            _focusedDay = focused;
          });
          if (widget.onPageChanged != null) {
            await widget.onPageChanged!(focused);
            if (mounted) setState(() {});
          }
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final plannedWorkout = events.whereType<PlannedWorkout>().firstOrNull;
            if (plannedWorkout != null) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(int.parse(plannedWorkout.colorHex)),
                  shape: BoxShape.circle,
                ),
              );
            }
            return null;
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, _selectedDay),
            icon: const Icon(Icons.calendar_today),
            label: widget.confirmButtonBuilder(_selectedDay!),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
