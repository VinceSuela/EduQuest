import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/widgets/my_quiz_dialog.dart';
import 'package:flutter_pomodoro/widgets/paint.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pomodoro/services/quiz_service.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import '../services/quiz_pdf_service.dart';
import 'dart:typed_data';

class BottomNavigation extends StatelessWidget {
  final bool hideBottomNav;
  final bool hideBackButton;
  final String backUrl;

  const BottomNavigation({
    super.key,
    this.hideBottomNav = false,
    this.hideBackButton = false,
    this.backUrl = '/home',
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NavPainter(),
      child: Container(
        height: !hideBottomNav ? 100 : 60,
        clipBehavior: .none,
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage('assets/images/bottom-bar.png'),
        //     fit: .cover,
        //     alignment: .topCenter,
        //   ),
        // ),
        child: !hideBottomNav ? renderButtons() : renderBackButton(context),
        //SizedBox(width: .infinity),
      ),
    );
  }

  Transform renderButtons() {
    return Transform.translate(
      offset: Offset(0, 0),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        crossAxisAlignment: .end,
        children: [GenerateQuiz(), StartLearning(), ReviewQuizes()],
      ),
    );
  }

  Widget renderBackButton(BuildContext context) {
    return SizedBox(
      width: .infinity,
      child: Visibility(
        visible: !hideBackButton,
        child: TextButton(
          style: ButtonStyle(overlayColor: WidgetStateColor.transparent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pushReplacementNamed(context, backUrl);
            }
          },
          child: Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class ReviewQuizes extends StatefulWidget {
  const ReviewQuizes({super.key});

  @override
  State<ReviewQuizes> createState() => _ReviewQuizesState();
}

class _ReviewQuizesState extends State<ReviewQuizes> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () {
          showQuiz(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/review-button.png'),
        ),
      ),
    );
  }

  Future<void> showQuiz(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return MyQuizDialog(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        // This pops the Dialog specifically
                        Navigator.pop(dialogContext);
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48.0),
                          child: Text(
                            'My Quizzes',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: user == null
                    ? const Center(child: Text("Please log in to see quizzes"))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('generatedQuizzes')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError)
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          if (docs.isEmpty) {
                            return const Center(
                              child: Text("No quizzes generated yet."),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final fileName =
                                  data['fileName'] ?? 'Untitled PDF';
                              final date = (data['createdAt'] as Timestamp?)
                                  ?.toDate();

                              return GestureDetector(
                                onLongPress: () {
                                  _showQuizOptions(
                                    context,
                                    docs[index].id,
                                    data,
                                  );
                                },
                                onSecondaryTap: () {
                                  _showQuizOptions(
                                    context,
                                    docs[index].id,
                                    data,
                                  );
                                },
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.redAccent,
                                  ),
                                  title: Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    date != null
                                        ? "${date.day}/${date.month}/${date.year}"
                                        : "Just now",
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () async {
                                    final data =
                                        docs[index].data()
                                            as Map<String, dynamic>;
                                    final blob = data['pdf'] as Blob?;
                                    final fileName =
                                        data['fileName'] ?? 'Untitled.pdf';
                                    final questionsData =
                                        data['questions'] as List<dynamic>?;

                                    if (questionsData != null) {
                                      final quizService =
                                          Provider.of<GeminiQuizService>(
                                            context,
                                            listen: false,
                                          );
                                      quizService.clearQuestions();
                                      quizService.loadExistingQuestions(
                                        questionsData,
                                      );
                                    }

                                    if (blob != null) {
                                      Uint8List pdfBytes = blob.bytes;

                                      final navContext = NavigationService
                                          .navigatorKey
                                          .currentContext!;
                                      final myFileProvider =
                                          Provider.of<MyFile>(
                                            navContext,
                                            listen: false,
                                          );

                                      myFileProvider.reset();
                                      myFileProvider.setReviewMode(true);
                                      myFileProvider.setFileFromBytes(
                                        pdfBytes,
                                        fileName,
                                      );

                                      Navigator.pop(dialogContext);
                                      Navigator.of(
                                        navContext,
                                      ).pushReplacementNamed('/pdfViewer');
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Error: PDF data not found in this save.",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GenerateQuiz extends StatefulWidget {
  const GenerateQuiz({super.key});

  @override
  State<GenerateQuiz> createState() => _GenerateQuizState();
}

class _GenerateQuizState extends State<GenerateQuiz> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            withData: true,
          );

          if (result != null) {
            if (!context.mounted) return;
            PlatformFile file = result.files.single;
            final navContext = NavigationService.navigatorKey.currentContext!;
            final myFileProvider = Provider.of<MyFile>(
              navContext,
              listen: false,
            );
            myFileProvider.setReviewMode(false);
            myFileProvider.setFile(file, result.files.single.name);
            await generateQuizFromPdf(context);
          } else {
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/generate-button.png',
            fit: .contain,
          ),
        ),
      ),
    );
  }
}

class StartLearning extends StatefulWidget {
  const StartLearning({super.key});

  @override
  State<StartLearning> createState() => _StartLearningState();
}

class _StartLearningState extends State<StartLearning> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 8,
      child: GestureDetector(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            withData: true,
          );

          if (result != null) {
            if (!context.mounted) return;
            PlatformFile file = result.files.single;
            final navContext = NavigationService.navigatorKey.currentContext!;
            final myFileProvider = Provider.of<MyFile>(
              navContext,
              listen: false,
            );
            myFileProvider.setReviewMode(false);
            myFileProvider.setFile(file, result.files.single.name);
            Navigator.of(
              NavigationService.navigatorKey.currentContext!,
            ).pushReplacementNamed('/pdfViewer');
          } else {
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Image.asset('assets/images/start-button.png'),
        ),
      ),
    );
  }
}

void _showQuizOptions(
  BuildContext context,
  String docId,
  Map<String, dynamic> data,
) {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download Quiz PDF'),

              onTap: () async {
                Navigator.pop(context);

                final questionsData = data['questions'] as List<dynamic>?;

                if (questionsData == null) return;

                final questions = questionsData.map((q) {
                  return QuizQuestion(
                    id: q['id'],
                    question: q['question'],
                    options: Map<String, String>.from(q['options']),
                    answer: q['answer'],
                  );
                }).toList();

                await QuizPdfService.exportQuiz(
                  fileName: data['fileName'] ?? 'Quiz',
                  questions: questions,
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Quiz',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete quiz?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('generatedQuizzes')
                        .doc(docId)
                        .delete();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quiz deleted')),
                      );
                    }
                  }
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),

              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
