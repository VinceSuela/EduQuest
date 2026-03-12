import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
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
  int questionIndex = 0;
  List<QuizAnswers> answers = [];
  BuildContext navContext = NavigationService.navigatorKey.currentContext!;
  late List<QuizQuestion> questions;

  void setAnswer(String key) {
    final QuizQuestion question = questions[questionIndex % questions.length];
    QuizAnswers answer = QuizAnswers(
      id: questionIndex,
      question: question,
      answer: key,
    );
    answers.add(answer);
    setState(() {
      if (questionIndex >= questions.length - 1) {
        showScore = true;
      } else {
        questionIndex++;
      }
    });
  }

  int getScores() {
    int score = 0;
    for (QuizAnswers answer in answers) {
      if (answer.isCorrect) {
        score++;
      }
    }
    return score;
  }

  @override
  void initState() {
    questions = Provider.of<GeminiQuizService>(navContext).questions;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyLayout(
      title: '',
      hideHeader: true,
      hideSideNav: true,
      child: MyQuizDialog(
        child: showScore ? renderResult(context) : renderQuiz(context),
      ),
    );
  }

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
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .stretch,
                  children: [
                    Center(
                      child: Text(
                        'Your Score ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child: Text(
                        getScores().toString(),
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Card.filled(
                  color: Color(0xFF888888),
                  child: Card(
                    clipBehavior: .hardEdge,
                    child: ListView.builder(
                      itemCount: answers.length,
                      itemBuilder: (BuildContext context, index) {
                        QuizAnswers answer = answers[index];
                        String answerKey = answer.getAnswer;
                        String correctKey = answer.getQuestion.getAnswer;
                        bool isCorrect = answer.isCorrect;
                        // answer.getQuestion.getOptions[answerKey].toString();
                        return Card(
                          color: isCorrect ? Colors.green[50] : Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(answer.getQuestion.getQuestion),
                                Divider(),
                                Column(
                                  children: [
                                    Text(
                                      !isCorrect
                                          ? 'Your answer is'
                                          : 'Your answer is correct',
                                    ),

                                    Text.rich(
                                      textAlign: .center,
                                      style: TextStyle(
                                        color: isCorrect
                                            ? Colors.green[900]
                                            : Colors.red[900],
                                      ),
                                      TextSpan(
                                        text: answer
                                            .getQuestion
                                            .getOptions[answerKey]
                                            .toString(),
                                      ),
                                    ),
                                  ],
                                ),
                                Visibility(
                                  visible: !isCorrect,
                                  child: Column(
                                    children: [
                                      Text('Correct answer is '),
                                      Text.rich(
                                        textAlign: .center,
                                        style: TextStyle(
                                          color: Colors.green[900],
                                        ),
                                        TextSpan(
                                          text: answer
                                              .getQuestion
                                              .getOptions[correctKey]
                                              .toString(),
                                        ),
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
          label: 'restart',
          isActive: false,
          onPressed: () {
            setState(() {
              questionIndex = 0;
              answers = [];
              showScore = false;
            });
          },
        ),
      ],
    );
  }

  Column renderQuiz(BuildContext context) {
    final QuizQuestion question = questions[questionIndex % questions.length];
    final Map<String, String> questionOptions = question.getOptions;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  question.getQuestion,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: questionOptions.length,
            itemBuilder: (BuildContext context, index) {
              // optionItem = questionOptions.;
              String buttonKey = questionOptions.keys.elementAt(index);
              String buttonLabel = questionOptions.values.elementAt(index);
              return MyButton(
                label: buttonLabel,
                isActive: false,
                onPressed: () {
                  setAnswer(buttonKey);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
