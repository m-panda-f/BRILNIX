import 'package:flutter/material.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String pdfName;

  PdfViewerScreen({required this.pdfUrl, required this.pdfName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfName),
      ),
      body: FutureBuilder<PDFDocument>(
        future: PDFDocument.fromURL(pdfUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return PDFViewer(
                document: snapshot.data!,
              );
            } else {
              return Center(child: Text('Error loading PDF'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}