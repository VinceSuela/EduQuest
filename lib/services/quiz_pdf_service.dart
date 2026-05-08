// lib/services/quiz_pdf_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';

class QuizPdfService {
  static Future<void> exportQuiz({
    required String fileName,
    required List<QuizQuestion> questions,
  }) async {
    final regular = await PdfGoogleFonts.notoSerifRegular();
    final bold    = await PdfGoogleFonts.notoSerifBold();
    final italic  = await PdfGoogleFonts.notoSerifItalic();

    final titleStyle = pw.TextStyle(
      font: bold,
      fontSize: 20,
    );
    final sectionStyle = pw.TextStyle(
      font: bold,
      fontSize: 14,
      decoration: pw.TextDecoration.underline,
    );
    final questionStyle = pw.TextStyle(
      font: regular,
      fontSize: 12,
    );
    final optionStyle = pw.TextStyle(
      font: regular,
      fontSize: 11,
    );
    final answerKeyLabelStyle = pw.TextStyle(
      font: italic,
      fontSize: 11,
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 52),
        build: (context) => [
          pw.Text(
            'Quiz: ${fileName.split('.').first}',
            style: titleStyle,
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 16),

          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;

            final sortedOptions = q.getOptions.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${index + 1}. ${q.getQuestion}',
                  style: questionStyle,
                ),
                pw.SizedBox(height: 6),

                ...sortedOptions.map((option) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                    child: pw.Text(
                      '${option.key}.  ${option.value}',
                      style: optionStyle,
                    ),
                  );
                }),

                pw.SizedBox(height: 14),
              ],
            );
          }),

          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          pw.Text('Answer Key', style: sectionStyle),
          pw.SizedBox(height: 8),

          pw.Wrap(
            spacing: 24,
            runSpacing: 4,
            children: questions.asMap().entries.map((entry) {
              final q = entry.value;
              return pw.SizedBox(
                width: 180,
                child: pw.Text(
                  '${entry.key + 1}.  ${q.getAnswer}',
                  style: answerKeyLabelStyle,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${fileName.split('.').first}_quiz.pdf',
    );
  }
}