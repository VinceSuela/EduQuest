import 'package:hive_ce/hive_ce.dart';
import '../providers/quiz_generator.dart'; 

part 'quiz_question.g.dart';

@HiveType(typeId: 0)
class QuizQuestionHive extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String question;

  @HiveField(2)
  final Map<String, String> options; 

  @HiveField(3)
  final String answer;

  @HiveField(4)
  final String difficulty;

  QuizQuestionHive({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.difficulty,
  });

  factory QuizQuestionHive.fromQuizQuestion(
    QuizQuestion q, {
    String difficulty = 'medium',
  }) {
    return QuizQuestionHive(
      id: q.getId,
      question: q.getQuestion,
      options: q.getOptions,
      answer: q.getAnswer,
      difficulty: difficulty,
    );
  }

  QuizQuestion toQuizQuestion() {
    return QuizQuestion(
      id: id,
      question: question,
      options: options,
      answer: answer,
    );
  }
}