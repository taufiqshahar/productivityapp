class FocusSession {
  final String? id; // Make id optional
  final DateTime date;
  final int durationMinutes;

  FocusSession({
    this.id,
    required this.date,
    required this.durationMinutes,
  });

  // Convert FocusSession to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'startTime': date.toIso8601String(), // Map date to startTime
      'duration': durationMinutes, // Map durationMinutes to duration
    };
  }

  // Create FocusSession from Firestore data
  factory FocusSession.fromFirestore(Map<String, dynamic> data, String? id) {
    return FocusSession(
      id: id,
      date: data['startTime'] != null
          ? DateTime.parse(data['startTime'] as String)
          : DateTime.now(),
      durationMinutes: (data['duration'] as num?)?.toInt() ?? 0,
    );
  }
}