import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import 'sucursal_selector.dart';
import 'user_info.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Widget? drawer;
  final VoidCallback? onRefresh;

  const MainScaffold({
    Key? key,
    required this.body,
    this.title,
    this.bottom,
    this.actions,
    this.drawer,
    this.onRefresh,
  }) : super(key: key);

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: scheme.error, size: 28),
            const SizedBox(width: 8),
            Text('Cerrar Sesión', style: TextStyle(color: scheme.onSurface)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(fontSize: 16, color: scheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(fontSize: 16, color: scheme.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleRefresh(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text('Actualizando...', style: TextStyle(color: scheme.onPrimary)),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: scheme.primary,
      ),
    );

    try {
      // Ejecutar callback personalizado si existe
      if (onRefresh != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        onRefresh!();
      } else {
        // Actualización por defecto
        await authProvider.checkAuthStatus();
      }

      // Mostrar mensaje de éxito
      if (context.mounted) {
        final s = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: s.onPrimary),
                const SizedBox(width: 8),
                Text('Página actualizada', style: TextStyle(color: s.onPrimary)),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

    } catch (e) {
      // Si el token expiró, cerrar sesión y enviar al login.
      if (await MainScaffold.handleTokenExpiredIfNeeded(context, e)) {
        return;
      }
      // Otros errores: solo mostrar mensaje
      if (context.mounted) {
        final s = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: s.onError),
                const SizedBox(width: 8),
                Text('Error al actualizar: $e', style: TextStyle(color: s.onError)),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: s.error,
          ),
        );
      }
    }
  }

  /// Manejo centralizado cuando el backend responde que el token ha expirado.
  /// Devuelve true si ya se manejó el error y no hay que seguir procesándolo.
  static Future<bool> handleTokenExpiredIfNeeded(
    BuildContext context,
    Object error,
  ) async {
    final message = error.toString().toLowerCase();
    if (!message.contains('token expirado') &&
        !message.contains('token_expirado') &&
        !message.contains('jwt expired') &&
        !message.contains('token has expired')) {
      return false;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tu sesión ha expirado. Inicia sesión nuevamente.'),
          backgroundColor: scheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await authProvider.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'App Base Web'),
        bottom: bottom,
        actions: [
          const UserInfo(),
          const SucursalSelector(),
          if (actions != null) ...actions!,
          // Botón de actualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _handleRefresh(context),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.yellow[700]),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: () => _confirmarCerrarSesion(context),
          ),
        ],
      ),
      drawer: drawer,
      body: body,
    );
  }
} 