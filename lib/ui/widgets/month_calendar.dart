import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.today,
    required this.hasTransactions,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime today;
  final bool Function(DateTime date) hasTransactions;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  // A 300-year browsing range keeps date navigation effectively unbounded for
  // personal finance while avoiding an unbounded PageView allocation.
  static const _anchorPage = 1800;
  late final DateTime _baseMonth;
  late final PageController _pageController;
  late int _visiblePage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _visiblePage = _pageForMonth(widget.month);
    _pageController = PageController(initialPage: _visiblePage);
  }

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desiredPage = _pageForMonth(widget.month);
    if (desiredPage != _visiblePage) {
      _visiblePage = desiredPage;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          desiredPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  int _pageForMonth(DateTime month) =>
      _anchorPage + (month.year - _baseMonth.year) * 12 + month.month - _baseMonth.month;

  DateTime _monthAtPage(int page) =>
      DateTime(_baseMonth.year, _baseMonth.month + page - _anchorPage);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _WeekdayHeader(),
        const SizedBox(height: 6),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            allowImplicitScrolling: true,
            itemCount: 3601,
            onPageChanged: (page) {
              _visiblePage = page;
              widget.onMonthChanged(_monthAtPage(page));
            },
            itemBuilder: (context, page) => _MonthGrid(
              month: _monthAtPage(page),
              selectedDate: widget.selectedDate,
              today: widget.today,
              hasTransactions: widget.hasTransactions,
              onDateSelected: widget.onDateSelected,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          'M', 'T', 'W', 'T', 'F', 'S', 'S',
        ]
            .map(
              (day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: AppPalette.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.today,
    required this.hasTransactions,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime today;
  final bool Function(DateTime) hasTransactions;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final leadingDays = month.weekday - 1;
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((leadingDays + dayCount) / 7).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final cellHeight = constraints.maxHeight / rows;
        final dateDiameter = math.max(
          29.0,
          math.min(40.0, math.min(cellWidth - 3, cellHeight - 7)),
        ).toDouble();
        final indicatorHeight =
            math.max(0.0, math.min(7.0, cellHeight - dateDiameter)).toDouble();
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: rows * 7,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: cellWidth / cellHeight,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingDays + 1;
            if (day < 1 || day > dayCount) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, day);
            return _DateCell(
              date: date,
              isSelected: _sameDay(date, selectedDate),
              isToday: _sameDay(date, today),
              hasTransactions: hasTransactions(date),
              dateDiameter: dateDiameter,
              indicatorHeight: indicatorHeight,
              onTap: () => onDateSelected(date),
            );
          },
        );
      },
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasTransactions,
    required this.dateDiameter,
    required this.indicatorHeight,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasTransactions;
  final double dateDiameter;
  final double indicatorHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isSelected || isToday;
    final label = '${date.day}, ${isToday ? 'today, ' : ''}${isSelected ? 'selected' : ''}'
        '${hasTransactions ? ', has transactions' : ''}';
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        highlightShape: BoxShape.circle,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1 : 0.94,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: dateDiameter,
                  height: dateDiameter,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                      ? AppPalette.accent
                      : isSelected
                        ? AppPalette.accentMuted
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppPalette.accent.withValues(alpha: 0.85))
                        : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: AppPalette.white,
                      fontSize: 15,
                      fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: indicatorHeight,
                child: hasTransactions && indicatorHeight >= 4
                    ? Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.accent,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
