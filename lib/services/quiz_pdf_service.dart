import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter_pomodoro/providers/quiz_generator.dart';

class QuizPdfService {
  static Future<void> exportQuiz({
    required String fileName,
    required List<QuizQuestion> questions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Quiz from $fileName',
            style: pw.TextStyle(fontSize: 24),
          ),

          pw.SizedBox(height: 20),

          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                pw.Text(
                  '${index + 1}. ${q.getQuestion}',
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.SizedBox(height: 5),

                ...q.getOptions.entries.map((option) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(
                      left: 12,
                      bottom: 3,
                    ),
                    child: pw.Text(
                      '${option.key}. ${option.value}',
                    ),
                  );
                }),

                pw.SizedBox(height: 12),
              ],
            );
          }),

          pw.SizedBox(height: 25),

          pw.Text(
            'Answer Key',
            style: pw.TextStyle(fontSize: 18),
          ),

          pw.SizedBox(height: 10),

          ...questions.asMap().entries.map((entry) {
            return pw.Text(
              '${entry.key + 1}. ${entry.value.getAnswer}',
            );
          }),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${fileName}_quiz.pdf',
    );
  }
}