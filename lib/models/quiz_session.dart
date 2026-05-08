import 'package:hive_ce/hive_ce.dart';
import 'quiz_question.dart';
import 'dart:math';

part 'quiz_session.g.dart';

@HiveType(typeId: 1)
class QuizSession extends HiveObject {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final String sourceFileName;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<QuizQuestionHive> questions;

  @HiveField(4)
  final List<String> userAnswerKeys;

  @HiveField(5)
  final String difficulty;


  QuizSession({
    required this.sessionId,
    required this.sourceFileName,
    required this.createdAt,
    required this.questions,
    required this.userAnswerKeys,
    required this.difficulty,
  });

  factory QuizSession.create({
    required String sourceFileName,
    required List<QuizQuestionHive> questions,
    required List<String> userAnswerKeys,
    required String difficulty,
  }) {
    return QuizSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceFileName: sourceFileName,
      createdAt: DateTime.now(),
      questions: questions,
      userAnswerKeys: userAnswerKeys,
      difficulty: difficulty,
    );
  }

  int get totalQuestions => questions.length;

  int get correctCount {
    int count = 0;
    for (int i = 0; i < min(questions.length, userAnswerKeys.length); i++) {
      if (userAnswerKeys[i].isNotEmpty &&
          userAnswerKeys[i] == questions[i].answer) {
        count++;
      }
    }
    return count;
  }

  int get incorrectCount => totalQuestions - correctCount;

  double get accuracyPercent =>
      totalQuestions == 0 ? 0.0 : (correctCount / totalQuestions) * 100;

  bool get meetsLeaderboardThreshold => totalQuestions >= 70;

  Map<String, int> get correctByDifficulty {
    final breakdown = {'easy': 0, 'medium': 0, 'hard': 0};
    for (int i = 0; i < questions.length; i++) {
      if (userAnswerKeys[i].isNotEmpty &&
          userAnswerKeys[i] == questions[i].answer) {
        final d = questions[i].difficulty;
        breakdown[d] = (breakdown[d] ?? 0) + 1;
      }
    }
    return breakdown;
  }

  Map<String, dynamic> toLeaderboardPayload(String uid, String? userEmail) {
    return {
      'uid': uid,
      'userEmail': userEmail ?? 'Anonymous',
      'sessionId': sessionId,
      'sourceFileName': sourceFileName,
      'createdAt': createdAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'accuracyPercent': accuracyPercent,
      'difficulty': difficulty,
      'correctByDifficulty': correctByDifficulty,
    };
  }
}