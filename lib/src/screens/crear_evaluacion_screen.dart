import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/evaluador_service.dart';
import '../services/auth_service.dart';
import '../services/cargos_service.dart';
import '../services/competencias_service.dart';

/// Escala de rentas según puntaje total (1-5):
/// Excelente 4.6-5 → 2; Bueno 4-4.5 → 1.5; Cumple 3-3.9 → 1;
/// Necesita mejorar 2-2.9 → 0.5; Bajo 1-1.9 → 0
double rentasDesdePuntaje(double puntaje) {
  if (puntaje >= 4.6) return 2;
  if (puntaje >= 4) return 1.5;
  if (puntaje >= 3) return 1;
  if (puntaje >= 2) return 0.5;
  return 0;
}

/// Pantalla para crear una evaluación de desempeño según el formato
/// Evaluación de desempeño laboral (fecha, datos evaluado/evaluador, instrucciones,
/// funciones 70%, competencias 30%, comentarios, resultados, plan de trabajo, firmas).
class CrearEvaluacionScreen extends StatefulWidget {
  final Map<String, dynamic> evaluacion;
  /// Si se pasa, la pantalla está en modo edición (prellenar y enviar PUT).
  final String? idEvaluacion;

  const CrearEvaluacionScreen({
    super.key,
    required this.evaluacion,
    this.idEvaluacion,
  });

  @override
  State<CrearEvaluacionScreen> createState() => _CrearEvaluacionScreenState();
}

class _CrearEvaluacionScreenState extends State<CrearEvaluacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioEvalController = TextEditingController();
  final _comentarioEvaladoController = TextEditingController();

  DateTime _fecha = DateTime.now();
  bool _enviando = false;
  String? _error;
  bool _cargandoFunciones = true;
  bool _cargandoCompetencias = true;

  /// Items con id_cargofuncion / id_competencianivel y nota (1-5). Null nota = sin calificar.
  List<Map<String, dynamic>> _funciones = [];
  List<Map<String, dynamic>> _competencias = [];
  List<Map<String, dynamic>> _planTrabajo = [];
  Map<String, dynamic>? _user;

  /// Opciones para asociar el plan de trabajo a una función o competencia (solo títulos).
  /// El índice de la lista se envía como `aspectosamejorar` (int o null).
  List<String> get _aspectosOpcionesLabels {
    final labels = <String>[];
    for (final f in _funciones) {
      final nombre = f['nombre']?.toString() ?? f['nombre_funcion']?.toString() ?? 'Función';
      labels.add('Función: $nombre');
    }
    for (final c in _competencias) {
      final nombre = c['nombre']?.toString() ?? c['nombre_competencia']?.toString() ?? 'Competencia';
      labels.add('Competencia: $nombre');
    }
    return labels;
  }

  /// Cargos y sucursal cargados por id para mostrar en datos del evaluado.
  String? _cargoEvaluadoNombre;
  String? _cargoEvaluadorNombre;
  String? _unidadNombre;

  bool get _esEdicion => widget.idEvaluacion != null && widget.idEvaluacion!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _planTrabajo.clear();
    if (_esEdicion && widget.evaluacion['plan_trabajo'] is List) {
      final pt = widget.evaluacion['plan_trabajo'] as List;
      for (final p in pt) {
        final m = p is Map ? Map<String, dynamic>.from(p as Map) : <String, dynamic>{};
        final asp = m['aspectosamejorar'];
        final aspectosamejorar = asp is int ? asp : (asp is num ? (asp as num).toInt() : int.tryParse(asp?.toString().trim() ?? ''));
        _planTrabajo.add({
          'objetivo': m['objetivo']?.toString() ?? '',
          'accionesesperadas': m['accionesesperadas']?.toString() ?? '',
          'aspectosamejorar': aspectosamejorar,
          'fechalimitetermino': m['fechalimitetermino']?.toString() ?? '',
        });
      }
    }
    if (_planTrabajo.isEmpty) {
      _planTrabajo.add({'objetivo': '', 'accionesesperadas': '', 'aspectosamejorar': null, 'fechalimitetermino': ''});
    }
    if (_esEdicion) {
      final fStr = widget.evaluacion['fecha']?.toString() ?? '';
      if (fStr.isNotEmpty) {
        final parts = fStr.split(RegExp(r'[-/]'));
        if (parts.length >= 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) _fecha = DateTime(y, m, d);
        }
      }
      _comentarioEvalController.text = widget.evaluacion['comentarioevaluador']?.toString() ?? '';
      _comentarioEvaladoController.text = widget.evaluacion['comentarioevaluado']?.toString() ?? '';
    }
    _cargarCargosYCargarFuncionesYCompetencias();
    AuthService().getCurrentUser().then((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  /// Carga nombres de cargo (evaluado y evaluador), luego funciones del cargo y competencias del nivel.
  Future<void> _cargarCargosYCargarFuncionesYCompetencias() async {
    final idCargoEvalado = _parseInt(
      widget.evaluacion['id_cargoevaluado'] ?? widget.evaluacion['id_cargo_evaluado'],
    );
    final idCargoEval = _parseInt(
      widget.evaluacion['id_cargoevaluador'] ?? widget.evaluacion['id_cargo_evaluador'],
    );

    if (idCargoEvalado != null) {
      try {
        final cargoEvalado = await CargosService.getById(idCargoEvalado);
        if (mounted) setState(() => _cargoEvaluadoNombre = cargoEvalado['nombre']?.toString());
      } catch (_) {
        if (mounted) setState(() => _cargoEvaluadoNombre = null);
      }
    }
    if (idCargoEval != null) {
      try {
        final cargoEval = await CargosService.getById(idCargoEval);
        if (mounted) setState(() => _cargoEvaluadorNombre = cargoEval['nombre']?.toString());
      } catch (_) {
        if (mounted) setState(() => _cargoEvaluadorNombre = null);
      }
    }

    final idSucursal = _parseInt(widget.evaluacion['id_sucursal']);
    if (idSucursal != null) {
      try {
        final sucursales = await AuthService().getSucursalesDisponibles();
        if (mounted) {
          final suc = sucursales.where((s) {
            final sid = s['id'] is int ? s['id'] as int : int.tryParse(s['id']?.toString() ?? '');
            return sid == idSucursal;
          }).firstOrNull;
          setState(() => _unidadNombre = suc?['nombre']?.toString() ?? suc?['nombre_sucursal']?.toString());
        }
      } catch (_) {
        if (mounted) setState(() => _unidadNombre = null);
      }
    }

    if (idCargoEvalado == null) {
      setState(() {
        _cargandoFunciones = false;
        _cargandoCompetencias = false;
      });
      return;
    }

    if (_esEdicion && widget.evaluacion['funciones'] is List && widget.evaluacion['competencias'] is List) {
      final funcRaw = widget.evaluacion['funciones'] as List;
      final compRaw = widget.evaluacion['competencias'] as List;
      setState(() {
        _funciones = funcRaw.map((e) {
          final m = e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{};
          final nota = m['nota'];
          final notaInt = nota is int ? nota : (nota is num ? nota.toInt() : int.tryParse(nota?.toString() ?? ''));
          return {
            'id_cargofuncion': m['id_cargofuncion'] ?? m['id'],
            'nombre': m['nombre_funcion']?.toString() ?? m['nombre']?.toString() ?? 'Función',
            'nota': notaInt,
          };
        }).toList();
        _competencias = compRaw.map((e) {
          final m = e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{};
          final nota = m['nota'];
          final notaInt = nota is int ? nota : (nota is num ? nota.toInt() : int.tryParse(nota?.toString() ?? ''));
          return {
            'id_competencianivel': m['id_competencianivel'] ?? m['id'],
            'nombre': m['nombre_competencia']?.toString() ?? m['nombre']?.toString() ?? 'Competencia',
            'definicion': m['definicion']?.toString(),
            'nota': notaInt,
          };
        }).toList();
        _cargandoFunciones = false;
        _cargandoCompetencias = false;
      });
      return;
    }

    try {
      final funciones = await EvaluadorService.getFuncionesCargo(idCargoEvalado);
      if (!mounted) return;
      setState(() {
        _funciones = funciones.map((e) => {'id_cargofuncion': e['id_cargofuncion'], 'nombre': e['nombre'] ?? e['descripcion'] ?? 'Función', 'nota': null as int?}).toList();
        _cargandoFunciones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _funciones = [];
        _cargandoFunciones = false;
      });
    }

    try {
      final disponibles = await CompetenciasService.getDisponiblesByCargo(idCargoEvalado);
      if (!mounted) return;
      setState(() {
        _competencias = disponibles.map((e) {
          final idCn = e['id'] is int ? e['id'] as int : int.tryParse(e['id']?.toString() ?? '');
          final nombre = e['nombre_competencia']?.toString() ?? e['nombre']?.toString() ?? e['definicion']?.toString() ?? 'Competencia';
          return {
            'id_competencianivel': idCn,
            'nombre': nombre,
            'definicion': e['definicion']?.toString(),
            'nota': null as int?,
          };
        }).toList();
        _cargandoCompetencias = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _competencias = [];
        _cargandoCompetencias = false;
      });
    }
  }

  @override
  void dispose() {
    _comentarioEvalController.dispose();
    _comentarioEvaladoController.dispose();
    super.dispose();
  }

  double get _promedioFunciones {
    final conNota = _funciones.where((e) => e['nota'] != null).toList();
    if (conNota.isEmpty) return 0;
    final sum = conNota.fold<int>(0, (s, e) => s + ((e['nota'] as int?) ?? 0));
    return sum / conNota.length;
  }

  double get _promedioCompetencias {
    final conNota = _competencias.where((e) => e['nota'] != null).toList();
    if (conNota.isEmpty) return 0;
    final sum = conNota.fold<int>(0, (s, e) => s + ((e['nota'] as int?) ?? 0));
    return sum / conNota.length;
  }

  double get _puntajeTotal {
    final subFunc = _promedioFunciones * 0.70;
    final subComp = _promedioCompetencias * 0.30;
    return ((subFunc + subComp) * 100).round() / 100;
  }

  double get _rentas => rentasDesdePuntaje(_puntajeTotal);

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _enviar() async {
    _error = null;
    if (_funciones.any((e) => e['nota'] == null)) {
      setState(() => _error = 'Asigna una nota (1-5) a cada función del cargo.');
      return;
    }
    if (_competencias.any((e) => e['nota'] == null)) {
      setState(() => _error = 'Asigna una nota (1-5) a cada competencia.');
      return;
    }

    final e = widget.evaluacion;
    final idEvaluador = e['id_evaluador']?.toString();
    final idEvaluado = e['id_evaluado']?.toString();
    final idCargoEval = _parseInt(e['id_cargoevaluador'] ?? e['id_cargo_evaluador']);
    final idCargoEvalado = _parseInt(e['id_cargoevaluado'] ?? e['id_cargo_evaluado']);

    if (idEvaluador == null || idEvaluador.isEmpty || idEvaluado == null || idEvaluado.isEmpty ||
        idCargoEval == null || idCargoEvalado == null) {
      setState(() => _error = 'Faltan datos de la asignación (evaluador/evaluado/cargo).');
      return;
    }

    final fechaStr =
        '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'id_evaluador': idEvaluador,
      'id_evaluado': idEvaluado,
      'id_cargoevaluador': idCargoEval,
      'id_cargoevaluado': idCargoEvalado,
      'fecha': fechaStr,
      'notafinal': _puntajeTotal,
      'factorbono': _rentas,
      'competencias': _competencias
          .map((c) {
            final idCn = c['id_competencianivel'];
            final idInt = idCn is int ? idCn : (idCn is num ? idCn.toInt() : int.tryParse(idCn?.toString() ?? ''));
            return {'id_competencianivel': idInt, 'nota': c['nota'] as int};
          })
          .where((c) => c['id_competencianivel'] != null)
          .toList(),
      'funciones': _funciones
          .map((f) => {'id_cargofuncion': f['id_cargofuncion'], 'nota': f['nota'] as int})
          .toList(),
      'plan_trabajo': _planTrabajo
          .where((p) =>
              (p['objetivo']?.toString() ?? '').trim().isNotEmpty ||
              (p['accionesesperadas']?.toString() ?? '').trim().isNotEmpty)
          .map((p) {
                final a = p['aspectosamejorar'];
                int? aspectosamejorar;
                if (a is int) {
                  aspectosamejorar = a;
                } else if (a != null && a.toString().trim().isNotEmpty) {
                  aspectosamejorar = int.tryParse(a.toString().trim());
                }
                return {
                  'objetivo': (p['objetivo']?.toString() ?? '').trim(),
                  'accionesesperadas': (p['accionesesperadas']?.toString() ?? '').trim(),
                  'aspectosamejorar': aspectosamejorar,
                  'fechalimitetermino': (p['fechalimitetermino']?.toString() ?? '').trim(),
                };
              })
          .toList(),
    };

    final comentarioEval = _comentarioEvalController.text.trim();
    if (comentarioEval.isNotEmpty) body['comentarioevaluador'] = comentarioEval;
    final comentarioEvalado = _comentarioEvaladoController.text.trim();
    if (comentarioEvalado.isNotEmpty) body['comentarioevaluado'] = comentarioEvalado;

    final idSucursal = _parseInt(e['id_sucursal']);
    if (idSucursal != null) body['id_sucursal'] = idSucursal;

    if (!mounted) return;
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      if (_esEdicion) {
        await EvaluadorService.actualizarEvaluacion(widget.idEvaluacion!, body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación actualizada correctamente'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await EvaluadorService.crearEvaluacion(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación creada correctamente'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (ex) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = ex.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = widget.evaluacion;

    final evaluadoNombre = e['evaluado_nombre']?.toString() ?? '—';
    final evaluadoCargo = _cargoEvaluadoNombre ?? e['cargo']?.toString() ?? e['cargo_evaluado']?.toString() ?? '—';
    final unidad = _unidadNombre ?? e['sucursal']?.toString() ?? e['sucursal_nombre']?.toString() ?? '—';

    final evaluadorNombre = e['evaluador_nombre']?.toString() ?? _user?['nombre']?.toString() ?? '—';
    final evaluadorCargo = _cargoEvaluadorNombre ?? e['cargo_evaluador']?.toString() ?? e['cargo_evaluador_nombre']?.toString() ?? '—';

    return MainScaffold(
      title: _esEdicion ? 'Editar evaluación' : 'Evaluación de desempeño',
      drawer: null,
      body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(scheme),
                  if (_error != null) _buildError(scheme),
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
                  _buildInstrucciones(scheme),
                  _buildSectionTitle('IV  EVALUACIÓN FUNCIONES DEL CARGO (70%)'),
                  _buildFunciones(scheme),
                  _buildSectionTitle('V  EVALUACIÓN DE COMPETENCIAS (30%)'),
                  _buildCompetencias(scheme),
                  _buildSectionTitle('VI  COMENTARIOS'),
                  _buildComentarios(scheme),
                  _buildSectionTitle('VII  RESULTADOS'),
                  _buildResultados(scheme),
                  _buildSectionTitle('VIII  PLAN DE TRABAJO'),
                  _buildPlanTrabajo(scheme),
                  _buildSectionTitle('IX  FIRMAS DE PARTICIPACIÓN'),
                  _buildFirmas(scheme),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 22),
                    label: Text(_enviando ? 'Guardando...' : (_esEdicion ? 'Actualizar evaluación' : 'Guardar evaluación')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
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
            OutlinedButton(
              onPressed: _enviando ? null : _elegirFecha,
              child: Text(
                '${_fecha.day.toString().padLeft(2, '0')}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.year}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: scheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: scheme.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildInstrucciones(ColorScheme scheme) {
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

  Widget _buildFunciones(ColorScheme scheme) {
    if (_cargandoFunciones) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_funciones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay funciones del cargo cargadas para este puesto. Contacte a RRHH.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
      );
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (int i = 0; i < _funciones.length; i++) ...[
            _buildNotaRow(scheme, _funciones, i, 'nombre', 'nota'),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SUBTOTAL (PROMEDIO)', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                Text(
                  (_promedioFunciones * 0.70).toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetencias(ColorScheme scheme) {
    if (_cargandoCompetencias) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_competencias.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay competencias definidas para el nivel de este cargo. Asigne nivel al cargo y defina competencias en "Competencias por cargo".',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
      );
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (int i = 0; i < _competencias.length; i++) ...[
            _buildNotaRow(scheme, _competencias, i, 'nombre', 'nota', subtitleKey: 'definicion'),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SUBTOTAL (PROMEDIO)', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                Text(
                  (_promedioCompetencias * 0.30).toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaRow(ColorScheme scheme, List<Map<String, dynamic>> items, int index, String labelKey, String notaKey, {String? subtitleKey}) {
    final item = items[index];
    final nota = item[notaKey] as int?;
    final subtitle = subtitleKey != null ? item[subtitleKey]?.toString() : null;
    final hasSubtitle = subtitle != null && subtitle.trim().isNotEmpty;
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
                  item[labelKey]?.toString() ?? '—',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<int>(
              value: nota,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              hint: const Text('1-5'),
              items: [1, 2, 3, 4, 5]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) {
                setState(() => item[notaKey] = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComentarios(ColorScheme scheme) {
    return Card(
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
            TextFormField(
              controller: _comentarioEvalController,
              decoration: const InputDecoration(
                hintText: 'Escriba sus comentarios...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'COMENTARIOS DEL EVALUADO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _comentarioEvaladoController,
              decoration: const InputDecoration(
                hintText: 'Comentarios del colaborador (opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados(ColorScheme scheme) {
    return Card(
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
                    _puntajeTotal.toStringAsFixed(2),
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
                    _rentas.toStringAsFixed(_rentas == _rentas.roundToDouble() ? 0 : 1),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTrabajo(ColorScheme scheme) {
    return Card(
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
                  width: 80,
                  child: Text('Objetivo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Acciones esperadas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Text('Fecha límite', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_planTrabajo.length, (i) {
              final p = _planTrabajo[i];
              final opciones = _aspectosOpcionesLabels;
              final int? valorSeleccionado = (p['aspectosamejorar'] is int) ? p['aspectosamejorar'] as int : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        value: (valorSeleccionado != null && valorSeleccionado >= 0 && valorSeleccionado < opciones.length)
                            ? valorSeleccionado
                            : null,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        isExpanded: true,
                        hint: const Text('Seleccionar'),
                        items: [
                          for (int index = 0; index < opciones.length; index++)
                            DropdownMenuItem<int>(
                              value: index,
                              child: Text(opciones[index]),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            p['aspectosamejorar'] = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 220,
                      child: TextFormField(
                        initialValue: p['objetivo']?.toString(),
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onChanged: (v) => p['objetivo'] = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: p['accionesesperadas']?.toString(),
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onChanged: (v) => p['accionesesperadas'] = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 220,
                      child: InkWell(
                        onTap: () async {
                          final str = p['fechalimitetermino']?.toString().trim() ?? '';
                          DateTime initial = DateTime.now();
                          if (str.isNotEmpty) {
                            final parsed = DateTime.tryParse(str);
                            if (parsed != null) initial = parsed;
                          }
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 5),
                          );
                          if (picked != null) {
                            setState(() {
                              p['fechalimitetermino'] =
                                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            hintText: 'Seleccionar',
                            isDense: true,
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          isEmpty: (p['fechalimitetermino']?.toString().trim() ?? '').isEmpty,
                          child: Text(
                            p['fechalimitetermino']?.toString().trim() ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: (p['fechalimitetermino']?.toString().trim() ?? '').isEmpty
                                  ? scheme.onSurfaceVariant.withOpacity(0.7)
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() {
                _planTrabajo.add({'objetivo': '', 'accionesesperadas': '', 'aspectosamejorar': null, 'fechalimitetermino': ''});
              }),
              icon: const Icon(Icons.add),
              label: const Text('Agregar objetivo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmas(ColorScheme scheme) {
    return Card(
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
    );
  }
}
