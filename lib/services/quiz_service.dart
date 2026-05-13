// lib/services/quiz_service.dart
import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/models/quiz_question.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generatePdfHash(Uint8List bytes) {
  // No Uint8List.fromList copy here — caller already holds a safe defensive copy
  return sha256.convert(bytes).toString();
}

Future<String> generatePdfHashAsync(Uint8List bytes) async {
  return await Isolate.run(() => sha256.convert(bytes).toString());
}

Future<void> generateQuizFromPdf(BuildContext context) async {
  final myFile      = Provider.of<MyFile>(context, listen: false);
  final quizService = Provider.of<GeminiQuizService>(context, listen: false);
  final currentUser = FirebaseAuth.instance.currentUser;
  final navContext  = NavigationService.navigatorKey.currentContext!;

  if (currentUser == null) {
    _showErrorSnackBar(navContext, "Please login first.");
    return;
  }

  // Always clear stale questions before any quiz flow
  quizService.clearQuestions();

  _showLoadingDialog(context);

  try {
    final uid     = currentUser.uid;
    final pdfHash = await generatePdfHashAsync(myFile.bytes);

    // ── Cache check: direct doc lookup by pdfHash (no query, no index needed) ──
    final existing = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('generatedQuizzes')
        .doc(pdfHash)
        .get();

    if (existing.exists) {
      final data         = existing.data()!;
      final questionsData = data['questions'] as List<dynamic>?;

      if (questionsData != null && questionsData.isNotEmpty) {
        // Cache hit — load questions, skip AI
        quizService.loadExistingQuestions(questionsData);
        if (context.mounted) Navigator.pop(context);
        Navigator.pushNamed(navContext, '/quiz');
        return;
      }
    }

    // Cache miss — generate new quiz via AI
    final questions = await quizService.generateQuizFromBytes(myFile.bytes);

    if (questions.isEmpty) {
      throw Exception("Quiz generation failed — AI returned no questions.");
    }

    // Persist to Firestore — pdfHash is the doc ID (prevents duplicates)
    // Blob is always stored so Review mode can load the PDF on any device
    await _persistQuizData(
      uid:        uid,
      userEmail:  currentUser.email,
      pdfBytes:   myFile.bytes,
      fileName:   myFile.name,
      questions:  questions,
      aiResponse: quizService.lastAiResponse ?? '',
      pdfHash:    pdfHash,
    );

    if (context.mounted) Navigator.pop(context);
    Navigator.pushReplacementNamed(navContext, '/quiz');
  } catch (e, stack) {
    log("Quiz Workflow Error: $e", stackTrace: stack);
    if (context.mounted) Navigator.pop(context);
    _showErrorSnackBar(
      navContext,
      "Failed to generate quiz. Please try again in a moment.",
    );
  }
}

Future<void> _persistQuizData({
  required String uid,
  required String? userEmail,
  required Uint8List pdfBytes,
  required String fileName,
  required List<QuizQuestion> questions,
  required String aiResponse,
  required String pdfHash,
}) async {
  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('generatedQuizzes')
      .doc(pdfHash);

  await docRef.set({
    'fileName':  fileName,
    'userEmail': userEmail ?? 'Anonymous',
    'createdAt': FieldValue.serverTimestamp(),
    'aiResponse': aiResponse,
    'questions': questions.map((q) => q.toJson()).toList(),
    'pdfSize':   pdfBytes.length,
    'pdf':       pdfBytes.isNotEmpty ? Blob(pdfBytes) : null,
    'pdfHash':   pdfHash,
  });
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
    SnackBar(
      content: Text("Error: $message"),
      backgroundColor: Colors.redAccent,
    ),
  );
}