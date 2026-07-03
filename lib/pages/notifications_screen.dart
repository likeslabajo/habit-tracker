import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_tracker_project/app_colors.dart';
import 'package:habit_tracker_project/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  final FirestoreService service;

  const NotificationsScreen({super.key, required this.service});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Map<String, String> _reminderPeriods = {
    'morning': '8:00 AM',
    'afternoon': '1:00 PM',
    'evening': '7:00 PM',
  };

  bool _notificationsEnabled = false;
  Set<String> _selectedPeriods = {};
  Set<String> _selectedHabitIds = {};
  bool _loading = true;

  late final String _uid;
  late final DocumentReference<Map<String, dynamic>> _settingsRef;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _settingsRef = FirebaseFirestore.instance
        .collection('notification_settings')
        .doc(_uid);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _settingsRef.get();
      if (doc.exists) {
        final data = doc.data();
        final enabled = (data?['enabled'] ?? false) as bool;
        final periods = List<String>.from(
          (data?['reminderTimes'] ?? <String>[]) as List,
        );
        final habitIds = List<String>.from(
          (data?['habitIds'] ?? <String>[]) as List,
        );
        setState(() {
          _notificationsEnabled = enabled;
          _selectedPeriods = periods.toSet();
          _selectedHabitIds = habitIds.toSet();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      // ignore errors for now, could log or show UI
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _persistSettings() async {
    try {
      await _settingsRef.set({
        'enabled': _notificationsEnabled,
        'reminderTimes': _selectedPeriods.toList(),
        'habitIds': _selectedHabitIds.toList(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore errors for now
    }
  }

  void _onToggleChanged(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    _persistSettings();
  }

  void _onPeriodTapped(String periodKey) {
    if (!_notificationsEnabled) return;
    setState(() {
      if (_selectedPeriods.contains(periodKey)) {
        _selectedPeriods.remove(periodKey);
      } else {
        _selectedPeriods.add(periodKey);
      }
    });
    _persistSettings();
  }

  void _onHabitToggled(String habitId, bool value) {
    if (!_notificationsEnabled) return;
    setState(() {
      if (value) {
        _selectedHabitIds.add(habitId);
      } else {
        _selectedHabitIds.remove(habitId);
      }
    });
    _persistSettings();
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  Widget _buildPeriodChip(String periodKey, String timeLabel) {
    final isSelected = _selectedPeriods.contains(periodKey);
    final label = periodKey[0].toUpperCase() + periodKey.substring(1);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodTapped(periodKey),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enable Notifications
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: const Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      subtitle: const Text(
                        'Get reminded to do your habits',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      value: _notificationsEnabled,
                      onChanged: _onToggleChanged,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Remind me at
                  _buildSectionHeader('REMIND ME AT'),
                  Opacity(
                    opacity: _notificationsEnabled ? 1.0 : 0.4,
                    child: IgnorePointer(
                      ignoring: !_notificationsEnabled,
                      child: Row(
                        children: [
                          for (final entry in _reminderPeriods.entries)
                            _buildPeriodChip(entry.key, entry.value),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Your habits
                  _buildSectionHeader('YOUR HABITS'),
                  const Divider(),
                  Expanded(
                    child: Opacity(
                      opacity: _notificationsEnabled ? 1.0 : 0.4,
                      child: IgnorePointer(
                        ignoring: !_notificationsEnabled,
                        child: StreamBuilder<List<Habit>>(
                          stream: widget.service.habitsStream(),
                          builder: (context, habitsSnap) {
                            if (habitsSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final habits = habitsSnap.data ?? [];

                            if (habits.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'No habits yet. Add some habits first to '
                                  'get notified about them.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: habits.length,
                              itemBuilder: (context, index) {
                                final habit = habits[index];
                                final isSelected = _selectedHabitIds.contains(
                                  habit.id,
                                );
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: _getColorFromHex(
                                      habit.colorHex,
                                    ),
                                  ),
                                  title: Text(
                                    habit.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  trailing: Switch(
                                    activeColor: AppColors.primary,
                                    value: isSelected,
                                    onChanged: (value) =>
                                        _onHabitToggled(habit.id, value),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}