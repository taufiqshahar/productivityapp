import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import 'new_task_screen.dart';
import '../../widgets/custom_app_bar.dart';

class TaskManagerScreen extends StatefulWidget {
  final bool openAddDialog;
  const TaskManagerScreen({super.key, this.openAddDialog = false});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  String _filter = "All";
  String? _categoryFilter;
  String? _priorityFilter;
  String _sortBy = "Due Date";

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addNewTask(context);
      });
    }
  }

  void _addNewTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTaskScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: CustomAppBar(
        title: "Task Manager",
        actions: [
          TextButton(
            onPressed: () => _addNewTask(context),
            child: const Text(
              "New",
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Manage your tasks and stay on track"),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                children: [
                  ChoiceChip(
                    label: const Text("All"),
                    selected: _filter == "All",
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = "All");
                    },
                  ),
                  ChoiceChip(
                    label: const Text("Active"),
                    selected: _filter == "Active",
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = "Active");
                    },
                  ),
                  ChoiceChip(
                    label: const Text("Completed"),
                    selected: _filter == "Completed",
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = "Completed");
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                hint: const Text("Filter by Category"),
                value: _categoryFilter,
                items: ["All", "School", "Reading", "Work", "Personal"].map((category) {
                  return DropdownMenuItem<String>(
                    value: category == "All" ? null : category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoryFilter = value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                hint: const Text("Filter by Priority"),
                value: _priorityFilter,
                items: ["All", "High", "Medium", "Low"].map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority == "All" ? null : priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _priorityFilter = value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                hint: const Text("Sort by"),
                value: _sortBy,
                items: ["Due Date", "Updated At", "Title"].map((sortOption) {
                  return DropdownMenuItem<String>(
                    value: sortOption,
                    child: Text(sortOption),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _sortBy = value ?? "Due Date");
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    var tasks = _filter == "All"
                        ? taskProvider.getSortedTasks(_sortBy)
                        : _filter == "Active"
                        ? taskProvider.activeTasks
                        : taskProvider.completedTasks;
                    if (_categoryFilter != null) {
                      tasks = tasks.where((task) => task.category == _categoryFilter).toList();
                    }
                    if (_priorityFilter != null) {
                      tasks = tasks.where((task) => task.priority == _priorityFilter).toList();
                    }
                    return tasks.isEmpty
                        ? const Center(child: Text('No tasks found'))
                        : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return ListTile(
                          title: Text(task.title),
                          subtitle: Text("Due: ${task.dueDateTime.toString()} - ${task.priority}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  taskProvider.toggleTaskCompletion(task);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete task',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Task'),
                                      content: Text('Are you sure you want to delete "${task.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && mounted) { //
                                    try {
                                      await taskProvider.deleteTask(task);
                                      _scaffoldMessengerKey.currentState?.showSnackBar(
                                        const SnackBar(content: Text('Task deleted successfully')),
                                      );
                                    } catch (e) {
                                      _scaffoldMessengerKey.currentState?.showSnackBar(
                                        SnackBar(content: Text('Failed to delete task: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewTaskScreen(task: task),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}