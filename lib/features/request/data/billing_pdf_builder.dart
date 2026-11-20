import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/billing_document.dart';

class BillingPdfBuilder {
  const BillingPdfBuilder();

  Future<Uint8List> build(BillingDocument document) async {
    final regularData = await rootBundle.load('assets/fonts/Lato-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Lato-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final pdf = pw.Document(
      title: 'Projet de facture - ${document.requestId}',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    final ink = PdfColor.fromHex('#17324D');
    final accent = PdfColor.fromHex('#087E83');
    final muted = PdfColor.fromHex('#64748B');
    final pale = PdfColor.fromHex('#E9F4F3');
    final body = pw.TextStyle(fontSize: 10, color: ink);
    final small = pw.TextStyle(fontSize: 8, color: muted);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PROJET DE FACTURE · ${document.requestId}',
                    style: pw.TextStyle(
                      color: ink,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: pale),
                  pw.SizedBox(height: 12),
                ],
              ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: pale),
            pw.Text(
              'Projet de facture - non validé par Tunisie TradeNet. '
              'Ce document ne remplace pas une facture électronique officielle.',
              style: small,
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: small,
            ),
          ],
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            color: ink,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'QUICKFIX TUNISIA',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'PROJET DE FACTURE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 23,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Dossier ${document.requestId}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            document.createdAt == null
                ? 'Aperçu avant enregistrement'
                : 'Document établi le ${_date(document.createdAt!)}',
            style: small,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Date de la prestation : ${_serviceDate(document.serviceDate)}',
            style: small,
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _party(
                  'ÉMETTEUR',
                  document.issuerName,
                  [
                    document.issuerAddress,
                    'Matricule fiscal : ${document.taxId}',
                  ],
                  accent,
                  body,
                  small,
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: _party(
                  'CLIENT',
                  document.clientName,
                  ['Adresse de la prestation : ${document.clientAddress}'],
                  accent,
                  body,
                  small,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'DÉTAIL DE L’INTERVENTION',
            style: pw.TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: pale),
              bottom: pw.BorderSide(color: pale),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: pale),
                children: [
                  _cell('Désignation', body, bold: true),
                  _cell('Qté', body, bold: true),
                  _cell('Prix HT', body, bold: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell(document.service, body),
                  _cell('1', body),
                  _cell(_money(document.subtotalMillimes), body),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Travaux réalisés',
            style: pw.TextStyle(
              color: ink,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(document.workPerformed, style: body),
          if (document.diagnosis?.isNotEmpty == true) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Diagnostic',
              style: pw.TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(document.diagnosis!, style: body),
          ],
          if (document.materials?.isNotEmpty == true) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Matériaux ou pièces utilisés',
              style: pw.TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(document.materials!, style: body),
          ],
          if (document.clientAdvice?.isNotEmpty == true) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Conseils au client',
              style: pw.TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(document.clientAdvice!, style: body),
          ],
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow(
                    'Sous-total HT',
                    _money(document.subtotalMillimes),
                    body,
                  ),
                  pw.SizedBox(height: 8),
                  _totalRow(
                    document.vatRate == 0
                        ? 'TVA non appliquée'
                        : 'TVA ${document.vatRate} %',
                    _money(document.vatMillimes),
                    body,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: pale,
                    child: _totalRow(
                      'TOTAL À PAYER',
                      _money(document.totalMillimes),
                      pw.TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Montant conforme au devis accepté pour ce dossier.',
            style: small,
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _party(
    String label,
    String name,
    List<String> details,
    PdfColor accent,
    pw.TextStyle body,
    pw.TextStyle small,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        name,
        style: pw.TextStyle(
          color: body.color,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 5),
      ...details.map(
        (detail) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(detail, style: small),
        ),
      ),
    ],
  );

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    bool bold = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: pw.Text(
      text,
      style: bold
          ? pw.TextStyle(
              color: style.color,
              fontSize: style.fontSize,
              fontWeight: pw.FontWeight.bold,
            )
          : style,
    ),
  );

  static pw.Widget _totalRow(String label, String value, pw.TextStyle style) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      );

  static String _money(int millimes) =>
      '${millimes ~/ 1000},${(millimes % 1000).toString().padLeft(3, '0')} DT';

  static String _date(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _serviceDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : _date(date);
  }
}
