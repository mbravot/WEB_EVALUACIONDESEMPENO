import 'dart:typed_data';
import 'package:printing/printing.dart';

/// En móvil/desktop: abre el diálogo de impresión del sistema.
Future<void> presentPdf(Uint8List bytes, String filename) async {
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}
