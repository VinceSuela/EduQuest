// lib/services/quiz_service.dart
import 'dart:developer';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/models/quiz_question.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

Future<String> generatePdfHashAsync(Uint8List bytes) async {
  if (kIsWeb) {
    return sha256.convert(bytes).toString();
  }
  return await compute(_hashBytes, bytes);
}

String _hashBytes(Uint8List bytes) => sha256.convert(bytes).toString();

// Main entry point — call this from any widget to generate or load a quiz.
Future<void> generateQuizFromPdf(BuildContext context) async {
  final myFile = Provider.of<MyFile>(context, listen: false);
  final quizService = Provider.of<GeminiQuizService>(context, listen: false);
  final currentUser = FirebaseAuth.instance.currentUser;
  final navContext = NavigationService.navigatorKey.currentContext!;

  if (currentUser == null) {
    _showErrorDialog(navContext,
      title: 'Not Logged In',
      message: 'Please log in to your account before generating a quiz.',
    );
    return;
  }

  if (myFile.bytes.isEmpty) {
    _showErrorDialog(navContext,
      title: 'No PDF Loaded',
      message: 'The PDF could not be read. Please go back and re-open the file.',
    );
    return;
  }

  final Uint8List safeBytes = Uint8List.fromList(myFile.bytes.toList());
  final String fileName = myFile.name;
  final String uid = currentUser.uid;

  // Always clear stale questions before any quiz flow
  quizService.clearQuestions();

  _showLoadingDialog(navContext);

  try {
    final pdfHash = await generatePdfHashAsync(safeBytes);
    final storage = QuizStorageService();

    // ── Step 2a: Check HIVE first (fastest, no network) ──────────────────
    final cachedQuestions = storage.getCachedQuestions(pdfHash);

    if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
      quizService.loadExistingQuestions(cachedQuestions);
      _dismissLoading(navContext);
      Navigator.pushReplacementNamed(navContext, '/quiz');
      return; // done — never touched Firestore
    }

    // ── Step 2b: Check Firestore (slower, network required) ──────────────
    DocumentSnapshot? existingDoc;
    try {
      existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('generatedQuizzes')
          .doc(pdfHash)
          .get();
    } catch (e) {
      log('Firestore cache read failed: $e');
      existingDoc = null;
    }

    if (existingDoc != null && existingDoc.exists) {
      final data = existingDoc.data() as Map<String, dynamic>?;
      final questionsData = data?['questions'] as List<dynamic>?;

      if (questionsData != null && questionsData.isNotEmpty) {
        quizService.loadExistingQuestions(questionsData);
        // Save to Hive so next time skips Firestore entirely
        await storage.cacheQuestions(pdfHash, questionsData);
        _dismissLoading(navContext);
        Navigator.pushReplacementNamed(navContext, '/quiz');
        return;
      }
    }

    // Step 3: Cache miss — generate via Gemini AI
    List<QuizQuestion> questions;
    try {
      questions = await quizService.generateQuizFromBytes(safeBytes);
    } catch (e) {
      _dismissLoading(navContext);
      _showErrorDialog(navContext,
        title: 'Quiz Generation Failed',
        message: _friendlyAiError(e.toString()),
      );
      return;
    }

    if (questions.isEmpty) {
      _dismissLoading(navContext);
      _showErrorDialog(navContext,
        title: 'No Questions Generated',
        message:
            'The AI was unable to generate quiz questions from this document. '
            'Try using a PDF with more readable text content.',
      );
      return;
    }

    // Step 4: Save to Firestore for future caching
    try {
      await _persistQuizData(
        uid:        uid,
        userEmail:  currentUser.email,
        pdfBytes:   safeBytes,
        fileName:   fileName,
        questions:  questions,
        aiResponse: quizService.lastAiResponse ?? '',
        pdfHash:    pdfHash,
      );
      await storage.cacheQuestions(
        pdfHash,
        questions.map((q) => q.toJson()).toList(),
      );
    } catch (e) {
      // Firestore save failed — still let the user take the quiz.
      // It just won't be cached for next time.
      log('Firestore save failed (non-fatal): $e');
    }

    _dismissLoading(navContext);
    Navigator.pushReplacementNamed(navContext, '/quiz');

  } catch (e, stack) {
    log('Quiz Workflow Error: $e', stackTrace: stack);
    _dismissLoading(navContext);
    _showErrorDialog(navContext,
      title: 'Something Went Wrong',
      message: _friendlyAiError(e.toString()),
    );
  }
}

// Persist to Firestore

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
    'fileName':   fileName,
    'userEmail':  userEmail ?? 'Anonymous',
    'createdAt':  FieldValue.serverTimestamp(),
    'aiResponse': aiResponse,
    'questions':  questions.map((q) => q.toJson()).toList(),
    'pdfSize':    pdfBytes.length,
    'pdf':        pdfBytes.isNotEmpty ? Blob(pdfBytes) : null,
    'pdfHash':    pdfHash,
  });
}

// Error message translation

// Converts raw exception strings into messages students can actually act on.
String _friendlyAiError(String raw) {
  final lower = raw.toLowerCase();

  if (lower.contains('no api key') || lower.contains('api key')) {
    return 'No Gemini API key found. Please go to Settings and add your API key '
        'from Google AI Studio (aistudio.google.com).';
  }
  if (lower.contains('429') || lower.contains('quota') || lower.contains('rate limit')) {
    return 'The AI is currently receiving too many requests. '
        'Please wait 1–2 minutes and try again.';
  }
  if (lower.contains('503') || lower.contains('unavailable') || lower.contains('overloaded')) {
    return 'The AI service is temporarily unavailable due to high traffic. '
        'Please try again in a few minutes.';
  }
  if (lower.contains('400') || lower.contains('invalid') || lower.contains('bad request')) {
    return 'The AI could not process this document. '
        'Make sure your PDF contains readable text (not just scanned images).';
  }
  if (lower.contains('401') || lower.contains('403') || lower.contains('unauthorized') || lower.contains('permission')) {
    return 'Your API key appears to be invalid or expired. '
        'Please update it in Settings.';
  }
  if (lower.contains('network') || lower.contains('socket') || lower.contains('connection') || lower.contains('timeout')) {
    return 'Could not connect to the AI service. '
        'Please check your internet connection and try again.';
  }
  if (lower.contains('empty response') || lower.contains('null')) {
    return 'The AI returned an empty response. '
        'This sometimes happens with very short or image-only PDFs. '
        'Try a different document.';
  }
  if (lower.contains('not a json') || lower.contains('json')) {
    return 'The AI returned an unexpected response format. '
        'Please try again — this usually resolves on its own.';
  }
  if (lower.contains('pdf not loaded') || lower.contains('bytes')) {
    return 'The PDF could not be read. Please go back and re-open the file.';
  }

  // Fallback - generic but actionable
  return 'Something went wrong while generating your quiz. '
      'Please check your internet connection and try again. '
      'If the problem persists, try reopening the PDF.';
}

// UI helpers

bool _isLoadingShowing = false;

void _showLoadingDialog(BuildContext context) {
  if (_isLoadingShowing) return;
  _isLoadingShowing = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating your quiz...'),
            ],
          ),
        ),
      ),
    ),
  );
}

void _dismissLoading(BuildContext context) {
  if (!_isLoadingShowing) return;
  _isLoadingShowing = false;
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
}

void _showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Flexible(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}