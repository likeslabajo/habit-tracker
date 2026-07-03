import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_tracker_project/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker_project/auth.dart';
import 'package:habit_tracker_project/firestore_service.dart';
import 'login_screen.dart';
import 'add_habit_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) {
          // Not signed in (or session expired) — bounce to login.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final uid = user.uid;
        final service = FirestoreService(uid);
        return _buildHomeContent(context, uid, service);
      },
    );
  }

  Stream<String> _usernameStream(String uid) {
    return FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .snapshots()
        .map((doc) {
      final username = doc.data()?['username'] as String?;
      return (username != null && username.isNotEmpty)
          ? username
          : widget.username;
    });
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }

  Future<void> _signOut(BuildContext context) async {
    await Auth().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    String uid,
    FirestoreService service,
  ) {
    final formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return StreamBuilder<String>(
      stream: _usernameStream(uid),
      initialData: widget.username,
      builder: (context, usernameSnap) {
        final currentUsername = usernameSnap.data ?? widget.username;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Streakly',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          drawer: NavigationDrawer(
            onDestinationSelected: (index) {
              Navigator.pop(context); // close the drawer first
              switch (index) {
                case 0:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddHabitScreen(service: service),
                    ),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(username: currentUsername),
                    ),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportsScreen(service: service),
                    ),
                  );
                  break;
                case 3:
                  // Notifications - no-op for now
                  break;
              }
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '@$currentUsername',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Divider(),
              const NavigationDrawerDestination(
                icon: Icon(Icons.checklist),
                label: Text('Habits'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.bar_chart_rounded),
                label: Text('Reports'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.notifications),
                label: Text('Notifications'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // close the drawer first
                  _signOut(context);
                },
              ),
            ],
          ),
          body: StreamBuilder<List<Habit>>(
            stream: service.habitsStream(),
            builder: (context, habitsSnap) {
              if (habitsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final habits = habitsSnap.data ?? [];

              return StreamBuilder<Map<String, bool>>(
                stream: service.dailyLogStream(today),
                builder: (context, logSnap) {
                  final completion = logSnap.data ?? {};
                  final selected = habits
                      .where((h) => completion[h.id] != true)
                      .toList();
                  final completed = habits
                      .where((h) => completion[h.id] == true)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today is $formattedDate',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                                Text(
                                  'Hey, $currentUsername!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Text('👋', style: TextStyle(fontSize: 36)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader("TODAY'S HABITS"),
                      if (selected.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Text(
                                'No habits yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: AppColors.textMedium,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Add your habits to start your streak',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...selected.map(
                          (habit) => _buildHabitCard(
                            habit.name,
                            _getColorFromHex(habit.colorHex),
                            isCompleted: false,
                            onTapCircle: () => service.setHabitCompletion(
                              today,
                              habit.id,
                              true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildSectionHeader("COMPLETED"),
                      if (completed.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Tap on an activity circle to mark as done.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMedium,
                            ),
                          ),
                        )
                      else
                        ...completed.map(
                          (habit) => _buildHabitCard(
                            habit.name,
                            _getColorFromHex(habit.colorHex),
                            isCompleted: true,
                            onTapCircle: () => service.setHabitCompletion(
                              today,
                              habit.id,
                              false,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddHabitScreen(service: service),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            tooltip: 'Add Habits',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
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
        const Divider(),
      ],
    );
  }

  Widget _buildHabitCard(
    String title,
    Color leadingDotColor, {
    bool isCompleted = false,
    required VoidCallback onTapCircle,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.textLight, width: 1.0),
      ),
      color: Colors.grey[50],
      child: Container(
        height: 64,
        alignment: Alignment.center,
        child: ListTile(
          leading: CircleAvatar(backgroundColor: leadingDotColor, radius: 8),
          title: Text(
            title,
            style: TextStyle(
              color: isCompleted ? Colors.grey : AppColors.textDark,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: GestureDetector(
            onTap: onTapCircle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color.fromARGB(255, 90, 83, 164)
                      : AppColors.textMedium.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}