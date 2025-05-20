import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Task> _tasks = [];
  final _logger = Logger();
  String _currentQuery = ''; // Added for search

  List<Task> get tasks => _tasks;
  List<Task> get activeTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  // Getter for sorted tasks based on the selected criterion
  List<Task> getSortedTasks(String sortBy) {
    final sortedTasks = List<Task>.from(_tasks);
    switch (sortBy) {
      case 'Due Date':
        sortedTasks.sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));
        break;
      case 'Updated At':
        sortedTasks.sort((a, b) => (b.updatedAt ?? DateTime.now()).compareTo(a.updatedAt ?? DateTime.now()));
        break;
      case 'Title':
        sortedTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      default:
        sortedTasks.sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));
    }
    return sortedTasks;
  }

  // Getter for filtered tasks based on search query
  List<Task> get filteredTasks {
    var tasks = getSortedTasks('Due Date'); // Default sort for consistency
    if (_currentQuery.isEmpty) {
      return tasks;
    }
    return tasks.where((task) {
      return task.title.toLowerCase().contains(_currentQuery.toLowerCase());
    }).toList();
  }

  // Method to update search query
  void searchTasks(String query) {
    _currentQuery = query;
    notifyListeners();
  }

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      _tasks.clear();
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        notifyListeners();
        return;
      }
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .get();
      _tasks.addAll(snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.data(), doc.id);
      }).toList());
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading tasks: $e');
      rethrow;
    }
  }

  Future<void> addTask(Task task) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        throw Exception('User not authenticated');
      }
      if (task.title.isEmpty) {
        _logger.w('Task title is empty');
        throw Exception('Task title cannot be empty');
      }
      if (task.priority.isEmpty) {
        _logger.w('Task priority is empty');
        throw Exception('Task priority cannot be empty');
      }
      final taskData = task.toFirestore();
      taskData['userId'] = user.uid;
      _logger.i('Adding task: $taskData');
      final docRef = await _firestore.collection('tasks').add(taskData);
      _tasks.add(Task.fromFirestore(taskData, docRef.id));
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task oldTask, Task newTask) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        throw Exception('User not authenticated');
      }
      final taskData = newTask.toFirestore();
      taskData['userId'] = user.uid;
      await _firestore.collection('tasks').doc(oldTask.id).update(taskData);
      await loadTasks();
    } catch (e) {
      _logger.e('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).delete();
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        dueDateTime: task.dueDateTime,
        priority: task.priority,
        category: task.category,
        isCompleted: !task.isCompleted,
      );
      await updateTask(task, updatedTask);
    } catch (e) {
      _logger.e('Error toggling task completion: $e');
      rethrow;
    }
  }
}