import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/evaluador_service.dart';
import '../utils/evaluacion_pdf.dart';
import '../utils/evaluacion_pdf_present_stub.dart'
    if (dart.library.html) '../utils/evaluacion_pdf_present_web.dart' as pdf_present;
import 'crear_evaluacion_screen.dart';

/// Pantalla para ver una evaluación ya realizada o para realizar una evaluación pendiente.
/// Recibe los datos del colaborador y el estado [realizada].
/// Si [realizada] y [detallePrecargado] es null, carga el detalle desde GET /api/evaluador/mis-evaluaciones.
/// Si [detallePrecargado] no es null (p. ej. desde GET /api/evaluaciones), se usa directamente.
/// Si [permisoAdminEditarEliminar] es true (p. ej. desde Consultar evaluaciones / RRHH), cualquier usuario con acceso puede editar y eliminar.
class EvaluacionDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> evaluacion;
  final bool realizada;
  /// Si se pasa, no se llama a mis-evaluaciones; se usa este mapa como detalle (p. ej. desde "Todas las evaluaciones").
  final Map<String, dynamic>? detallePrecargado;
  /// true cuando se abre desde "Consultar evaluaciones" (administrador RRHH): se muestran siempre Editar y Eliminar para cualquier evaluación.
  final bool permisoAdminEditarEliminar;

  const EvaluacionDetalleScreen({
    super.key,
    required this.evaluacion,
    required this.realizada,
    this.detallePrecargado,
    this.permisoAdminEditarEliminar = false,
  });

  @override
  State<EvaluacionDetalleScreen> createState() => _EvaluacionDetalleScreenState();
}

class _EvaluacionDetalleScreenState extends State<EvaluacionDetalleScreen> {
  Map<String, dynamic>? _detalle;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.realizada) {
      if (widget.detallePrecargado != null) {
        _detalle = widget.detallePrecargado;
      } else {
        _cargarDetalle();
      }
    }
  }

  Future<void> _imprimirPdf({
    required String evaluadoNombre,
    required String evaluadoCargo,
    required String unidad,
    required String evaluadorNombre,
    required String evaluadorCargo,
  }) async {
    if (_detalle == null) return;
    try {
      final bytes = await generarPdfEvaluacion(
        detalle: _detalle!,
        evaluadoNombre: evaluadoNombre,
        evaluadoCargo: evaluadoCargo,
        unidad: unidad,
        evaluadorNombre: evaluadorNombre,
        evaluadorCargo: evaluadorCargo,
      );
      if (!mounted) return;
      final nombreArchivo = 'Evaluacion_${evaluadoNombre.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_')}_${_detalle!['fecha'] ?? 'fecha'}.pdf';
      await pdf_present.presentPdf(bytes, nombreArchivo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editarEvaluacion() async {
    if (_detalle == null) return;
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CrearEvaluacionScreen(
          evaluacion: _detalle!,
          idEvaluacion: _detalle!['id_evaluacion']?.toString(),
        ),
      ),
    );
    if (actualizado == true && mounted) {
      _cargarDetalle();
    }
  }

  Future<void> _confirmarEliminar() async {
    if (_detalle == null) return;
    final id = _detalle!['id_evaluacion']?.toString();
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: falta identificador de la evaluación'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evaluación'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta evaluación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await EvaluadorService.eliminarEvaluacion(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evaluación eliminada'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cargarDetalle() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await EvaluadorService.getMisEvaluaciones();
      if (!mounted) return;
      final nombreBuscado = (widget.evaluacion['evaluado_nombre']?.toString() ?? '').trim();
      final idEvaluado = widget.evaluacion['id_evaluado']?.toString();
      List<Map<String, dynamic>> candidatos = lista.where((e) {
        final nombre = (e['evaluado_nombre']?.toString() ?? '').trim();
        if (nombre.isEmpty) return false;
        if (nombreBuscado.isNotEmpty && nombre == nombreBuscado) return true;
        if (idEvaluado != null &&
            idEvaluado.isNotEmpty &&
            (e['id_evaluado']?.toString() == idEvaluado)) return true;
        return false;
      }).toList();
      candidatos.sort((a, b) {
        final fa = a['fecha']?.toString() ?? '';
        final fb = b['fecha']?.toString() ?? '';
        return fb.compareTo(fa);
      });
      setState(() {
        _detalle = candidatos.isNotEmpty ? candidatos.first : null;
        _cargando = false;
        if (_detalle == null) {
          _error = lista.isEmpty
              ? 'No hay evaluaciones realizadas registradas.'
              : 'No se encontró el detalle de esta evaluación.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDatosTable(ColorScheme scheme, Map<String, String> rows) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2)},
        children: rows.entries
            .map((entry) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        entry.value,
                        style: TextStyle(color: scheme.onSurface, fontSize: 14),
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, String fechaStr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Evaluación de desempeño laboral',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Fecha de evaluación',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fechaStr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final evaluacion = widget.evaluacion;
    final realizada = widget.realizada;

    final d = _detalle;
    final evaluadoNombre = (d != null ? d['evaluado_nombre'] : null)?.toString() ?? evaluacion['evaluado_nombre']?.toString() ?? '—';
    final evaluadoCargo = (d != null ? d['cargo_evaluado'] : null)?.toString() ?? evaluacion['cargo']?.toString() ?? evaluacion['cargo_evaluado']?.toString() ?? '—';
    final unidad = (d != null ? (d['sucursal'] ?? d['sucursal_ubicacion']) : null)?.toString() ?? evaluacion['sucursal']?.toString() ?? evaluacion['sucursal_nombre']?.toString() ?? '—';
    final evaluadorNombre = (d != null ? d['evaluador_nombre'] : null)?.toString() ?? evaluacion['evaluador_nombre']?.toString() ?? '—';
    final evaluadorCargo = (d != null ? d['cargo_evaluador'] : null)?.toString() ?? evaluacion['cargo_evaluador']?.toString() ?? evaluacion['cargo_evaluador_nombre']?.toString() ?? '—';

    return MainScaffold(
      title: realizada ? 'Ver evaluación' : 'Realizar evaluación',
      drawer: null,
      actions: (realizada && _detalle != null) || (widget.permisoAdminEditarEliminar && _detalle != null)
          ? [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar evaluación',
                onPressed: () => _editarEvaluacion(),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Imprimir / Guardar PDF',
                onPressed: () => _imprimirPdf(
                  evaluadoNombre: evaluadoNombre,
                  evaluadoCargo: evaluadoCargo,
                  unidad: unidad,
                  evaluadorNombre: evaluadorNombre,
                  evaluadorCargo: evaluadorCargo,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar evaluación',
                onPressed: () => _confirmarEliminar(),
              ),
            ]
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((realizada || widget.permisoAdminEditarEliminar) && _detalle != null) ...[
              _buildHeader(scheme, _detalle!['fecha']?.toString() ?? '—'),
              _buildSectionTitle('I  DATOS DEL EVALUADO'),
              _buildDatosTable(scheme, {
                'Nombre': evaluadoNombre,
                'Unidad': unidad,
                'Cargo': evaluadoCargo,
              }),
              _buildSectionTitle('II  DATOS DEL EVALUADOR'),
              _buildDatosTable(scheme, {
                'Nombre': evaluadorNombre,
                'Cargo': evaluadorCargo,
              }),
              _buildSectionTitle('III  INSTRUCCIONES PARA LA EVALUACIÓN'),
              _buildInstruccionesReadOnly(scheme),
              _buildDetalleContenido(context, _detalle!, scheme),
              const SizedBox(height: 24),
            ] else if (realizada && _cargando) ...[
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando detalle de la evaluación...',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ] else if (realizada && _error != null) ...[
              Card(
                color: scheme.errorContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.error, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: _cargarDetalle,
                        child: Text('Reintentar', style: TextStyle(color: scheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!realizada) ...[
              _buildSectionTitle('I  DATOS DEL EVALUADO'),
              _buildDatosTable(scheme, {
                'Nombre': evaluadoNombre,
                'Unidad': unidad,
                'Cargo': evaluadoCargo,
              }),
              _buildSectionTitle('II  DATOS DEL EVALUADOR'),
              _buildDatosTable(scheme, {
                'Nombre': evaluadorNombre,
                'Cargo': evaluadorCargo,
              }),
              const SizedBox(height: 24),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Formulario de evaluación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa el formulario y guarda la evaluación de desempeño.',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () async {
                          final creado = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => CrearEvaluacionScreen(
                                evaluacion: widget.evaluacion,
                              ),
                            ),
                          );
                          if (creado == true && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        icon: const Icon(Icons.edit_note, size: 22),
                        label: const Text('Realizar evaluación'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstruccionesReadOnly(ColorScheme scheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Califique de 1 a 5, la gestión del colaborador de acuerdo con el desempeño que ha tenido frente al desarrollo y ejecución de su trabajo.\n\n'
              'Tenga en cuenta la siguiente escala y asigne la calificación pertinente. Evalúe con total objetividad cada uno de los elementos.',
              style: TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.4),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {0: FlexColumnWidth(0.5), 1: FlexColumnWidth(2.5)},
              border: TableBorder.all(color: scheme.outlineVariant),
              children: const [
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('1', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Bajo Rendimiento - No cumple con lo esperado o presenta dificultades.')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('2', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Necesita mejorar - Cumple parcialmente; requiere mejorar en aspectos específicos.')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('3', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Cumple con lo esperado - Satisface las expectativas y objetivos del cargo.')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('4', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Buen desempeño - Supera en varios aspectos y contribuye de forma consistente.')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('5', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Excelente desempeño - Nivel excepcional de desempeño y aporte a los objetivos.')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleContenido(BuildContext context, Map<String, dynamic> d, ColorScheme scheme) {
    final funcionesRaw = d['funciones'];
    final funciones = funcionesRaw is List
        ? (funcionesRaw).map((e) => Map<String, dynamic>.from(e is Map ? e as Map : <String, dynamic>{})).toList()
        : <Map<String, dynamic>>[];
    final competenciasRaw = d['competencias'];
    final competencias = competenciasRaw is List
        ? (competenciasRaw).map((e) => Map<String, dynamic>.from(e is Map ? e as Map : <String, dynamic>{})).toList()
        : <Map<String, dynamic>>[];
    final planRaw = d['plan_trabajo'];
    final planTrabajo = planRaw is List
        ? (planRaw).map((e) => Map<String, dynamic>.from(e is Map ? e as Map : <String, dynamic>{})).toList()
        : <Map<String, dynamic>>[];
    final notafinal = d['notafinal'];
    final factorbono = d['factorbono'];
    double? numNota;
    if (notafinal is num) {
      numNota = (notafinal as num).toDouble();
    } else if (notafinal != null) {
      numNota = double.tryParse(notafinal.toString().trim());
    }
    double? numFactor;
    if (factorbono is num) {
      numFactor = (factorbono as num).toDouble();
    } else if (factorbono != null) {
      numFactor = double.tryParse(factorbono.toString().trim());
    }
    final comentarioEval = d['comentarioevaluador']?.toString();
    final comentarioEvalado = d['comentarioevaluado']?.toString();

    // Etiquetas para Aspectos a mejorar (mapean el índice guardado a nombres de funciones/competencias).
    final aspectosLabels = <String>[];
    for (final f in funciones) {
      final nombre = f['nombre']?.toString() ?? f['nombre_funcion']?.toString() ?? 'Función';
      aspectosLabels.add('Función: $nombre');
    }
    for (final c in competencias) {
      final nombre = c['nombre']?.toString() ?? c['nombre_competencia']?.toString() ?? 'Competencia';
      aspectosLabels.add('Competencia: $nombre');
    }

    double? promedioFunc = funciones.isNotEmpty
        ? funciones.fold<double>(0, (s, e) {
            final n = e['nota'];
            if (n is num) return s + n.toDouble();
            return s;
          }) / funciones.length
        : null;
    double? promedioComp = competencias.isNotEmpty
        ? competencias.fold<double>(0, (s, e) {
            final n = e['nota'];
            if (n is num) return s + n.toDouble();
            return s;
          }) / competencias.length
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (funciones.isNotEmpty) ...[
          _buildSectionTitle('IV  EVALUACIÓN FUNCIONES DEL CARGO (70%)'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                ...funciones.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              f['nombre_funcion']?.toString() ?? f['nombre']?.toString() ?? '—',
                              style: TextStyle(fontSize: 14, color: scheme.onSurface),
                            ),
                          ),
                          Text(
                            '${f['nota'] ?? '—'}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 1),
                if (promedioFunc != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SUBTOTAL (PROMEDIO)', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                        Text(
                          (promedioFunc * 0.70).toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (competencias.isNotEmpty) ...[
          _buildSectionTitle('V  EVALUACIÓN DE COMPETENCIAS (30%)'),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                ...competencias.map((c) {
                      final nombreComp = c['nombre_competencia']?.toString() ?? c['nombre']?.toString() ?? '—';
                      final defComp = c['definicion']?.toString();
                      final hasDef = defComp != null && defComp.trim().isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nombreComp,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
                                  ),
                                  if (hasDef) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      defComp!,
                                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '${c['nota'] ?? '—'}',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
                            ),
                          ],
                        ),
                      );
                    }),
                const Divider(height: 1),
                if (promedioComp != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SUBTOTAL (PROMEDIO)', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                        Text(
                          (promedioComp * 0.30).toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        _buildSectionTitle('VI  COMENTARIOS'),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMENTARIOS DEL EVALUADOR',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comentarioEval?.isNotEmpty == true ? comentarioEval! : '—',
                    style: TextStyle(fontSize: 14, color: scheme.onSurface),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'COMENTARIOS DEL EVALUADO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comentarioEvalado?.isNotEmpty == true ? comentarioEvalado! : '—',
                    style: TextStyle(fontSize: 14, color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildSectionTitle('VII  RESULTADOS'),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Puntaje total obtenido',
                        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        numNota?.toStringAsFixed(2) ?? '—',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Cantidad de rentas máximas',
                        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        numFactor != null ? numFactor.toStringAsFixed(1) : '—',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildSectionTitle('VIII  PLAN DE TRABAJO'),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: Text('Aspectos a mejorar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 220,
                        child: Text('Objetivo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Acciones esperadas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: Text('Fecha límite', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (planTrabajo.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sin objetivos registrados', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  )
                else
                  ...planTrabajo.map((p) {
                    final idxRaw = p['aspectosamejorar'];
                    int? idx;
                    if (idxRaw is int) {
                      idx = idxRaw;
                    } else if (idxRaw != null) {
                      idx = int.tryParse(idxRaw.toString());
                    }
                    String label = '—';
                    if (idx != null && idx >= 0 && idx < aspectosLabels.length) {
                      label = aspectosLabels[idx];
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 220,
                            child: Text(
                              label,
                              style: TextStyle(fontSize: 13, color: scheme.onSurface),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 220,
                            child: Text(p['objetivo']?.toString() ?? '—', style: TextStyle(fontSize: 13, color: scheme.onSurface)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(p['accionesesperadas']?.toString() ?? '—', style: TextStyle(fontSize: 13, color: scheme.onSurface)),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: Text(p['fechalimitetermino']?.toString() ?? '—', style: TextStyle(fontSize: 13, color: scheme.onSurface)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        _buildSectionTitle('IX  FIRMAS DE PARTICIPACIÓN'),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'FIRMA EVALUADOR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Firma (opcional)',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'FIRMA EVALUADO',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Firma (opcional)',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
