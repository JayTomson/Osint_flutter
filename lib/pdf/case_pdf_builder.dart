part of '../main.dart';

// ============================================================================
// CASE PDF BUILDER — full case report (one page per person)
// ============================================================================

class CasePdfBuilder {
  static Future<Uint8List> buildCasePdf(
    CaseFile caseFile, {
    required bool withConnections,
    required bool withEvidence,
  }) async {
    final doc = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.TextStyle ts(double size, {bool bold = false}) => pw.TextStyle(
          font: bold ? boldFont : baseFont,
          fontSize: size,
        );

    for (final p in caseFile.people) {
      final imageWidgets = <pw.Widget>[];
      if (withEvidence) {
        for (final ev in p.evidence) {
          for (final fp in ev.filePaths) {
            if (_isImagePath(fp)) {
              try {
                final bytes = await File(fp).readAsBytes();
                final img = pw.MemoryImage(bytes);
                imageWidgets.add(pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(img, height: 180, fit: pw.BoxFit.contain),
                      pw.Text(fp.split('/').last, style: ts(9)),
                    ],
                  ),
                ));
              } catch (_) {}
            }
          }
        }
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
          build: (ctx) {
            final widgets = <pw.Widget>[
              pw.Text('${caseFile.name}', style: ts(13, bold: true)),
              pw.SizedBox(height: 4),
              pw.Text(p.fullName, style: ts(20, bold: true)),
              pw.Divider(),
              pw.SizedBox(height: 8),
            ];

            if (p.priority != null) {
              widgets.add(pw.Text('${p.priority!.label}', style: ts(11)));
              widgets.add(pw.SizedBox(height: 4));
            }

            if (p.tags.isNotEmpty) {
              widgets.add(
                  pw.Text('Tags: ${p.tags.join(', ')}', style: ts(11)));
              widgets.add(pw.SizedBox(height: 6));
            }
            if (p.notes.isNotEmpty) {
              widgets.add(pw.Text(p.notes, style: ts(11)));
              widgets.add(pw.SizedBox(height: 12));
            }

            for (final c in p.categories) {
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(pw.Text(c.name, style: ts(14, bold: true)));
              widgets.add(pw.SizedBox(height: 4));
              for (final kv in c.entries) {
                widgets.add(pw.Bullet(
                    text: '${kv.key}: ${kv.value}', style: ts(11)));
              }
            }

            if (withEvidence && p.evidence.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 14));
              widgets
                  .add(pw.Text('Evidence', style: ts(14, bold: true)));
              for (final ev in p.evidence) {
                widgets.add(pw.SizedBox(height: 6));
                widgets.add(pw.Text(ev.description, style: ts(11)));
                for (final fp in ev.filePaths) {
                  widgets.add(
                      pw.Text('• ${fp.split('/').last}', style: ts(10)));
                }
              }
              if (imageWidgets.isNotEmpty) {
                widgets.add(pw.SizedBox(height: 8));
                widgets.addAll(imageWidgets);
              }
            }

            if (withConnections && p.connections.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 14));
              widgets.add(
                  pw.Text('Connections', style: ts(14, bold: true)));
              for (final link in p.connections) {
                final other = caseFile.findPerson(link.targetPersonId);
                widgets.add(pw.SizedBox(height: 4));
                widgets.add(pw.Text(other?.fullName ?? '?',
                    style: ts(12, bold: true)));
                for (final r in link.reasons) {
                  widgets.add(pw.Text('  - $r', style: ts(10)));
                }
              }
            }

            return widgets;
          },
        ),
      );
    }

    return doc.save();
  }
}

class CasePdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final CaseFile caseFile;
  const CasePdfPreviewScreen(
      {super.key, required this.bytes, required this.caseFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF — ${caseFile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final f = File(
                  '${AppState.instance.docsDir.path}/case_${caseFile.id}.pdf');
              await f.writeAsBytes(bytes);
              await Share.shareXFiles([XFile(f.path)]);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final f = File(
                  '${AppState.instance.docsDir.path}/case_${caseFile.id}.pdf');
              await f.writeAsBytes(bytes);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${f.path}')),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: false,
      ),
    );
  }
}
