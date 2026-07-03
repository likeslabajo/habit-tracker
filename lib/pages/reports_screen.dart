import 'package:flutter/material.dart';
import 'package:habit_tracker_project/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker_project/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  final FirestoreService service;
  static const int _historyDays = 90;

  const ReportsScreen({super.key, required this.service});

  static const _dayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  List<DateTime> get _historyRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(
      _historyDays,
      (i) => today.subtract(Duration(days: _historyDays - 1 - i)),
    );
  }

  List<DateTime> get _currentWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sinceSunday = today.weekday % 7;
    final sunday = today.subtract(Duration(days: sinceSunday));
    return List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  int _longestStreak(
    List<DateTime> days,
    Map<String, Map<String, bool>> logs,
    List<Habit> habits,
  ) {
    int longest = 0;
    for (final habit in habits) {
      int current = 0;
      for (final day in days) {
        final key = DateFormat('yyyy-MM-dd').format(day);
        if (logs[key]?[habit.id] == true) {
          current++;
          if (current > longest) longest = current;
        } else {
          current = 0;
        }
      }
    }
    return longest;
  }

  @override
  Widget build(BuildContext context) {
    final history = _historyRange;
    final week = _currentWeek;
    final startKey = DateFormat('yyyy-MM-dd').format(history.first);
    final endKey = DateFormat('yyyy-MM-dd').format(history.last);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: StreamBuilder<List<Habit>>(
        stream: service.habitsStream(),
        builder: (context, habitsSnap) {
          if (habitsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = habitsSnap.data ?? [];

          return FutureBuilder<Map<String, Map<String, bool>>>(
            future: service.logsInRange(startKey, endKey),
            builder: (context, logsSnap) {
              if (logsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final logs = logsSnap.data ?? {};

              int weekTotal = 0;
              final weekCounts = <int>[];
              for (final day in week) {
                final key = DateFormat('yyyy-MM-dd').format(day);
                final count = habits
                    .where((h) => logs[key]?[h.id] == true)
                    .length;
                weekCounts.add(count);
                weekTotal += count;
              }

              final longestStreak = _longestStreak(history, logs, habits);
              final maxBarValue =
                  habits.isEmpty ? 1 : habits.length; // denominator

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'THIS WEEK',
                          value: '$weekTotal',
                          suffix: 'habits done',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'LONGEST STREAK',
                          value: '$longestStreak',
                          suffix: longestStreak == 1 ? 'DAY' : 'DAYS',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DAILY PROGRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (i) {
                      final ratio = weekCounts[i] / maxBarValue;
                      return _DayBar(
                        label: _dayLabels[i],
                        ratio: ratio.clamp(0.0, 1.0),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'YOUR HABITS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                  const Divider(),
                  if (habits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No habits yet',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                    )
                  else
                    ...habits.map((habit) {
                      final done = logs[todayKey]?[habit.id] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getColorFromHex(habit.colorHex),
                              radius: 6,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                habit.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            _StatusPill(done: done),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                suffix,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String label;
  final double ratio; // 0.0 - 1.0
  static const double _height = 80;
  static const double _width = 44.29;

  const _DayBar({required this.label, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: _width,
            height: _height,
            color: AppColors.primary.withOpacity(0.15),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio == 0 ? 0.06 : ratio,
                child: Container(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool done;

  const _StatusPill({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: done ? const Color(0xFF2E7D32) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        done ? 'Done' : 'To do',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: done ? Colors.white : AppColors.textMedium,
        ),
      ),
    );
  }
}