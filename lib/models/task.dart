class Task {
  final String? id;
  final String title;
  final DateTime dueDateTime;
  final String priority;
  final String category;
  final bool isCompleted;
  final DateTime? updatedAt;

  Task({
    this.id,
    required this.title,
    required this.dueDateTime,
    required this.priority,
    required this.category,
    required this.isCompleted,
    this.updatedAt,
  });

  // Factory method to create a Task from Firestore data
  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] as String? ?? 'Untitled Task',
      dueDateTime: data['dueDate'] != null
          ? DateTime.parse(data['dueDate'] as String)
          : DateTime.now(),
      priority: data['priority'] as String? ?? 'Medium',
      category: data['category'] as String? ?? 'General',
      isCompleted: data['isCompleted'] as bool? ?? false,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
    );
  }

  // Method to convert Task to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': '', // To be set by TaskProvider
      'title': title,
      'dueDate': dueDateTime.toIso8601String(),
      'priority': priority,
      'category': category,
      'isCompleted': isCompleted,
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}