import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiQuizService with ChangeNotifier {
  List<QuizQuestion> _questions = List.empty();

  List<QuizQuestion> get questions => _questions;

  Future<List<QuizQuestion>> generateQuizFromBytes(
    Uint8List pdfBytes, {
    bool debug = true,
  }) async {
    List<dynamic> decodedList;
    try {
      if (debug) {
        await Future.delayed(const Duration(seconds: 3));
        decodedList = jsonDecode(sample);
      } else {
        final String extractedText = await _extractTextFromBytes(pdfBytes);

        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final prompt = [
          Content.text('''
          You are an Educational Content Creator. Your task is to analyze the provided document and generate a multiple-choice quiz that accurately reflects its specific subject matter.

          Rules:

              Topic Adaptation: Identify the main subject (e.g., Biology, History, Mathematics) and generate questions ranging from basic facts to conceptual understanding.

              JSON Format: Output ONLY a valid JSON array. No conversational text.

              Schema: > [
              {
              "id": integer,
              "question": "string",
              "options": {"A": "string", "B": "string", "C": "string", "D": "string"},
              "answer": "A, B, C, or D"
              }
              ]

              Quality: Ensure all distractors (wrong answers) are plausible based on the context of the document.

              Quantity: Generate 10 questions depending on the quantity of the content.      
          Learning Material:
          $extractedText
        '''),
        ];

        final response = await model.generateContent(prompt);
        if (response.text == null) {
          throw Exception("AI returned empty response");
        }

        decodedList = jsonDecode(response.text!);
        print(extractedText);
        print(response.text!);
      }

      _questions = decodedList
          .map((json) => QuizQuestion.fromJson(json))
          .toList();
      notifyListeners();
      return _questions;
    } catch (e) {
      print("Error generating quiz: $e");
      rethrow;
    }
  }

  Future<String> _extractTextFromBytes(Uint8List bytes) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
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
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: Map<String, String>.from(json['options']),
      answer: json['answer'],
    );
  }

  int get getId => id;
  String get getQuestion => question;
  Map<String, String> get getOptions => options;
  String get getAnswer => answer;
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
