import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiQuizService with ChangeNotifier {
  List<QuizQuestion> _questions = List.empty();
  String? _lastAiResponse;

  List<QuizQuestion> get questions => _questions;
  String? get lastAiResponse => _lastAiResponse;

  Future<List<QuizQuestion>> generateQuizFromBytes(Uint8List pdfBytes) async {
    if (_questions.isNotEmpty) {
      return _questions;
    }

    try {
      late String rawResponse;

      if (debug) {
        await Future.delayed(const Duration(seconds: 3));
        rawResponse = sample;
      } else {
        final String extractedText = await _extractTextFromBytes(pdfBytes);

        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final aiPrompt = [
          Content.text('''
          $prompt   
          Learning Material:
          $extractedText
        '''),
        ];

        final response = await model.generateContent(aiPrompt);
        if (response.text == null) {
          throw Exception("AI returned empty response");
        }

        rawResponse = response.text!;
        if (kDebugMode) {
          print(extractedText);
          print(rawResponse);
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
      if (kDebugMode) {
        print("Error generating quiz: $e");
      }
      rethrow;
    }
  }

  Future<String> _extractTextFromBytes(Uint8List bytes) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  void loadExistingQuestions(List<dynamic> jsonList) {
    _questions = jsonList
        .map((item) => QuizQuestion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    notifyListeners();
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'answer': answer,
    };
  }
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
