import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'cambiar_clave_screen.dart';
import 'cambiar_sucursal_screen.dart';
import 'evaluador_screen.dart';
import 'evaluaciones_screen.dart';
import 'dashboard_screen.dart';
import 'funciones_screen.dart';
import 'competencias_screen.dart';
import '../services/permisos_service.dart';
import '../services/evaluador_service.dart';
import '../widgets/sucursal_selector.dart';
import '../widgets/main_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  /// Permiso id=7 (usuario_dim_permiso): acceso a Consultar evaluaciones, Funciones del cargo, Competencias por cargo.
  bool _accesoPantallaPermitido = false;

  /// Estadísticas del evaluador: evaluaciones asignadas (pendientes + realizadas).
  int _totalEvaluaciones = 0;
  int _evaluacionesRealizadas = 0;
  int _evaluacionesPendientes = 0;
  bool _cargandoEstadisticas = true;
  String? _errorEstadisticas;

  @override
  void initState() {
    super.initState();
    _cargarPermisoPantalla();
    _cargarEstadisticasEvaluaciones();
  }

  Future<void> _cargarPermisoPantalla() async {
    final permitido = await PermisosService.getAccesoPantalla();
    if (mounted) setState(() => _accesoPantallaPermitido = permitido);
  }

  Future<void> _cargarEstadisticasEvaluaciones() async {
    if (!mounted) return;
    setState(() {
      _cargandoEstadisticas = true;
      _errorEstadisticas = null;
    });
    try {
      final lista = await EvaluadorService.getEvaluacionesPendientes();
      if (!mounted) return;
      final realizadas = lista.where((e) => e['realizada'] == true).length;
      setState(() {
        _totalEvaluaciones = lista.length;
        _evaluacionesRealizadas = realizadas;
        _evaluacionesPendientes = lista.length - realizadas;
        _cargandoEstadisticas = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Si el token expiró, cerrar sesión y enviar al login.
      if (await MainScaffold.handleTokenExpiredIfNeeded(context, e)) {
        return;
      }
      setState(() {
        _errorEstadisticas = e.toString().replaceFirst('Exception: ', '');
        _cargandoEstadisticas = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, AuthProvider authProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.errorColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Cerrar Sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildSearchField() {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar en el menú...',
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: InputBorder.none,
        prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
      ),
      style: TextStyle(color: scheme.onSurface),
      onChanged: (value) {
        // No hacer nada aquí para evitar SnackBars molestos
      },
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Búsqueda completada: $value'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        setState(() => _isSearching = false);
      },
    );
  }

  List<Widget> _buildAppBarActions(ThemeProvider themeProvider, AuthProvider authProvider) {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              setState(() => _isSearching = false);
            } else {
              _searchController.clear();
            }
          },
        ),
      ];
    }

    return [
      // Botón de búsqueda
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearching = true),
      ),
      // Selector de sucursal global
      const SucursalSelector(),
      // Botón de tema
      IconButton(
        icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
        onPressed: () => themeProvider.toggleTheme(),
      ),
      // Botón de cerrar sesión
      IconButton(
        icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () => _confirmarCerrarSesion(context, authProvider),
      ),
    ];
  }

  Widget _buildDashboardContent() {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _cargarEstadisticasEvaluaciones,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de bienvenida
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.accentColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Evaluación de Desempeño',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resumen de las evaluaciones que debes realizar como evaluador.',
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Estadísticas de evaluaciones
            Text(
              'Mis evaluaciones asignadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_cargandoEstadisticas)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Cargando estadísticas...',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorEstadisticas != null)
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
                          _errorEstadisticas!,
                          style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: _cargarEstadisticasEvaluaciones,
                        child: Text('Reintentar', style: TextStyle(color: scheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total asignadas',
                      '$_totalEvaluaciones',
                      Icons.people_outline,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pendientes',
                      '$_evaluacionesPendientes',
                      Icons.pending_actions,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Realizadas',
                      '$_evaluacionesRealizadas',
                      Icons.check_circle_outline,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Avance',
                      _totalEvaluaciones > 0
                          ? '${((_evaluacionesRealizadas / _totalEvaluaciones) * 100).round()}%'
                          : '0%',
                      Icons.trending_up,
                      AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
              if (_totalEvaluaciones > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _totalEvaluaciones > 0 ? _evaluacionesRealizadas / _totalEvaluaciones : 0,
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 28),
            // Acción principal
            Text(
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EvaluadorScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                        child: Icon(Icons.assignment, color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis Evaluaciones',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _evaluacionesPendientes > 0
                                  ? 'Tienes $_evaluacionesPendientes evaluación(es) pendiente(s)'
                                  : 'Ver y gestionar tus evaluaciones',
                              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'Inicio',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
        await _cargarEstadisticasEvaluaciones();
      },
      drawer: _buildDrawer(context, authProvider, themeProvider),
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? _buildSearchField()
                : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, ThemeProvider themeProvider) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: scheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.onPrimary,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.userData?['nombre'] ?? 'Usuario',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sucursal: ${authProvider.userData?['nombre_sucursal'] ?? 'No especificada'}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: AppTheme.primaryColor),
            title: const Text('Mis Evaluaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EvaluadorScreen()),
              );
            },
          ),
          if (_accesoPantallaPermitido) ...[
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppTheme.primaryColor),
              title: const Text('Dashboard'),
              subtitle: const Text('Estadísticas globales · Admin/RRHH'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind, color: AppTheme.primaryColor),
              title: const Text('Consultar evaluaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EvaluacionesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline, color: AppTheme.primaryColor),
              title: const Text('Funciones del cargo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FuncionesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_outlined, color: AppTheme.primaryColor),
              title: const Text('Competencias por cargo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompetenciasScreen()),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.business, color: AppTheme.primaryColor),
            title: const Text('Cambiar Sucursal'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CambiarSucursalScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: AppTheme.warningColor),
            title: const Text('Cambiar Contraseña'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CambiarClaveScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              _confirmarCerrarSesion(context, authProvider);
            },
          ),
        ],
      ),
    );
  }
} 