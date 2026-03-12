import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
const String sample = '''
[
{
"id": 1,
"question": "What is the primary persona assigned to the AI for this task?",
"options": {
"A": "Curriculum Designer",
"B": "Educational Content Creator",
"C": "Academic Researcher",
"D": "Technical Instructor"
},
"answer": "B"
},
{
"id": 2,
"question": "According to the 'Topic Adaptation' rule, what is the required scope of the quiz questions?",
"options": {
"A": "Only basic facts",
"B": "Only conceptual understanding",
"C": "Ranging from basic facts to conceptual understanding",
"D": "Primarily advanced theoretical applications"
},
"answer": "C"
},
{
"id": 3,
"question": "Which output format is strictly mandated by the instructions?",
"options": {
"A": "A Markdown document",
"B": "A comma-separated values (CSV) list",
"C": "A valid JSON array",
"D": "A plain text conversational response"
},
"answer": "C"
},
{
"id": 4,
"question": "What is the specified range for the number of questions to be generated?",
"options": {
"A": "5 to 20",
"B": "10 to 40",
"C": "20 to 50",
"D": "Exactly 30"
},
"answer": "B"
},
{
"id": 5,
"question": "In the provided JSON schema, what is the expected data type for the 'id' field?",
"options": {
"A": "string",
"B": "float",
"C": "integer",
"D": "boolean"
},
"answer": "C"
},
{
"id": 6,
"question": "What is the requirement for 'distractors' (wrong answers) in the quiz?",
"options": {
"A": "They must be obviously false to avoid confusion.",
"B": "They must be plausible based on the context of the document.",
"C": "They should be taken from unrelated subject matters.",
"D": "They must always include 'All of the above'."
},
"answer": "B"
},
{
"id": 7,
"question": "What is the specific rule regarding conversational text in the final output?",
"options": {
"A": "Include a brief introduction and conclusion.",
"B": "Conversational text is allowed only in the 'question' field.",
"C": "Output ONLY a valid JSON array; no conversational text.",
"D": "Provide a summary of the analysis before the JSON."
},
"answer": "C"
},
{
"id": 8,
"question": "How are the multiple-choice options structured within each JSON object in the schema?",
"options": {
"A": "As a simple array of four strings",
"B": "As a nested object with keys 'A', 'B', 'C', and 'D'",
"C": "As a single string separated by commas",
"D": "As four separate root-level fields"
},
"answer": "B"
},
{
"id": 9,
"question": "Which field in the JSON schema indicates the correct choice for the question?",
"options": {
"A": "correct_option",
"B": "solution",
"C": "answer",
"D": "key"
},
"answer": "C"
},
{
"id": 10,
"question": "Which of the following subjects is explicitly listed as an example in the 'Topic Adaptation' rule?",
"options": {
"A": "Physics",
"B": "Biology",
"C": "Philosophy",
"D": "Economics"
},
"answer": "B"
}
]
''';

class GeminiQuizService with ChangeNotifier {
  String apiKey = "";
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
      }
      // print(extractedText);
      // print(response.text!);
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
