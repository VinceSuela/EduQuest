// lib/widgets/bottom_navigation.dart
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/widgets/my_quiz_dialog.dart';
import 'package:flutter_pomodoro/widgets/paint.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pomodoro/services/quiz_service.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import '../services/quiz_pdf_service.dart';

// Bottom Navigation with Generate, Start, and Review buttons
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
        clipBehavior: Clip.none,
        child: !hideBottomNav ? _renderButtons() : _renderBackButton(context),
      ),
    );
  }

  Widget _renderButtons() {
    return Transform.translate(
      offset: Offset.zero,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [GenerateQuiz(), StartLearning(), ReviewQuizes()],
      ),
    );
  }

  Widget _renderBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Visibility(
        visible: !hideBackButton,
        child: TextButton(
          style: ButtonStyle(overlayColor: WidgetStateColor.transparent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pushReplacementNamed(context, backUrl);
            }
          },
          child: const Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

// Review Quizes
class ReviewQuizes extends StatefulWidget {
  const ReviewQuizes({super.key});

  @override
  State<ReviewQuizes> createState() => _ReviewQuizesState();
}

class _ReviewQuizesState extends State<ReviewQuizes> {
  // Stream<QuerySnapshot>? _quizStream;
  // String? _lastUid;
  final List<DocumentSnapshot> _allDocs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Future<void>? _initialLoadFuture;
  static const int _pageSize = 20;

  // Stream<QuerySnapshot> _buildStream(String uid) {
  //   return FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(uid)
  //       .collection('generatedQuizzes')
  //       .orderBy('createdAt', descending: true)
  //       .limit(20)
  //       .snapshots();
  // }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () => _showQuizDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/review-button.png'),
        ),
      ),
    );
  }

  Future<void> _showQuizDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Build stream once per uid — reuse on subsequent dialog opens
    // if (user != null && _lastUid != user.uid) {
    //   _lastUid = user.uid;
    //   _quizStream = _buildStream(user.uid);
    // }

    
    if (_allDocs.isEmpty) {
      _initialLoadFuture = _loadFirst();
    }

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return MyQuizDialog(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(dialogContext),
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

              // List of quizzes or loading/error states
              Expanded(
                child: user == null
                    ? const Center(child: Text('Please log in to see quizzes'))
                    : FutureBuilder(
                        future: _initialLoadFuture,
                        builder: (context, _) =>
                            NotificationListener<ScrollNotification>(
                              onNotification: (scroll) {
                                if (scroll.metrics.pixels >=
                                    scroll.metrics.maxScrollExtent - 200) {
                                  if (!_isLoadingMore) {
                                    _loadMore();
                                  }
                                }
                                return false;
                              },
                              child: ListView.builder(
                                itemCount: _allDocs.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _allDocs.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final data =
                                      _allDocs[index].data()
                                          as Map<String, dynamic>;

                                  final fileName =
                                      data['fileName'] as String? ??
                                      'Untitled PDF';

                                  final pdfHash =
                                      data['pdfHash'] as String? ??
                                      _allDocs[index].id;

                                  final date = (data['createdAt'] as Timestamp?)
                                      ?.toDate();

                                  return GestureDetector(
                                    onLongPress: () => _showQuizOptions(
                                      context,
                                      _allDocs[index].id,
                                      pdfHash,
                                      data,
                                    ),
                                    onSecondaryTap: () => _showQuizOptions(
                                      context,
                                      _allDocs[index].id,
                                      pdfHash,
                                      data,
                                    ),
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
                                            ? '${date.day}/${date.month}/${date.year}'
                                            : 'Just now',
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                      onTap: () => _onQuizTap(
                                        context,
                                        dialogContext,
                                        _allDocs[index].id,
                                        pdfHash,
                                        fileName,
                                        data,
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
        );
      },
    );
  }

  Future<void> _loadFirst() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('generatedQuizzes')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .get();

    setState(() {
      _allDocs
        ..clear()
        ..addAll(snap.docs);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _pageSize;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingMore = true);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('generatedQuizzes')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_pageSize)
        .get();

    setState(() {
      _allDocs.addAll(snap.docs);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  // Handles tapping a quiz item.
  Future<void> _onQuizTap(
    BuildContext context,
    BuildContext dialogContext,
    String docId,
    String pdfHash,
    String fileName,
    Map<String, dynamic> data,
  ) async {
    final navContext = NavigationService.navigatorKey.currentContext!;
    final quizService = Provider.of<GeminiQuizService>(context, listen: false);
    final myFileProvider = Provider.of<MyFile>(navContext, listen: false);
    final storage = QuizStorageService();

    quizService.clearQuestions();

    // Try Hive cache first (zero network cost)
    final cachedQuestions = storage.getCachedQuestions(pdfHash);
    if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
      quizService.loadExistingQuestions(cachedQuestions);
      myFileProvider.reset();
      myFileProvider.setReviewMode(true);
      _loadPdfBytesLazily(myFileProvider, pdfHash, fileName, data);
      Navigator.pop(dialogContext);
      Navigator.of(navContext).pushReplacementNamed('/pdfViewer');
      return;
    }

    // Questions already in the snapshot doc
    final questionsData = data['questions'] as List<dynamic>?;
    if (questionsData != null && questionsData.isNotEmpty) {
      quizService.loadExistingQuestions(questionsData);
      // Save to Hive so next open skips even this step
      await storage.cacheQuestions(pdfHash, questionsData);
    }

    // Load PDF bytes for the viewer
    final blob = data['pdf'] as Blob?;
    if (blob != null) {
      final pdfBytes = Uint8List.fromList(blob.bytes.toList());
      myFileProvider.reset();
      myFileProvider.setReviewMode(true);
      myFileProvider.setFileFromBytes(pdfBytes, fileName);
      Navigator.pop(dialogContext);
      Navigator.of(navContext).pushReplacementNamed('/pdfViewer');
    } else if (questionsData != null) {
      // Questions loaded but no PDF blob — go straight to quiz
      Navigator.pop(dialogContext);
      Navigator.of(navContext).pushReplacementNamed('/quiz');
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load this quiz. The data may be missing.'),
          ),
        );
      }
    }
  }

  /// Loads PDF blob from Firestore in the background after navigating.
  /// This way the user sees the PDF viewer immediately with a loading state
  /// rather than waiting for the blob before navigation.
  void _loadPdfBytesLazily(
    MyFile myFileProvider,
    String pdfHash,
    String fileName,
    Map<String, dynamic> data,
  ) {
    final blob = data['pdf'] as Blob?;
    if (blob != null) {
      final pdfBytes = Uint8List.fromList(blob.bytes.toList());
      myFileProvider.setFileFromBytes(pdfBytes, fileName);
    }
    // If blob isn't in the snapshot, it means we only loaded metadata.
    // In that case, fetch the full doc separately.
    // This is a future enhancement when you split blob into a sub-document.
  }
}

// Generate Quiz
class GenerateQuiz extends StatelessWidget {
  const GenerateQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            withData: true,
          );

          if (result != null) {
            if (!context.mounted) return;
            final file = result.files.single;
            final navContext = NavigationService.navigatorKey.currentContext!;
            final myFileProvider = Provider.of<MyFile>(
              navContext,
              listen: false,
            );
            myFileProvider.setReviewMode(false);
            myFileProvider.setFile(file, file.name);
            await generateQuizFromPdf(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/generate-button.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// Start Learning
class StartLearning extends StatelessWidget {
  const StartLearning({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 8,
      child: GestureDetector(
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            withData: true,
          );

          if (result != null) {
            if (!context.mounted) return;
            final file = result.files.single;
            final navContext = NavigationService.navigatorKey.currentContext!;
            final myFileProvider = Provider.of<MyFile>(
              navContext,
              listen: false,
            );
            myFileProvider.setReviewMode(false);
            myFileProvider.setFile(file, file.name);
            Navigator.of(navContext).pushReplacementNamed('/pdfViewer');
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

// Quiz Options Bottom Sheet
void _showQuizOptions(
  BuildContext context,
  String docId,
  String pdfHash,
  Map<String, dynamic> data,
) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download Quiz PDF'),
            onTap: () async {
              Navigator.pop(context);
              final questionsData = data['questions'] as List<dynamic>?;
              if (questionsData == null) return;
              final questions = questionsData
                  .map(
                    (q) => QuizQuestion(
                      id: q['id'] is int
                          ? q['id']
                          : int.parse(q['id'].toString()),
                      question: q['question']?.toString() ?? '',
                      options: Map<String, String>.from(q['options'] ?? {}),
                      answer: q['answer']?.toString() ?? '',
                    ),
                  )
                  .toList();
              await QuizPdfService.exportQuiz(
                fileName: data['fileName'] ?? 'Quiz',
                questions: questions,
              );
            },
          ),

          // Delete
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
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
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

                  // Also remove from local Hive cache
                  await QuizStorageService().removeCachedQuestions(pdfHash);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quiz deleted')),
                    );
                  }
                }
              }
            },
          ),

          // Cancel
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
