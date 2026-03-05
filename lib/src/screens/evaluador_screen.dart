import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/evaluador_service.dart';
import '../widgets/main_scaffold.dart';

class EvaluadorScreen extends StatefulWidget {
  const EvaluadorScreen({super.key});

  @override
  State<EvaluadorScreen> createState() => _EvaluadorScreenState();
}

class _EvaluadorScreenState extends State<EvaluadorScreen> {
  List<Map<String, dynamic>> _evaluaciones = [];
  bool _cargando = true;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
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
                    else
                      ..._evaluaciones.map((e) => _buildCard(context, e)),
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
          ],
        ),
      ),
    );
  }
}
