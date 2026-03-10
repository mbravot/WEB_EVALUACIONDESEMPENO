import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/evaluador_service.dart';
import '../services/permisos_service.dart';
import '../widgets/main_scaffold.dart';

/// Dashboard para administradores/RRHH: estadísticas sobre todas las evaluaciones realizadas.
/// Requiere permiso id=7 (mismo que Consultar evaluaciones, Funciones, Competencias).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _evaluaciones = [];
  /// Si el backend expone GET /api/evaluaciones/estadisticas, aquí vienen total_asignadas, realizadas, pendientes, por_sucursal.
  Map<String, dynamic>? _estadisticas;
  bool _cargando = true;
  String? _error;
  bool? _permisoOk;

  int get _totalAsignadas {
    if (_estadisticas != null) {
      final v = _estadisticas!['total_asignadas'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      if (s != null) return int.tryParse(s) ?? 0;
    }
    return 0;
  }

  int get _realizadas {
    if (_estadisticas != null) {
      final v = _estadisticas!['realizadas'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      if (s != null) return int.tryParse(s) ?? 0;
    }
    return _evaluaciones.length;
  }

  int get _pendientes {
    if (_estadisticas != null) {
      final v = _estadisticas!['pendientes'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      if (s != null) return int.tryParse(s) ?? 0;
    }
    final total = _totalAsignadas;
    if (total > 0) return total - _realizadas;
    return 0;
  }

  double get _porcentajeAvance {
    final total = _totalAsignadas;
    if (total <= 0) return 0;
    return (_realizadas / total).clamp(0.0, 1.0);
  }

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

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
      _estadisticas = null;
    });
    try {
      final stats = await EvaluadorService.getEstadisticasGlobales();
      if (!mounted) return;
      if (stats != null) {
        setState(() {
          _estadisticas = stats;
          _cargando = false;
        });
        return;
      }
      final lista = await EvaluadorService.getTodasEvaluaciones();
      if (!mounted) return;
      setState(() {
        _evaluaciones = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Si el token expiró, cerrar sesión y enviar al login.
      if (await MainScaffold.handleTokenExpiredIfNeeded(context, e)) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  /// Por sucursal: desde estadísticas (con total/realizadas/pendientes) o desde lista (solo realizadas).
  List<Map<String, dynamic>> get _porSucursalList {
    final porSuc = _estadisticas?['por_sucursal'];
    if (porSuc is List) {
      return porSuc.map((e) => Map<String, dynamic>.from(e is Map ? e as Map : {})).toList();
    }
    final count = <String, int>{};
    for (final e in _evaluaciones) {
      final suc = (e['sucursal'] ?? e['sucursal_ubicacion'])?.toString().trim();
      if (suc != null && suc.isNotEmpty) {
        count[suc] = (count[suc] ?? 0) + 1;
      }
    }
    return count.entries.map((e) => {'sucursal': e.key, 'realizadas': e.value, 'pendientes': 0, 'total': e.value}).toList();
  }

  static int _intFrom(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Evaluaciones realizadas este mes (año actual). Solo con lista cargada (sin endpoint estadísticas).
  int get _realizadasEsteMes {
    final now = DateTime.now();
    return _evaluaciones.where((e) {
      final f = e['fecha']?.toString();
      if (f == null || f.isEmpty) return false;
      final parts = f.split(RegExp(r'[-/]'));
      if (parts.length < 2) return false;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts.length >= 2 ? parts[1] : parts[0]);
      return y == now.year && m == now.month;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_permisoOk == false) {
      return MainScaffold(
        title: 'Dashboard',
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
      title: 'Dashboard',
      onRefresh: _cargar,
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: (_permisoOk != true || _cargando)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      _permisoOk == null ? 'Comprobando permiso...' : 'Cargando estadísticas...',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              Icon(Icons.error_outline, color: scheme.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
                                ),
                              ),
                              TextButton(
                                onPressed: _cargar,
                                child: Text('Reintentar', style: TextStyle(color: scheme.onErrorContainer)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        'Resumen general',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total a realizar',
                              '$_totalAsignadas',
                              Icons.assignment,
                              AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Realizadas',
                              '$_realizadas',
                              Icons.assignment_turned_in,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Pendientes',
                              '$_pendientes',
                              Icons.pending_actions,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Avance',
                              '${(_porcentajeAvance * 100).toStringAsFixed(0)}%',
                              Icons.trending_up,
                              AppTheme.infoColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _porcentajeAvance,
                          minHeight: 10,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                      if (_evaluaciones.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Este mes',
                          '$_realizadasEsteMes',
                          Icons.calendar_today,
                          AppTheme.infoColor,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Por sucursal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_porSucursalList.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _estadisticas == null
                                  ? 'No hay datos por sucursal en las evaluaciones cargadas.'
                                  : 'No hay datos por sucursal.',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        )
                      else
                        ...(_porSucursalList
                          ..sort((a, b) {
                            final ra = _intFrom(a['realizadas'] ?? a['total']);
                            final rb = _intFrom(b['realizadas'] ?? b['total']);
                            return rb.compareTo(ra);
                          })
                        ).map((e) {
                          final suc = (e['sucursal'] ?? '—').toString();
                          final total = _intFrom(e['total']);
                          final realizadas = _intFrom(e['realizadas']);
                          final pendientes = _intFrom(e['pendientes']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                child: Icon(Icons.business, color: AppTheme.primaryColor),
                              ),
                              title: Text(
                                suc,
                                style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurface),
                              ),
                              subtitle: (total > 0 || pendientes > 0)
                                  ? Text(
                                      'Realizadas: $realizadas · Pendientes: $pendientes${total > 0 ? ' · Total: $total' : ''}',
                                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                    )
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$realizadas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
