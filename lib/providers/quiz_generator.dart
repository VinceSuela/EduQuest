import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiQuizService {
  Future<List<QuizQuestion>> generateQuizFromBytes(Uint8List pdfBytes) async {
    try {
      const apiKey = "AIzaSyAFjCOFZiZ5B57RXeXyViQ82V64g8QOSGo";

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

              Quantity: Generate 10 up to 40 questions depending on the quantity of the content.      
          Learning Material:
          $extractedText
        '''),
      ];

      final response = await model.generateContent(prompt);
      if (response.text == null) throw Exception("AI returned empty response");

      final List<dynamic> decodedList = jsonDecode(response.text!);
      return decodedList.map((json) => QuizQuestion.fromJson(json)).toList();
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
}
