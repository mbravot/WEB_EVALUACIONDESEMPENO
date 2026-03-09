import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/evaluador_service.dart';
import '../widgets/main_scaffold.dart';
import 'evaluacion_detalle_screen.dart';

class EvaluadorScreen extends StatefulWidget {
  const EvaluadorScreen({super.key});

  @override
  State<EvaluadorScreen> createState() => _EvaluadorScreenState();
}

class _EvaluadorScreenState extends State<EvaluadorScreen> {
  List<Map<String, dynamic>> _evaluaciones = [];
  bool _cargando = true;
  String? _mensajeError;
  final TextEditingController _busquedaController = TextEditingController();
  final FocusNode _busquedaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
    _busquedaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _busquedaFocus.dispose();
    super.dispose();
  }

  /// Filtra colaboradores por nombre, correo, cargo, sucursal o nivel.
  List<Map<String, dynamic>> get _evaluacionesFiltradas {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) return _evaluaciones;
    return _evaluaciones.where((e) {
      final nombre = (e['evaluado_nombre']?.toString() ?? '').toLowerCase();
      final correo = (e['correo_dim']?.toString() ?? '').toLowerCase();
      final cargo = ((e['cargo'] ?? e['cargo_evaluado'])?.toString() ?? '').toLowerCase();
      final sucursal = ((e['sucursal'] ?? e['sucursal_nombre'])?.toString() ?? '').toLowerCase();
      final nivel = ((e['nivel'] ?? e['nivel_nombre'])?.toString() ?? '').toLowerCase();
      return nombre.contains(q) ||
          correo.contains(q) ||
          cargo.contains(q) ||
          sucursal.contains(q) ||
          nivel.contains(q);
    }).toList();
  }

  Future<void> _cargarEvaluaciones() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final lista = await EvaluadorService.getEvaluacionesPendientes();
      if (!mounted) return;
      setState(() {
        _evaluaciones = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MainScaffold(
      title: 'Mis Evaluaciones',
      onRefresh: _cargarEvaluaciones,
      drawer: null,
      body: RefreshIndicator(
        onRefresh: _cargarEvaluaciones,
        color: scheme.primary,
        child: _cargando
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando colaboradores a evaluar...',
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
                    if (_mensajeError != null) ...[
                      Card(
                        color: scheme.errorContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: scheme.error, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _mensajeError!,
                                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, color: scheme.onErrorContainer),
                                onPressed: _cargarEvaluaciones,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Buscador de colaboradores
                    if (!_cargando && _evaluaciones.isNotEmpty) ...[
                      TextField(
                        controller: _busquedaController,
                        focusNode: _busquedaFocus,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, correo, cargo, sucursal...',
                          prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                          suffixIcon: _busquedaController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: scheme.onSurfaceVariant),
                                  onPressed: () {
                                    _busquedaController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_busquedaController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_evaluacionesFiltradas.length} de ${_evaluaciones.length} colaboradores',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else
                        const SizedBox(height: 16),
                    ],
                    if (_evaluaciones.isEmpty && _mensajeError == null)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes colaboradores asignados para evaluar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_evaluacionesFiltradas.isEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(Icons.search_off, size: 40, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Ningún colaborador coincide con la búsqueda',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _busquedaController.clear(),
                                icon: const Icon(Icons.clear_all, size: 20),
                                label: const Text('Limpiar'),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final evaluado = e['evaluado_nombre']?.toString() ?? '—';
    final correo = e['correo_dim']?.toString();
    final realizada = e['realizada'] == true;
    final cargo = e['cargo']?.toString() ?? e['cargo_evaluado']?.toString();
    final sucursal = e['sucursal']?.toString() ?? e['sucursal_nombre']?.toString();
    final nivel = e['nivel']?.toString() ?? e['nivel_nombre']?.toString();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: realizada
                      ? AppTheme.successColor.withOpacity(0.15)
                      : scheme.primary.withOpacity(0.15),
                  child: Icon(
                    Icons.person,
                    color: realizada ? AppTheme.successColor : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluado,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (correo != null && correo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          correo,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (cargo != null && cargo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cargo,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: realizada
                        ? AppTheme.successColor.withOpacity(0.12)
                        : AppTheme.warningColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    realizada ? 'Realizada' : 'Pendiente',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: realizada ? AppTheme.successColor : AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
            if ((sucursal != null && sucursal.isNotEmpty) || (nivel != null && nivel.isNotEmpty)) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: scheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (sucursal != null && sucursal.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          sucursal,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  if (nivel != null && nivel.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          nivel,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final actualizado = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => EvaluacionDetalleScreen(
                        evaluacion: e,
                        realizada: realizada,
                      ),
                    ),
                  );
                  if (actualizado == true && context.mounted) {
                    _cargarEvaluaciones();
                  }
                },
                icon: Icon(
                  realizada ? Icons.visibility_outlined : Icons.edit_note,
                  size: 20,
                ),
                label: Text(realizada ? 'Ver evaluación' : 'Realizar evaluación'),
                style: FilledButton.styleFrom(
                  backgroundColor: realizada
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
