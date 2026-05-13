import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';

class PeriodReportService {
  // 76 mm usable width inside an 80 mm roll (2 mm margin each side)
  static const double _mmToPt = PdfPageFormat.mm;
  static const double _pageWidth = 76 * _mmToPt;
  static const double _margin = 2 * _mmToPt;

  static Future<pw.Document> generate({
    required Period period,
    required List<Map<String, dynamic>> categoryRevenues,
  }) async {
    final fontData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final titleStyle = pw.TextStyle(
        font: font, fontSize: 13, fontWeight: pw.FontWeight.bold);
    final subStyle =
        pw.TextStyle(font: font, fontSize: 9);
    final headerStyle = pw.TextStyle(
        font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);
    final bodyStyle = pw.TextStyle(font: font, fontSize: 9);
    final totalStyle = pw.TextStyle(
        font: font, fontSize: 11, fontWeight: pw.FontWeight.bold);

    final startStr = DateFormat('yyyy/MM/dd – HH:mm')
        .format(period.startTimestamp.toLocal());
    final endStr = period.endTimestamp != null
        ? DateFormat('yyyy/MM/dd – HH:mm')
            .format(period.endTimestamp!.toLocal())
        : '–';

    final grandTotal = categoryRevenues.fold<double>(
        0.0, (sum, r) => sum + (r['revenue'] as double));

    // Estimate page height
    final estimatedH =
        (55 + categoryRevenues.length * 12.0 + 30) * _mmToPt;
    final pageFormat = PdfPageFormat(
      _pageWidth,
      estimatedH,
      marginAll: _margin,
    );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Center(
                child: pw.Text('تقرير نهاية الفترة', style: titleStyle),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child:
                    pw.Text('الفترة رقم ${period.id}', style: subStyle),
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('البداية: $startStr', style: subStyle),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('النهاية: $endStr', style: subStyle),
                ],
              ),
              pw.Divider(thickness: 0.7),
              pw.SizedBox(height: 2),
              // Category table
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                      width: 0.3, color: PdfColors.grey400),
                  top: pw.BorderSide(width: 0.5),
                  bottom: pw.BorderSide(width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),  // category (right)
                  1: const pw.FlexColumnWidth(2),  // total (left)
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200),
                    children: [
                      _cell('الفئة', headerStyle),
                      _cell('الإجمالي', headerStyle),
                    ],
                  ),
                  // Data rows
                  ...categoryRevenues.map((r) {
                    final revenue = r['revenue'] as double;
                    return pw.TableRow(children: [
                      _cell(r['categoryName'] as String, bodyStyle),
                      _cell(
                        '${revenue.toStringAsFixed(2)} ج.م',
                        bodyStyle,
                      ),
                    ]);
                  }),
                ],
              ),
              pw.Divider(thickness: 0.7),
              // Grand total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي الكلي:', style: totalStyle),
                  pw.Text(
                    '${grandTotal.toStringAsFixed(2)} ج.م',
                    style: totalStyle,
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text('** نهاية التقرير **', style: subStyle),
              ),
            ],
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _cell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.right),
    );
  }
}
