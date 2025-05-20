import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
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
  final _searchController = TextEditingController();
  Timer? _debounce;

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

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String tempFilter = _filter;
        String? tempCategory = _categoryFilter;
        String? tempPriority = _priorityFilter;
        String tempSortBy = _sortBy;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Filter & Sort Tasks",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text("Status", style: Theme.of(context).textTheme.titleMedium),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: ["All", "Active", "Completed"].map((status) {
                          return ChoiceChip(
                            label: Text(status),
                            selected: tempFilter == status,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempFilter = status;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text("Category", style: Theme.of(context).textTheme.titleMedium),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: ["All", "School", "Reading", "Work", "Personal"].map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: tempCategory == (category == "All" ? null : category),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempCategory = category == "All" ? null : category;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text("Priority", style: Theme.of(context).textTheme.titleMedium),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: ["All", "High", "Medium", "Low"].map((priority) {
                          return ChoiceChip(
                            label: Text(priority),
                            selected: tempPriority == (priority == "All" ? null : priority),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempPriority = priority == "All" ? null : priority;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text("Sort By", style: Theme.of(context).textTheme.titleMedium),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: ["Due Date", "Updated At", "Title"].map((sortOption) {
                          return ChoiceChip(
                            label: Text(sortOption),
                            selected: tempSortBy == sortOption,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempSortBy = sortOption;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filter = tempFilter;
                                _categoryFilter = tempCategory;
                                _priorityFilter = tempPriority;
                                _sortBy = tempSortBy;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Apply"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
            child: const Text("New"),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: "Search Tasks",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<TaskProvider>(context, listen: false).searchTasks('');
                          },
                        ),
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          Provider.of<TaskProvider>(context, listen: false).searchTasks(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list),
                        if (_filter != "All" || _categoryFilter != null || _priorityFilter != null || _sortBy != "Due Date")
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "!",
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => _showFilterModal(context),
                    tooltip: "Filter & Sort",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    var tasks = _filter == "All"
                        ? _searchController.text.isNotEmpty
                        ? taskProvider.filteredTasks
                        : taskProvider.getSortedTasks(_sortBy)
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
                          subtitle: Text(
                            "Due: ${DateFormat('dd/MM/yyyy HH:mm').format(task.dueDateTime)} - ${task.priority}",
                          ),
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
                                  if (confirm == true && mounted) {
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

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}