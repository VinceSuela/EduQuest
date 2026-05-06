import 'dart:developer';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';

Future<void> _persistQuizData({
  required String uid,
  required String? userEmail,
  required Uint8List pdfBytes,
  required String fileName,
  required List<QuizQuestion> questions,
  required String aiResponse,
}) async {
  final userQuizRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('generatedQuizzes');

  final quizData = {
    'fileName': fileName,
    'userEmail': userEmail ?? 'Anonymous',
    'createdAt': FieldValue.serverTimestamp(),
    'aiResponse': aiResponse,
    'questions': questions.map((q) => q.toJson()).toList(),
    'pdfSize': pdfBytes.length,
    'pdf': pdfBytes.isNotEmpty ? Blob(pdfBytes) : null, 
  };

  await userQuizRef.add(quizData);
}

Future<void> generateQuizFromPdf(BuildContext context) async {
  final myFile = Provider.of<MyFile>(context, listen: false);
  final quizService = Provider.of<GeminiQuizService>(context, listen: false);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  final navContext = NavigationService.navigatorKey.currentContext!;

  if (myFile.isReviewMode) {
    log("Review mode detected. Skipping generation and saving.");
    Navigator.pushReplacementNamed(navContext, '/quiz');
    return;
  }

  _showLoadingDialog(context); 

  try {
    final questions = await quizService.generateQuizFromBytes(myFile.bytes);
    final rawAiResponse = quizService.lastAiResponse ?? '';
    final sanitizedFileName = myFile.name.trim().isEmpty ? 'untitled_quiz.pdf' : myFile.name;
    final uid = currentUser?.uid;

    if (uid != null) {
      await _persistQuizData(
        uid: uid,
        userEmail: currentUser?.email,
        pdfBytes: myFile.bytes,
        fileName: sanitizedFileName,
        questions: questions,
        aiResponse: rawAiResponse,
      );
    } else {
      log("Warning: Quiz generated but not saved (User not authenticated).");
    }
    if (context.mounted) Navigator.pop(context);
    Navigator.pushReplacementNamed(navContext, '/quiz');

  } catch (e, stack) {
    log("Quiz Workflow Error: $e", stackTrace: stack);
    if (context.mounted) Navigator.pop(context); 
    
    _showErrorSnackBar(navContext, e.toString());
  }
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: $message"), backgroundColor: Colors.redAccent),
  );
}