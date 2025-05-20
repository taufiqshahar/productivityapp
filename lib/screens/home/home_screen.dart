import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../providers/task_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/task_manager/task_manager_screen.dart';
import '../../screens/note_hub/note_hub_screen.dart';
import '../../screens/focus_booster/focus_booster_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _initializeDataFuture;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.i('HomeScreen initState called');
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final focusProvider = Provider.of<FocusProvider>(context, listen: false);
    _initializeDataFuture = Future.wait([
      taskProvider.loadTasks(),
      noteProvider.loadNotes(),
      focusProvider.loadSessions(),
    ]).timeout(const Duration(seconds: 10), onTimeout: () {
      _logger.e('Data loading timed out after 10 seconds');
      throw Exception('Data loading timed out');
    }).then((_) {
      _logger.i('Data loading completed successfully');
    }).catchError((error) {
      _logger.e('Error loading data: $error');
      throw error;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning!";
    } else if (hour < 17) {
      return "Good afternoon!";
    } else {
      return "Good evening!";
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.i('HomeScreen build called');
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    return FutureBuilder<void>(
      future: _initializeDataFuture,
      builder: (context, snapshot) {
        _logger.i('FutureBuilder state: ${snapshot.connectionState}, error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          _logger.e('Error in HomeScreen: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading data: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeDataFuture = Future.wait([
                          taskProvider.loadTasks(),
                          noteProvider.loadNotes(),
                          Provider.of<FocusProvider>(context, listen: false).loadSessions(),
                        ]);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        _logger.i('Rendering HomeScreen UI');
        return Scaffold(
          // Removed the appBar property entirely
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track your tasks, take notes, and stay focused.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Dark Mode",
                        style: TextStyle(fontSize: 16),
                      ),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme(value);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskManagerScreen(openAddDialog: true),
                            ),
                          ).then((_) {
                            taskProvider.loadTasks();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("New Task"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NoteHubScreen(openAddDialog: true),
                            ),
                          ).then((_) {
                            noteProvider.loadNotes();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("New Note"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer3<TaskProvider, NoteProvider, FocusProvider>(
                    builder: (context, taskProvider, noteProvider, focusProvider, child) {
                      final completedTasks = taskProvider.completedTasks.length;
                      final totalTasks = taskProvider.tasks.length;
                      final recentNotes = noteProvider.notes
                          .where((note) => note.updatedAt
                          .isAfter(DateTime.now().subtract(const Duration(days: 7))))
                          .length;

                      return Column(
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.task_alt),
                              title: const Text("Tasks"),
                              subtitle: Text(
                                "$completedTasks/$totalTasks completed",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TaskManagerScreen()),
                                ).then((_) {
                                  taskProvider.loadTasks();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.note),
                              title: const Text("Notes"),
                              subtitle: Text(
                                "${noteProvider.notes.length}\n$recentNotes updated recently",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NoteHubScreen()),
                                ).then((_) {
                                  noteProvider.loadNotes();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.timer),
                              title: const Text("Focus Time"),
                              subtitle: Text(
                                "${focusProvider.todayMinutes} min\n${focusProvider.streakDays} day streak",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FocusBoosterScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}