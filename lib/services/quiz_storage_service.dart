import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/quiz_session.dart';

// This service manages quiz session storage, lifetime stats, and weekly leaderboard 
// stats using Hive for local persistence and Firestore for syncing leaderboard data.
class QuizStorageService {
  // Hive box names
  static const String _sessionsBox = 'quiz_sessions';
  static const String _statsBox    = 'user_stats';

  // Lifetime stat keys (persist across app usage)
  static const String keyTotalAnswered   = 'total_answered';
  static const String keyTotalCorrect    = 'total_correct';
  static const String keyHighestAccuracy = 'highest_accuracy';
  static const String keyCurrentStreak   = 'current_streak';
  static const String keyLastSessionDate = 'last_session_date';
  static const String keyTotalPomodoros  = 'total_pomodoros';

// Weekly stat keys (reset every week, used for leaderboard)
  static const String keyWeeklyData      = 'weekly_data';
  static const String keyLastWeeklyPush  = 'last_weekly_push';
  static const String keyLastWeeklyReset = 'last_weekly_reset';

// Weekly data JSON structure:
  static const int _phtOffsetHours = 8;

  Box<QuizSession> get _sessions => Hive.box<QuizSession>(_sessionsBox);
  Box              get _stats    => Hive.box(_statsBox);

  // MAIN ENTRY POINTS

  // Call from quiz_page.dart when the user finishes a quiz.
  // The pdfHash is an optional parameter that can be used to prevent "pdf farming" — 
  // users repeatedly taking quizzes from the same PDF to boost their weekly leaderboard score. 
  // If provided, the service will only count one quiz session per unique pdfHash each week.
  Future<void> saveSession(QuizSession session, {String? pdfHash}) async {
    await _resetWeeklyStatsIfDue();           // step 1: reset if new week
    await _sessions.put(session.sessionId, session); // step 2: save history
    await _updateLifetimeStats(session);      // step 3: update profile stats
    await _updateWeeklyStats(session, pdfHash: pdfHash); // step 4: update leaderboard stats
    await _pushToFirestoreIfDue();            // step 5: sync if week rolled over
  }

// Call from pomodoro_timer.dart when a Pomodoro cycle completes.
  Future<void> recordPomodoroComplete() async {
    await _resetWeeklyStatsIfDue();

    // Lifetime counter
    final lifetime = _stats.get(keyTotalPomodoros, defaultValue: 0) as int;
    await _stats.put(keyTotalPomodoros, lifetime + 1);

    // Weekly counter
    final weekly = _getWeeklyData();
    weekly['pomodorosThisWeek'] =
        ((weekly['pomodorosThisWeek'] as int?) ?? 0) + 1;
    await _saveWeeklyData(weekly);
  }

  // SESSION CRUD

  List<QuizSession> loadAllSessions() => _sessions.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  QuizSession? loadSession(String sessionId) => _sessions.get(sessionId);

  Future<void> deleteSession(String sessionId) => _sessions.delete(sessionId);

  Future<void> clearAllSessions() async {
    await _sessions.clear();
    await _stats.clear();
  }

 // STATS & LEADERBOARD LOGIC

  /// Lifetime stats for the profile page.
  Map<String, dynamic> loadLifetimeStats() => {
    keyTotalAnswered:   _stats.get(keyTotalAnswered,   defaultValue: 0),
    keyTotalCorrect:    _stats.get(keyTotalCorrect,    defaultValue: 0),
    keyHighestAccuracy: _stats.get(keyHighestAccuracy, defaultValue: 0.0),
    keyCurrentStreak:   _stats.get(keyCurrentStreak,  defaultValue: 0),
    keyLastSessionDate: _stats.get(keyLastSessionDate),
    keyTotalPomodoros:  _stats.get(keyTotalPomodoros,  defaultValue: 0),
  };

// Weekly stats for leaderboard calculations (also used for profile display on leaderboard cards).
  Map<String, dynamic> loadWeeklyStats() {
    final d = _getWeeklyData();
    return {
      'weeklyAnswered':     d['weeklyAnswered']     ?? 0,
      'weeklyCorrect':      d['weeklyCorrect']      ?? 0,
      'weeklyUniquePdfs':   d['weeklyUniquePdfs']   ?? 0,
      'pomodorosThisWeek':  d['pomodorosThisWeek']  ?? 0,
    };
  }

  // LEADERBOARD SCORE  (weekly stats only)

  double computeLeaderboardScore() {
    final weekly   = _getWeeklyData();
    final answered = (weekly['weeklyAnswered'] as int?) ?? 0;
    final correct  = (weekly['weeklyCorrect']  as int?) ?? 0;

    // Threshold checks LIFETIME total, not weekly
    final lifetimeTotalAnswered = _stats.get(keyTotalAnswered, defaultValue: 0) as int;
    if (lifetimeTotalAnswered < 70) return 0.0;

    if (answered == 0) return 0.0;

    final accuracy     = correct / answered;
    final consistency  = min(answered / 300.0, 1.0);
    final difficulty   = _weeklyDifficultyMultiplier(weekly);
    final pomodoroBonus = _pomodoroBonus(weekly);

    return accuracy * consistency * difficulty * pomodoroBonus * 1000;
  }

  // PHT TIME & WEEKLY RESET LOGIC

  DateTime get _nowInPHT =>
      DateTime.now().toUtc().add(const Duration(hours: _phtOffsetHours));

  DateTime get _currentWeekStartPHT {
    final pht = _nowInPHT;
    final daysFromMonday = pht.weekday - DateTime.monday;
    return DateTime.utc(pht.year, pht.month, pht.day - daysFromMonday, 0, 0, 0);
  }

  String get _currentWeekLabel {
    final s  = _currentWeekStartPHT;
    final wn = _isoWeekNumber(s);
    return '${s.year}-W${wn.toString().padLeft(2, '0')}'
        '-Mon-${s.month.toString().padLeft(2, '0')}${s.day.toString().padLeft(2, '0')}';
  }

// Exposed for testing purposes (e.g. to verify weekly reset logic around DST changes).
  String get currentWeekLabel => _currentWeekLabel;

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime.utc(date.year, 1, 1);
    final dayOfYear   = date.difference(startOfYear).inDays;
    return ((dayOfYear + startOfYear.weekday - 1) / 7).floor() + 1;
  }

  // WEEKLY RESET  (Monday 12AM PHT)

  Future<void> _resetWeeklyStatsIfDue() async {
    final lastResetStr = _stats.get(keyLastWeeklyReset) as String?;
    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      if (!_currentWeekStartPHT.isAfter(lastReset)) return;
    }

    // Reset weekly stats to defaults for the new week
    await _saveWeeklyData({
      'weeklyAnswered':     0,
      'weeklyCorrect':      0,
      'pomodorosThisWeek':  0,
      'weeklyUniquePdfs':   0,
      'weeklyPdfHashes':    <String>[],  
      'weeklyDifficulties': <String>[],
      'weekStart':          _currentWeekStartPHT.toIso8601String(),
    });
    await _stats.put(keyLastWeeklyReset, _currentWeekStartPHT.toIso8601String());
  }

  // FIRESTORE PUSH

  Future<void> _pushToFirestoreIfDue() async {
    if (!_isWeeklyPushDue()) return;
    await pushWeeklyStatsToFirestore();
  }

  bool _isWeeklyPushDue() {
    final lastPushStr = _stats.get(keyLastWeeklyPush) as String?;
    if (lastPushStr == null) return true;
    return _currentWeekStartPHT.isAfter(DateTime.parse(lastPushStr));
  }

  // Also callable manually (e.g. a "Sync Now" button in Settings).
  Future<void> pushWeeklyStatsToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final score = computeLeaderboardScore();
  final weekly = loadWeeklyStats();
  final lifetime = loadLifetimeStats();

  try {
    // GET REAL USER DATA FROM FIRESTORE
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};

    final displayName =
        userData['displayName'] ??
        user.displayName ??
        'Student';

    final photoURL =
        userData['photoURL'] ??
        user.photoURL ??
        '';

    await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('weekly')
        .collection(_currentWeekLabel)
        .doc(user.uid)
        .set({
      'uid': user.uid,

      'userEmail': user.email ?? 'Anonymous',

      // FIXED
      'displayName': displayName,

      // FIXED
      'photoURL': photoURL,

      'score': score,

      // WEEKLY
      'weeklyAnswered': weekly['weeklyAnswered'],
      'weeklyCorrect': weekly['weeklyCorrect'],
      'weeklyUniquePdfs': weekly['weeklyUniquePdfs'],
      'pomodorosThisWeek': weekly['pomodorosThisWeek'],

      'accuracyPercent': weekly['weeklyAnswered'] > 0
          ? (weekly['weeklyCorrect'] /
                  weekly['weeklyAnswered']) *
              100
          : 0.0,

      // FIXED FIELD NAME
      'currentStreak': lifetime[keyCurrentStreak],

      'weekStartPHT':
          _currentWeekStartPHT.toIso8601String(),

      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _stats.put(
      keyLastWeeklyPush,
      _currentWeekStartPHT.toIso8601String(),
    );
  } catch (e) {
    print('Leaderboard push failed: $e');
  }
}
// Pushes the quiz session results to Firestore for leaderboard consideration, if the weekly push is due.

  Future<void> _updateLifetimeStats(QuizSession session) async {
    final prevAnswered = _stats.get(keyTotalAnswered,   defaultValue: 0)   as int;
    final prevCorrect  = _stats.get(keyTotalCorrect,    defaultValue: 0)   as int;
    final prevBest     = _stats.get(keyHighestAccuracy, defaultValue: 0.0) as double;
    final lastDateStr  = _stats.get(keyLastSessionDate) as String?;

    await _stats.putAll({
      keyTotalAnswered:   prevAnswered + session.totalQuestions,
      keyTotalCorrect:    prevCorrect  + session.correctCount,
      keyHighestAccuracy: session.accuracyPercent > prevBest
          ? session.accuracyPercent : prevBest,
      keyCurrentStreak:   _calculateStreak(lastDateStr),
      keyLastSessionDate: DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateWeeklyStats(
    QuizSession session, {
    String? pdfHash,
  }) async {
    final weekly = _getWeeklyData();

    // PDF farming prevention
    // If a pdfHash is provided and was already used this week,
    // skip the weekly stat update (session still saves to history).
    if (pdfHash != null) {
      final seen = List<String>.from(weekly['weeklyPdfHashes'] ?? []);
      if (seen.contains(pdfHash)) return; // already contributed this week
      seen.add(pdfHash);
      weekly['weeklyPdfHashes']  = seen;
      weekly['weeklyUniquePdfs'] = seen.length;
    }

    weekly['weeklyAnswered'] =
        ((weekly['weeklyAnswered'] as int?) ?? 0) + session.totalQuestions;
    weekly['weeklyCorrect'] =
        ((weekly['weeklyCorrect'] as int?) ?? 0) + session.correctCount;

    final difficulties = List<String>.from(weekly['weeklyDifficulties'] ?? []);
    difficulties.add(session.difficulty);
    weekly['weeklyDifficulties'] = difficulties;

    await _saveWeeklyData(weekly);
  }

// Calculates the current streak based on the last session date.
  int _calculateStreak(String? lastDateStr) {
    final current = _stats.get(keyCurrentStreak, defaultValue: 0) as int;
    if (lastDateStr == null) return 1;

    final lastPHT  = DateTime.parse(lastDateStr)
        .toUtc().add(const Duration(hours: _phtOffsetHours));
    final nowPHT   = _nowInPHT;
    final lastDay  = DateTime(lastPHT.year, lastPHT.month, lastPHT.day);
    final todayDay = DateTime(nowPHT.year, nowPHT.month, nowPHT.day);
    final diff     = todayDay.difference(lastDay).inDays;

    if (diff == 0) return current;
    if (diff == 1) return current + 1;
    return 1;
  }

// Difficulty multiplier based on the weighted average of this week's session difficulties.
  double _weeklyDifficultyMultiplier(Map<String, dynamic> weekly) {
    const multipliers = {'easy': 1.0, 'medium': 1.15, 'hard': 1.30, 'mixed': 1.20};
    final difficulties = List<String>.from(weekly['weeklyDifficulties'] ?? []);
    if (difficulties.isEmpty) return 1.0;
    final avg = difficulties.fold(
        0.0, (sum, d) => sum + (multipliers[d] ?? 1.0));
    return avg / difficulties.length;
  }

// Bonus multiplier based on Pomodoro cycles completed this week.
  double _pomodoroBonus(Map<String, dynamic> weekly) {
    final pomodoros = (weekly['pomodorosThisWeek'] as int?) ?? 0;
    return 1.0 + min(pomodoros / 100.0, 0.10);
  }

// Helper methods to load and save the weekly data JSON blob in Hive.
  Map<String, dynamic> _getWeeklyData() {
    final raw = _stats.get(keyWeeklyData) as String?;
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveWeeklyData(Map<String, dynamic> data) async {
    await _stats.put(keyWeeklyData, jsonEncode(data));
  }
}