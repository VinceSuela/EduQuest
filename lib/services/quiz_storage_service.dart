import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/quiz_session.dart';

class QuizStorageService {
  static const String _sessionsBox = 'quiz_sessions';
  static const String _statsBox = 'user_stats';

  static const String keyTotalAnswered = 'total_answered';
  static const String keyTotalCorrect = 'total_correct';
  static const String keyHighestAccuracy = 'highest_accuracy';
  static const String keyCurrentStreak = 'current_streak';
  static const String keyLastSessionDate = 'last_session_date';
  static const String keyLastWeeklyPush = 'last_weekly_push';

  static const int _phtOffsetHours = 8;

  Box<QuizSession> get _sessions => Hive.box<QuizSession>(_sessionsBox);
  Box get _stats => Hive.box(_statsBox);


  Future<void> saveSession(QuizSession session) async {
    await _sessions.put(session.sessionId, session);
    await _updateStats(session);
    await _pushToFirestoreIfDue();
  }

  List<QuizSession> loadAllSessions() {
    return _sessions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  QuizSession? loadSession(String sessionId) => _sessions.get(sessionId);

  Future<void> deleteSession(String sessionId) async {
    await _sessions.delete(sessionId);
  }

  Future<void> clearAllSessions() async {
    await _sessions.clear();
    await _stats.clear();
  }

  Map<String, dynamic> loadStats() {
    return {
      keyTotalAnswered: _stats.get(keyTotalAnswered, defaultValue: 0),
      keyTotalCorrect: _stats.get(keyTotalCorrect, defaultValue: 0),
      keyHighestAccuracy: _stats.get(keyHighestAccuracy, defaultValue: 0.0),
      keyCurrentStreak: _stats.get(keyCurrentStreak, defaultValue: 0),
      keyLastSessionDate: _stats.get(keyLastSessionDate),
    };
  }

  double computeLeaderboardScore() {
    final totalAnswered = _stats.get(keyTotalAnswered, defaultValue: 0) as int;
    final totalCorrect = _stats.get(keyTotalCorrect, defaultValue: 0) as int;

    if (totalAnswered < 70) return 0.0;

    final accuracy = totalCorrect / totalAnswered;
    final reliability = _reliabilityMultiplier(totalAnswered);
    final difficulty = _difficultyMultiplier();

    return accuracy * reliability * difficulty * 100;
  }

  DateTime get _nowInPHT =>
      DateTime.now().toUtc().add(const Duration(hours: _phtOffsetHours));

  DateTime get _currentWeekStartPHT {
    final pht = _nowInPHT;
    final daysFromMonday = pht.weekday - DateTime.monday;
    return DateTime.utc(
      pht.year,
      pht.month,
      pht.day - daysFromMonday,
      0, 0, 0,
    );
  }

  String get _currentWeekLabel {
    final weekStart = _currentWeekStartPHT;
    final weekNumber = _isoWeekNumber(weekStart);
    final monthStr = weekStart.month.toString().padLeft(2, '0');
    final dayStr = weekStart.day.toString().padLeft(2, '0');
    return '${weekStart.year}-W${weekNumber.toString().padLeft(2, '0')}-Mon-$monthStr$dayStr';
  }

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime.utc(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    return ((dayOfYear + startOfYear.weekday - 1) / 7).floor() + 1;
  }

  Future<void> _pushToFirestoreIfDue() async {
    if (!_isWeeklyPushDue()) return;
    await pushWeeklyStatsToFirestore();
  }

  bool _isWeeklyPushDue() {
    final lastPushStr = _stats.get(keyLastWeeklyPush) as String?;
    if (lastPushStr == null) return true;

    final lastPushedWeekStart = DateTime.parse(lastPushStr);
    return _currentWeekStartPHT.isAfter(lastPushedWeekStart);
  }

  Future<void> pushWeeklyStatsToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final score = computeLeaderboardScore();
    final stats = loadStats();

    try {
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc('weekly')
          .collection(_currentWeekLabel)
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'userEmail': user.email ?? 'Anonymous',
        'displayName': user.displayName ?? 'Student',
        'score': score,
        'totalAnswered': stats[keyTotalAnswered],
        'totalCorrect': stats[keyTotalCorrect],
        'accuracyPercent': stats[keyTotalAnswered] > 0
            ? (stats[keyTotalCorrect] / stats[keyTotalAnswered]) * 100
            : 0.0,
        'currentStreak': stats[keyCurrentStreak],
        'weekStartPHT': _currentWeekStartPHT.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _stats.put(
        keyLastWeeklyPush,
        _currentWeekStartPHT.toIso8601String(),
      );
    } catch (e) {
      // Silent fail — student can still study offline, retries on next saveSession()
    }
  }

  Future<void> _updateStats(QuizSession session) async {
    final prevAnswered = _stats.get(keyTotalAnswered, defaultValue: 0) as int;
    final prevCorrect = _stats.get(keyTotalCorrect, defaultValue: 0) as int;

    final newAnswered = prevAnswered + session.totalQuestions;
    final newCorrect = prevCorrect + session.correctCount;

    final prevBest = _stats.get(keyHighestAccuracy, defaultValue: 0.0) as double;
    final newBest = session.accuracyPercent > prevBest
        ? session.accuracyPercent
        : prevBest;

    final lastDateStr = _stats.get(keyLastSessionDate) as String?;

    await _stats.putAll({
      keyTotalAnswered: newAnswered,
      keyTotalCorrect: newCorrect,
      keyHighestAccuracy: newBest,
      keyCurrentStreak: _calculateStreak(lastDateStr),
      keyLastSessionDate: DateTime.now().toIso8601String(),
    });
  }

  int _calculateStreak(String? lastDateStr) {
    final current = _stats.get(keyCurrentStreak, defaultValue: 0) as int;
    if (lastDateStr == null) return 1;

    final lastPHT = DateTime.parse(lastDateStr)
        .toUtc()
        .add(const Duration(hours: _phtOffsetHours));
    final nowPHT = _nowInPHT;

    final lastDay = DateTime(lastPHT.year, lastPHT.month, lastPHT.day);
    final todayDay = DateTime(nowPHT.year, nowPHT.month, nowPHT.day);
    final diff = todayDay.difference(lastDay).inDays;

    if (diff == 0) return current;
    if (diff == 1) return current + 1;
    return 1;
  }

  double _reliabilityMultiplier(int totalAnswered) {
    if (totalAnswered >= 300) return 1.20;
    if (totalAnswered >= 200) return 1.10;
    if (totalAnswered >= 100) return 1.05;
    return 1.00;
  }

  double _difficultyMultiplier() {
    final sessions = loadAllSessions();
    if (sessions.isEmpty) return 1.0;
    const multipliers = {
      'easy': 1.0,
      'medium': 1.15,
      'hard': 1.30,
      'mixed': 1.20,
    };
    final avg = sessions.fold(
      0.0,
      (sum, s) => sum + (multipliers[s.difficulty] ?? 1.0),
    );
    return avg / sessions.length;
  }
}