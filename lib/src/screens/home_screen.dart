import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'cambiar_clave_screen.dart';
import 'cambiar_sucursal_screen.dart';
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
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Buscar en el menú...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        prefixIcon: Icon(Icons.search, color: Colors.black54),
      ),
      style: const TextStyle(color: Colors.black),
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
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () => _confirmarCerrarSesion(context, authProvider),
      ),
    ];
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
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
                        Icons.dashboard,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Bienvenido a tu Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta es tu aplicación base. Aquí puedes agregar las funcionalidades específicas que necesites.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sección de estadísticas rápidas
          const Text(
            'Estadísticas Rápidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Items',
                  '0',
                  Icons.inventory,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  '0',
                  Icons.pending,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completados',
                  '0',
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'En Proceso',
                  '0',
                  Icons.schedule,
                  AppTheme.infoColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sección de acciones rápidas
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(
                'Nuevo Item',
                Icons.add,
                AppTheme.primaryColor,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de nuevo item - Implementar según necesidades'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildActionCard(
                'Ver Reportes',
                Icons.assessment,
                AppTheme.accentColor,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de reportes - Implementar según necesidades'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildActionCard(
                'Configuración',
                Icons.settings,
                AppTheme.infoColor,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de configuración - Implementar según necesidades'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildActionCard(
                'Ayuda',
                Icons.help,
                AppTheme.warningColor,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de ayuda - Implementar según necesidades'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
      title: 'App Base Web',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.userData?['nombre'] ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sucursal: ${authProvider.userData?['nombre_sucursal'] ?? 'No especificada'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
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