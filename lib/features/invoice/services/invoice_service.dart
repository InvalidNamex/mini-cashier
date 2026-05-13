import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/database/app_database.dart';

class InvoiceService {
  // 76 mm usable width inside an 80 mm roll (2 mm margin each side)
  static const double _mmToPt = PdfPageFormat.mm;
  static const double _pageWidth = 76 * _mmToPt;
  static const double _margin = 2 * _mmToPt;

  static Future<pw.Document> generate({
    required Order order,
    required List<OrderItem> orderItems,
    required String cashierName,
  }) async {
    final fontData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final nameStyle =
        pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold);
    final detailStyle = pw.TextStyle(font: font, fontSize: 8);
    final noteStyle = pw.TextStyle(
        font: font, fontSize: 8, fontStyle: pw.FontStyle.italic);
    final boldStyle =
        pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold);
    final titleStyle =
        pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final totalStyle =
        pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold);
    final headerStyle = pw.TextStyle(font: font, fontSize: 9);

    final dateStr =
        DateFormat('yyyy/MM/dd – HH:mm').format(order.createdAt.toLocal());

    // Estimate page height: header ~45mm + each item ~12mm + footer ~25mm
    final estimatedH =
        (50 + orderItems.length * 14.0 + (order.notes != null ? 12 : 0) + 28) *
            _mmToPt;
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
              // Store name
              pw.Center(child: pw.Text('الكاشير', style: titleStyle)),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5),
              // Receipt info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('رقم: ${order.id}', style: headerStyle),
                  pw.Text('كاشير: $cashierName', style: headerStyle),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text('التاريخ: $dateStr', style: headerStyle),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 2),
              // Items table: RTL → col 0 is rightmost (item details), col 1 is leftmost (total)
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                      width: 0.3, color: PdfColors.grey400),
                  top: pw.BorderSide(width: 0.5),
                  bottom: pw.BorderSide(width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.5), // item details (right)
                  1: const pw.FlexColumnWidth(1.5), // total (left)
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _headerCell('الصنف', boldStyle),
                      _headerCell('الإجمالي', boldStyle),
                    ],
                  ),
                  // Item rows
                  ...orderItems.map((oi) {
                    final lineTotal =
                        oi.unitPriceSnapshot * oi.quantity;
                    return pw.TableRow(children: [
                      // Col 0 (right): name + qty×price + optional note
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 3),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(oi.itemNameSnapshot, style: nameStyle),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              '${oi.quantity} × ${oi.unitPriceSnapshot.toStringAsFixed(2)} ج.م',
                              style: detailStyle,
                            ),
                            if (oi.note != null && oi.note!.isNotEmpty) ...[
                              pw.SizedBox(height: 1),
                              pw.Text('• ${oi.note}', style: noteStyle),
                            ],
                          ],
                        ),
                      ),
                      // Col 1 (left): line total
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 3),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            '${lineTotal.toStringAsFixed(2)} ج.م',
                            style: boldStyle,
                          ),
                        ),
                      ),
                    ]);
                  }),
                ],
              ),
              pw.Divider(thickness: 0.5),
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي الكلي:', style: totalStyle),
                  pw.Text('${order.total.toStringAsFixed(2)} ج.م',
                      style: totalStyle),
                ],
              ),
              // Invoice notes
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.3),
                pw.Text('ملاحظات: ${order.notes}', style: noteStyle),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text('شكراً لتعاملكم معنا',
                    style: headerStyle),
              ),
            ],
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _headerCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.right),
    );
  }
}

