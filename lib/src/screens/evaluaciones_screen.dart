import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/evaluador_service.dart';
import '../services/permisos_service.dart';
import '../widgets/main_scaffold.dart';
import 'evaluacion_detalle_screen.dart';

/// Pantalla para administradores / RRHH: consulta de todas las evaluaciones (GET /api/evaluaciones).
/// Distinta a "Mis Evaluaciones", que solo muestra las del usuario logueado.
/// Filtros por sucursal y por evaluador (client-side).
class EvaluacionesScreen extends StatefulWidget {
  const EvaluacionesScreen({super.key});

  @override
  State<EvaluacionesScreen> createState() => _EvaluacionesScreenState();
}

class _EvaluacionesScreenState extends State<EvaluacionesScreen> {
  List<Map<String, dynamic>> _evaluaciones = [];
  bool _cargando = true;
  String? _error;
  /// null = comprobando permiso, false = sin permiso (id 7), true = permitido.
  bool? _permisoOk;

  /// Valores únicos extraídos de los datos para los filtros.
  List<String> _sucursales = [];
  List<String> _evaluadores = [];

  String? _filtroSucursal; // null = todas
  String? _filtroEvaluador; // null = todos

  @override
  void initState() {
    super.initState();
    _comprobarPermisoYcargar();
  }

  Future<void> _comprobarPermisoYcargar() async {
    final permitido = await PermisosService.getAccesoPantalla();
    if (!mounted) return;
    setState(() => _permisoOk = permitido);
    if (permitido) _cargar();
  }

  List<Map<String, dynamic>> get _evaluacionesFiltradas {
    return _evaluaciones.where((e) {
      if (_filtroSucursal != null) {
        final suc = (e['sucursal'] ?? e['sucursal_ubicacion'])?.toString() ?? '';
        if (suc != _filtroSucursal) return false;
      }
      if (_filtroEvaluador != null) {
        final ev = e['evaluador_nombre']?.toString() ?? '';
        if (ev != _filtroEvaluador) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await EvaluadorService.getTodasEvaluaciones();
      if (!mounted) return;
      final sucSet = <String>{};
      final evSet = <String>{};
      for (final e in lista) {
        final suc = (e['sucursal'] ?? e['sucursal_ubicacion'])?.toString().trim();
        if (suc != null && suc.isNotEmpty) sucSet.add(suc);
        final ev = e['evaluador_nombre']?.toString().trim();
        if (ev != null && ev.isNotEmpty) evSet.add(ev);
      }
      setState(() {
        _evaluaciones = lista;
        _sucursales = sucSet.toList()..sort();
        _evaluadores = evSet.toList()..sort();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_permisoOk == false) {
      return MainScaffold(
        title: 'Consultar evaluaciones',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: scheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'No tiene permiso para acceder a esta pantalla.',
                      style: TextStyle(fontSize: 16, color: scheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Volver'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MainScaffold(
      title: 'Consultar evaluaciones',
      onRefresh: _cargar,
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: scheme.primary,
        child: (_permisoOk != true || _cargando)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      _permisoOk == null ? 'Comprobando permiso...' : 'Cargando evaluaciones...',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: scheme.surfaceContainerHighest.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, color: scheme.primary, size: 28),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
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
                              IconButton(
                                icon: Icon(Icons.refresh, color: scheme.onErrorContainer),
                                onPressed: _cargar,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_cargando && _evaluaciones.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _filtroSucursal,
                              decoration: InputDecoration(
                                labelText: 'Sucursal',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                                ..._sucursales.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (v) => setState(() => _filtroSucursal = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _filtroEvaluador,
                              decoration: InputDecoration(
                                labelText: 'Evaluador',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                                ..._evaluadores.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (v) => setState(() => _filtroEvaluador = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_evaluacionesFiltradas.length} de ${_evaluaciones.length} evaluaciones',
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_cargando && _evaluaciones.isEmpty && _error == null)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No hay evaluaciones registradas',
                                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (!_cargando && _evaluacionesFiltradas.isEmpty && _evaluaciones.isNotEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list_off, size: 40, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Ninguna evaluación coincide con los filtros',
                                  style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._evaluacionesFiltradas.map((e) => _buildCard(context, e)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> e) {
    final scheme = Theme.of(context).colorScheme;
    final evaluado = e['evaluado_nombre']?.toString() ?? '—';
    final evaluador = e['evaluador_nombre']?.toString() ?? '—';
    final fecha = e['fecha']?.toString() ?? '—';
    final sucursal = (e['sucursal'] ?? e['sucursal_ubicacion'])?.toString();
    final cargoEvaluado = e['cargo_evaluado']?.toString();
    final notafinalRaw = e['notafinal'];
    double? notafinalNum;
    if (notafinalRaw is num) {
      notafinalNum = (notafinalRaw as num).toDouble();
    } else if (notafinalRaw != null) {
      notafinalNum = double.tryParse(notafinalRaw.toString().trim());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final eliminada = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => EvaluacionDetalleScreen(
                evaluacion: e,
                realizada: true,
                detallePrecargado: e,
                permisoAdminEditarEliminar: true,
              ),
            ),
          );
          if (eliminada == true && mounted) _cargar();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.successColor.withOpacity(0.15),
                    child: Icon(Icons.person, color: AppTheme.successColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evaluado,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
                        ),
                        if (cargoEvaluado != null && cargoEvaluado.isNotEmpty)
                          Text(
                            cargoEvaluado,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (notafinalNum != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notafinalNum.toStringAsFixed(2),
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: scheme.onPrimaryContainer),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Evaluador: $evaluador', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(fecha, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  if (sucursal != null && sucursal.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(sucursal, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver detalle',
                  style: TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
