// lib/providers/quiz_generator.dart
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:flutter_pomodoro/services/api_key_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class GeminiQuizService with ChangeNotifier {
  List<QuizQuestion> _questions = [];
  String? _lastAiResponse;

  List<QuizQuestion> get questions => _questions;
  String? get lastAiResponse => _lastAiResponse;

  Future<List<QuizQuestion>> generateQuizFromBytes(Uint8List pdfBytes) async {
    try {
      late String rawResponse;

      if (debug) {
        await Future.delayed(const Duration(seconds: 3));
        rawResponse = sample;
      } else {
        final storage = QuizStorageService();
        final difficultyString = storage.loadDifficulty();

        final difficulty = QuizDifficulty.values.firstWhere(
          (e) => e.name == difficultyString,
          orElse: () => QuizDifficulty.medium,
        );

        final prompt = buildQuizPrompt(difficulty);
        final resolvedKey = await ApiKeyService.getApiKey();

        if (resolvedKey == null || resolvedKey.isEmpty) {
          throw Exception(
            'No API key found. Please add your Gemini API key in Settings.',
          );
        }

        final String extractedText = await _extractTextFromBytes(pdfBytes);

        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: resolvedKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final response = await model.generateContent([
          Content.text('$prompt\n\nLearning Material:\n$extractedText'),
        ]);

        if (response.text == null) {
          throw Exception('AI returned empty response');
        }

        rawResponse = response.text!;

        if (kDebugMode) {
          print('Extracted text: $extractedText');
          print('AI response: $rawResponse');
        }
      }

      _lastAiResponse = rawResponse;

      final decoded = jsonDecode(rawResponse);
      if (decoded is! List) {
        throw Exception('AI response is not a JSON list of questions');
      }

      _questions = decoded
          .map((item) => QuizQuestion.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      notifyListeners();
      return _questions;
    } catch (e) {
      if (kDebugMode) print('Error generating quiz: $e');
      rethrow;
    }
  }

  void loadExistingQuestions(List<dynamic> jsonList) {
    _questions = jsonList
        .map((item) => QuizQuestion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    notifyListeners();
  }

  void clearQuestions() {
    _questions = [];
    _lastAiResponse = null;
    notifyListeners();
  }

  Future<String> _extractTextFromBytes(Uint8List bytes) async {
    if (kIsWeb) {
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      return text;
    }
    return await Isolate.run(() {
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      return text;
    });
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final Map<String, String> options;
  final String answer;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String, String>{};
    if (rawOptions is Map) {
      rawOptions.forEach((key, value) {
        options['$key'] = value?.toString() ?? '';
      });
    }
    return QuizQuestion(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      question: json['question']?.toString() ?? '',
      options: options,
      answer: json['answer']?.toString() ?? '',
    );
  }

  int get getId => id;
  String get getQuestion => question;
  Map<String, String> get getOptions => options;
  String get getAnswer => answer;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'answer': answer,
      };
}

class QuizAnswers {
  final int id;
  final QuizQuestion question;
  final String answer;

  QuizAnswers({required this.id, required this.question, required this.answer});

  int get getId => id;
  QuizQuestion get getQuestion => question;
  String get getAnswer => answer;
  bool get isCorrect => question.getAnswer == answer;
}