import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';

class CasePdfBuilder {
  final CaseFile caseFile;
  final bool withConnections;
  final bool withEvidence;

  CasePdfBuilder({
    required this.caseFile,
    this.withConnections = true,
    this.withEvidence = true,
  });

  Future<List<int>> build() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              caseFile.name,
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                  color: PdfColors.blueGrey800),
            ),
            pw.Divider(),
          ],
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          for (final person in caseFile.people) {
            widgets.add(_buildPersonSection(person, boldFont, font));
            widgets.add(pw.SizedBox(height: 16));
          }
          return widgets;
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPersonSection(
      Person person, pw.Font boldFont, pw.Font font) {
    final children = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: const pw.BoxDecoration(
          color: PdfColors.blueGrey100,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(
          person.fullName,
          style: pw.TextStyle(font: boldFont, fontSize: 15),
        ),
      ),
      pw.SizedBox(height: 6),
    ];

    if (person.tags.isNotEmpty) {
      children.add(pw.Text(
        '${tr("tags")}: ${person.tags.join(", ")}',
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
      ));
      children.add(pw.SizedBox(height: 4));
    }

    if (person.notes.isNotEmpty) {
      children.add(pw.Text(
        '${tr("notes")}: ${person.notes}',
        style: pw.TextStyle(font: font, fontSize: 10),
      ));
      children.add(pw.SizedBox(height: 4));
    }

    for (final cat in person.categories) {
      children.add(pw.Text(
        cat.name,
        style: pw.TextStyle(
            font: boldFont, fontSize: 11, color: PdfColors.blueGrey700),
      ));
      for (final kv in cat.entries) {
        children.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (kv.key.isNotEmpty) ...[
                pw.Text('${kv.key}: ',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 10,
                        color: PdfColors.grey700)),
              ],
              pw.Expanded(
                child: pw.Text(kv.value,
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ),
            ],
          ),
        ));
      }
      children.add(pw.SizedBox(height: 4));
    }

    if (withConnections && person.connections.isNotEmpty) {
      children.add(pw.Text(
        tr('connections'),
        style: pw.TextStyle(
            font: boldFont, fontSize: 11, color: PdfColors.blueGrey700),
      ));
      for (final link in person.connections) {
        final target = caseFile.findPerson(link.targetPersonId);
        children.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
          child: pw.Text(
            '• ${target?.fullName ?? tr("unknown_target")}${link.reasons.isNotEmpty ? ": ${link.reasons.join(", ")}" : ""}',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ));
      }
      children.add(pw.SizedBox(height: 4));
    }

    if (withEvidence && person.evidence.isNotEmpty) {
      children.add(pw.Text(
        tr('evidence'),
        style: pw.TextStyle(
            font: boldFont, fontSize: 11, color: PdfColors.blueGrey700),
      ));
      for (final ev in person.evidence) {
        children.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
          child: pw.Text(
            '• ${ev.description.isNotEmpty ? ev.description : tr("evidence_no_description")}${ev.filePaths.isNotEmpty ? " (${ev.filePaths.length} ${tr("files")})" : ""}',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }
}

class CasePdfPreviewScreen extends StatefulWidget {
  final CaseFile caseFile;
  final bool withConnections;
  final bool withEvidence;
  const CasePdfPreviewScreen({
    super.key,
    required this.caseFile,
    this.withConnections = true,
    this.withEvidence = true,
  });
  @override
  State<CasePdfPreviewScreen> createState() =>
      _CasePdfPreviewScreenState();
}

class _CasePdfPreviewScreenState extends State<CasePdfPreviewScreen> {
  late final Future<List<int>> _future;

  @override
  void initState() {
    super.initState();
    _future = CasePdfBuilder(
      caseFile: widget.caseFile,
      withConnections: widget.withConnections,
      withEvidence: widget.withEvidence,
    ).build();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('case_pdf')),
        actions: [
          IconButton(
            tooltip: tr('share'),
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final bytes = await _future;
              final dir = AppState.instance.docsDir;
              final f = File(
                  '${dir.path}/${widget.caseFile.name.replaceAll(RegExp(r'[^\w]'), '_')}.pdf');
              await f.writeAsBytes(bytes);
              await Share.shareXFiles([XFile(f.path)],
                  subject: widget.caseFile.name);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<int>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('${tr("error")}: ${snap.error}'));
          }
          return PdfPreview(
            build: (_) async => snap.data!,
            allowSharing: true,
            allowPrinting: true,
          );
        },
      ),
    );
  }
}
