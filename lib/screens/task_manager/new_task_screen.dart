import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dp;
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/form_field.dart';

class NewTaskScreen extends StatefulWidget {
  final Task? task;

  const NewTaskScreen({super.key, this.task});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _titleController = TextEditingController();
  DateTime? _dueDateTime;
  String? _priority;
  String? _category;
  Task? _originalTask;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _originalTask = widget.task;
      _titleController.text = widget.task!.title;
      _dueDateTime = widget.task!.dueDateTime;
      _priority = widget.task!.priority;
      _category = widget.task!.category;
    } else {
      _priority = "Medium";
      _category = "School";
      _dueDateTime = DateTime.now();
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isNotEmpty &&
        _dueDateTime != null &&
        _priority != null &&
        _category != null) {
      try {
        final newTask = Task(
          id: _originalTask?.id ?? '',
          title: _titleController.text,
          dueDateTime: _dueDateTime!,
          priority: _priority!,
          category: _category!,
          isCompleted: _originalTask?.isCompleted ?? false,
        );
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        if (_originalTask != null) {
          await taskProvider.updateTask(_originalTask!, newTask);
        } else {
          await taskProvider.addTask(newTask);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving task: $e")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _originalTask == null ? "New Task" : "Edit Task",
        showHomeButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _originalTask == null ? "New Task" : "Edit Task",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomFormField(
                label: "Task Title",
                hint: "What do you need to do?",
                controller: _titleController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        dp.DatePicker.showDatePicker(
                          context,
                          showTitleActions: true,
                          minTime: DateTime.now(),
                          onConfirm: (date) {
                            setState(() {
                              _dueDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                _dueDateTime?.hour ?? 0,
                                _dueDateTime?.minute ?? 0,
                              );
                            });
                          },
                          currentTime: _dueDateTime ?? DateTime.now(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              _dueDateTime != null
                                  ? DateFormat('dd/MM/yyyy').format(_dueDateTime!)
                                  : "dd/mm/yyyy",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        dp.DatePicker.showTimePicker(
                          context,
                          showTitleActions: true,
                          onConfirm: (time) {
                            setState(() {
                              _dueDateTime = DateTime(
                                _dueDateTime?.year ?? DateTime.now().year,
                                _dueDateTime?.month ?? DateTime.now().month,
                                _dueDateTime?.day ?? DateTime.now().day,
                                time.hour,
                                time.minute,
                              );
                            });
                          },
                          currentTime: _dueDateTime ?? DateTime.now(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              _dueDateTime != null
                                  ? DateFormat('hh:mm a').format(_dueDateTime!)
                                  : "--:-- --",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Priority",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _priority,
                hint: const Text("Select priority"),
                items: ["High", "Medium", "Low"].map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _category,
                hint: const Text("Select category"),
                items: ["School", "Reading", "Work", "Personal"].map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1C4E9),
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_originalTask == null ? "Save Task" : "Update Task"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}