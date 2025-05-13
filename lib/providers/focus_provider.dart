import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/focus_session.dart';

class FocusProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<FocusSession> _sessions = [];
  final _logger = Logger();
  static const int weeklyGoalMinutes = 500;

  List<FocusSession> get sessions => _sessions;

  FocusProvider() {
    loadSessions();
  }

  Future<void> loadSessions() async {
    try {
      _sessions.clear();
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        notifyListeners();
        return;
      }
      final snapshot = await _firestore
          .collection('focus_sessions')
          .where('userId', isEqualTo: user.uid)
          .get();
      _sessions.addAll(snapshot.docs.map((doc) {
        return FocusSession.fromFirestore(doc.data(), doc.id);
      }).toList());
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading focus sessions: $e');
      rethrow;
    }
  }

  Future<void> addSession(FocusSession session) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user is signed in');
        throw Exception('User not authenticated');
      }

      final sessionData = session.toFirestore();
      sessionData['userId'] = user.uid;

      _logger.i('Adding session data: $sessionData');
      final docRef = await _firestore.collection('focus_sessions').add(sessionData);
      _sessions.add(FocusSession(
        id: docRef.id,
        date: session.date,
        durationMinutes: session.durationMinutes,
      ));
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding focus session: $e');
      rethrow;
    }
  }

  int get todayMinutes {
    final today = DateTime.now();
    return _sessions
        .where((session) =>
    session.date.year == today.year &&
        session.date.month == today.month &&
        session.date.day == today.day)
        .fold(0, (total, session) => total + session.durationMinutes);
  }

  int get streakDays {
    if (_sessions.isEmpty) return 0;

    final sortedSessions = _sessions..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (var session in sortedSessions) {
      final sessionDate = DateTime(session.date.year, session.date.month, session.date.day);
      final currentDateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);

      if (currentDateOnly.difference(sessionDate).inDays > 1) {
        break;
      }

      streak++;
      currentDate = sessionDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int get weekMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _sessions
        .where((session) =>
    session.date.isAfter(startOfWeek) || session.date.isAtSameMomentAs(startOfWeek))
        .fold(0, (total, session) => total + session.durationMinutes);
  }

  int get sessionCount {
    return _sessions.length;
  }

  double get weeklyProgress {
    final minutes = weekMinutes;
    return (minutes / weeklyGoalMinutes) * 100;
  }

  Map<DateTime, int> getDailyFocusMinutes({required int days}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dailyMinutes = <DateTime, int>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      dailyMinutes[DateTime(date.year, date.month, date.day)] = 0;
    }

    for (var session in _sessions) {
      final sessionDate = session.date;
      if (sessionDate.isAfter(startDate) && sessionDate.isBefore(endDate)) {
        final dateKey = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
        dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + session.durationMinutes;
      }
    }

    return dailyMinutes;
  }

  Map<String, int> getWeeklyFocusMinutes({required int weeks}) {
    final now = DateTime.now();
    final weeklyMinutes = <String, int>{};

    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < weeks; i++) {
      final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';

      final minutes = _sessions
          .where((session) =>
      session.date.isAfter(weekStart) && session.date.isBefore(weekEnd))
          .fold(0, (total, session) => total + session.durationMinutes);
      weeklyMinutes[weekKey] = minutes;
    }

    return weeklyMinutes;
  }
}