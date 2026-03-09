import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Genera un PDF con el detalle de una evaluación realizada.
/// Recibe el mapa [detalle] (respuesta del API) y los textos ya resueltos para cabecera.
Future<Uint8List> generarPdfEvaluacion({
  required Map<String, dynamic> detalle,
  required String evaluadoNombre,
  required String evaluadoCargo,
  required String unidad,
  required String evaluadorNombre,
  required String evaluadorCargo,
}) async {
  final pdf = pw.Document();
  final fecha = detalle['fecha']?.toString() ?? '—';
  final funcionesRaw = detalle['funciones'];
  final funciones = funcionesRaw is List
      ? (funcionesRaw).map((e) => Map<String, dynamic>.from(e is Map ? e as Map : <String, dynamic>{})).toList()
      : <Map<String, dynamic>>[];
  final competenciasRaw = detalle['competencias'];
  final competencias = competenciasRaw is List
      ? (competenciasRaw).map((e) => Map<String, dynamic>.from(e is Map ? e as Map : <String, dynamic>{})).toList()
      : <Map<String, dynamic>>[];
  final planRaw = detalle['plan_trabajo'];
  final planTrabajo = planRaw is List
      ? (planRaw).map((e) => Map<String, dynamic>.from(e is Map ? e as Map : <String, dynamic>{})).toList()
      : <Map<String, dynamic>>[];
  final numNota = detalle['notafinal'] is num ? (detalle['notafinal'] as num).toDouble() : null;
  final numFactor = detalle['factorbono'] is num ? (detalle['factorbono'] as num).toDouble() : null;
  final comentarioEval = detalle['comentarioevaluador']?.toString() ?? '';
  final comentarioEvalado = detalle['comentarioevaluado']?.toString() ?? '';
  double? promFunc = funciones.isNotEmpty
      ? funciones.fold<double>(0, (s, e) => s + ((e['nota'] is num) ? (e['nota'] as num).toDouble() : 0)) / funciones.length
      : null;
  double? promComp = competencias.isNotEmpty
      ? competencias.fold<double>(0, (s, e) => s + ((e['nota'] is num) ? (e['nota'] as num).toDouble() : 0)) / competencias.length
      : null;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Evaluación de desempeño laboral',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Fecha de evaluación', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(fecha, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        _sectionTitle('I  DATOS DEL EVALUADO'),
        _tablaDatos({
          'Nombre': evaluadoNombre,
          'Unidad': unidad,
          'Cargo': evaluadoCargo,
        }),
        pw.SizedBox(height: 12),
        _sectionTitle('II  DATOS DEL EVALUADOR'),
        _tablaDatos({
          'Nombre': evaluadorNombre,
          'Cargo': evaluadorCargo,
        }),
        pw.SizedBox(height: 12),
        _sectionTitle('III  INSTRUCCIONES PARA LA EVALUACIÓN'),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Text(
            'Califique de 1 a 5 según la escala: 1=Bajo, 2=Necesita mejorar, 3=Cumple, 4=Buen desempeño, 5=Excelente.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        if (funciones.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sectionTitle('IV  EVALUACIÓN FUNCIONES DEL CARGO (70%)'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1)},
            children: [
              for (final f in funciones)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(f['nombre_funcion']?.toString() ?? f['nombre']?.toString() ?? '—', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${f['nota'] ?? '—'}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              if (promFunc != null)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('SUBTOTAL (PROMEDIO)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text((promFunc * 0.70).toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (competencias.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sectionTitle('V  EVALUACIÓN DE COMPETENCIAS (30%)'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1)},
            children: [
              for (final c in competencias)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(c['nombre_competencia']?.toString() ?? c['nombre']?.toString() ?? '—', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${c['nota'] ?? '—'}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              if (promComp != null)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('SUBTOTAL (PROMEDIO)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text((promComp * 0.30).toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
            ],
          ),
        ],
        pw.SizedBox(height: 12),
        _sectionTitle('VI  COMENTARIOS'),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Comentario del evaluador', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(comentarioEval.isEmpty ? '—' : comentarioEval, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 10),
              pw.Text('Comentario del evaluado', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(comentarioEvalado.isEmpty ? '—' : comentarioEvalado, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        _sectionTitle('VII  RESULTADOS'),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Puntaje total obtenido', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(numNota?.toStringAsFixed(2) ?? '—', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cantidad de rentas máximas', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(numFactor?.toStringAsFixed(1) ?? '—', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        if (planTrabajo.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sectionTitle('VIII  PLAN DE TRABAJO'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('Objetivo', bold: true),
                  _cell('Acciones esperadas', bold: true),
                  _cell('Seguimiento', bold: true),
                  _cell('Fecha límite', bold: true),
                ],
              ),
              for (final p in planTrabajo)
                pw.TableRow(
                  children: [
                    _cell(p['objetivo']?.toString() ?? '—'),
                    _cell(p['accionesesperadas']?.toString() ?? '—'),
                    _cell(p['seguimiento']?.toString() ?? '—'),
                    _cell(p['fechalimitetermino']?.toString() ?? '—'),
                  ],
                ),
            ],
          ),
        ],
        pw.SizedBox(height: 12),
        _sectionTitle('IX  FIRMAS DE PARTICIPACIÓN'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Container(
              width: 180,
              height: 50,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Center(child: pw.Text('Firma evaluador', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
            ),
            pw.Container(
              width: 180,
              height: 50,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Center(child: pw.Text('Firma evaluado', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _sectionTitle(String title) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    margin: const pw.EdgeInsets.only(bottom: 6),
    color: PdfColors.green800,
    child: pw.Text(
      title,
      style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    ),
  );
}

pw.Widget _tablaDatos(Map<String, String> rows) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: {0: const pw.FlexColumnWidth(1.2), 1: const pw.FlexColumnWidth(2)},
    children: [
      for (final e in rows.entries)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${e.key}:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        ),
    ],
  );
}

pw.Widget _cell(String text, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      maxLines: 3,
      overflow: pw.TextOverflow.clip,
    ),
  );
}
