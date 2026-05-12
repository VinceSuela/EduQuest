// lib/quiz_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/models/quiz_question.dart';
import 'package:flutter_pomodoro/models/quiz_session.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/services/quiz_service.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_quiz_dialog.dart';
import 'package:provider/provider.dart';

class MyQuiz extends StatefulWidget {
  const MyQuiz({super.key});

  @override
  State<MyQuiz> createState() => _MyQuizState();
}

class _MyQuizState extends State<MyQuiz> {
  bool showScore = false;
  bool _sessionSaved = false;
  int questionIndex = 0;
  List<QuizAnswers> answers = [];
  BuildContext navContext = NavigationService.navigatorKey.currentContext!;
  late List<QuizQuestion> questions;

  QuizQuestion get getQuizQuestion =>
      questions[questionIndex % questions.length];

  Map<String, String> getOptions() {
    final Random random = Random();
    final Map<String, String> questionOptions = {...getQuizQuestion.getOptions};
    final Map<String, String> randomQuestionOptions = {};
    final int loop = questionOptions.length;

    for (var i = 0; i < loop; i++) {
      final int nextInt = random.nextInt(questionOptions.length);
      final MapEntry<String, String> randomQuestionOption =
          questionOptions.entries.elementAt(nextInt);
      questionOptions.removeWhere((k, v) => randomQuestionOption.key == k);
      randomQuestionOptions.addEntries([randomQuestionOption]);
    }

    return randomQuestionOptions;
  }

  void setAnswer(String key) {
    final QuizQuestion question =
        questions[questionIndex % questions.length];
    answers.add(QuizAnswers(id: question.getId, question: question, answer: key));

    setState(() {
      if (questionIndex >= questions.length - 1) {
        showScore = true;
        _saveSessionOnce();
      } else {
        questionIndex++;
      }
    });
  }

  int getScores() =>
      answers.where((a) => a.isCorrect).length;

  // Save the quiz session to local storage, ensuring it's only saved once per completion.
  void _saveSessionOnce() {
    if (_sessionSaved) return;
    _sessionSaved = true;

    final myFile = Provider.of<MyFile>(navContext, listen: false);

    // Convert answers to the key list QuizSession expects
    final userAnswerKeys = answers.map((a) => a.getAnswer).toList();

    // Convert QuizQuestion → QuizQuestionHive
    final hiveQuestions = questions
        .map((q) => QuizQuestionHive.fromQuizQuestion(q, difficulty: 'medium'))
        .toList();

    final session = QuizSession.create(
      sourceFileName: myFile.name,
      questions: hiveQuestions,
      userAnswerKeys: userAnswerKeys,
      difficulty: 'medium',
    );

    final pdfHash = myFile.currentHash;

    QuizStorageService().saveSession(session, pdfHash: pdfHash);
  }

  @override
  void initState() {
    questions = [...Provider.of<GeminiQuizService>(navContext).questions];
    questions.shuffle();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyLayout(
      title: '',
      backUrl: '/pdfViewer',
      hideHeader: true,
      hideSideNav: true,
      child: MyQuizDialog(
        child: showScore ? renderResult(context) : renderQuiz(context),
      ),
    );
  }

  // Result screen with score and breakdown
  Column renderResult(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Card.filled(
                elevation: 8,
                color: Colors.cyan[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Your Score',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${getScores()} / ${questions.length}',
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(getScores() / questions.length * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          color: getScores() / questions.length >= 0.7
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Card.filled(
                  color: const Color(0xFF888888),
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    child: ListView.builder(
                      itemCount: answers.length,
                      itemBuilder: (BuildContext context, index) {
                        final QuizAnswers answer = answers[index];
                        final String answerKey  = answer.getAnswer;
                        final String correctKey = answer.getQuestion.getAnswer;
                        final bool isCorrect    = answer.isCorrect;

                        return Card(
                          color: isCorrect ? Colors.green[50] : Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  answer.getQuestion.getQuestion,
                                  textAlign: TextAlign.center,
                                ),
                                const Divider(),
                                Column(
                                  children: [
                                    Text(
                                      isCorrect
                                          ? 'Your answer is correct ✓'
                                          : 'Your answer is',
                                      textAlign: TextAlign.start,
                                    ),
                                    Text(
                                      answer.getQuestion.getOptions[answerKey]
                                              .toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isCorrect
                                            ? Colors.green[900]
                                            : Colors.red[900],
                                      ),
                                    ),
                                  ],
                                ),
                                Visibility(
                                  visible: !isCorrect,
                                  child: Column(
                                    children: [
                                      const Text('Correct answer is'),
                                      Text(
                                        answer.getQuestion.getOptions[correctKey]
                                                .toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.green[900]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        MyButton(
          label: 'Restart',
          isActive: false,
          onPressed: () {
            questions.shuffle();
            setState(() {
              questionIndex  = 0;
              answers        = [];
              showScore      = false;
              _sessionSaved  = false;
            });
          },
        ),
      ],
    );
  }

// Quiz screen with question and options
  Column renderQuiz(BuildContext context) {
    final Map<String, String> randomQuestionOptions = getOptions();
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                getQuizQuestion.getQuestion,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
                childAspectRatio: 1.25,
              ),
              itemCount: randomQuestionOptions.length,
              itemBuilder: (BuildContext context, index) {
                final String buttonKey =
                    randomQuestionOptions.keys.elementAt(index);
                final String buttonLabel =
                    randomQuestionOptions.values.elementAt(index);
                return GestureDetector(
                  onTap: () => setAnswer(buttonKey),
                  child: Card.filled(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          buttonLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}