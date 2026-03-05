import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

// Sistema de logging condicional
void logInfo(String message) {
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    print("ℹ️ $message");
  }
}

void logError(String message) {
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    print("❌ $message");
  }
}

class CambiarSucursalScreen extends StatefulWidget {
  const CambiarSucursalScreen({super.key});

  @override
  State<CambiarSucursalScreen> createState() => _CambiarSucursalScreenState();
}

class _CambiarSucursalScreenState extends State<CambiarSucursalScreen> {
  List<Map<String, dynamic>> _sucursales = [];
  String? _sucursalSeleccionada;
  bool _cargando = false;
  String? _mensajeError;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    if (_isRefreshing) {
      setState(() => _cargando = true);
    }
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sucursales = await authProvider.getSucursalesDisponibles();
      final sucursalActual = authProvider.userData?['id_sucursal']?.toString();

      if (!mounted) return;

      setState(() {
        _sucursales = sucursales;
        _sucursalSeleccionada = sucursalActual;
        _mensajeError = null;
        _cargando = false;
      });
    } catch (e) {
      logError("Error al cargar sucursales: $e");
      if (!mounted) return;
      
      setState(() {
        _mensajeError = "No se pudieron cargar las sucursales.";
        _cargando = false;
      });
    }
  }

  Future<void> _guardarSucursal() async {
    if (_sucursalSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una sucursal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final exito = await authProvider.cambiarSucursal(_sucursalSeleccionada!);
      
      if (exito) {
        final sucursal = _sucursales.firstWhere(
          (s) => s['id'].toString() == _sucursalSeleccionada.toString(),
          orElse: () => {'nombre': 'Sucursal desconocida'},
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Sucursal cambiada a: ${sucursal['nombre']}'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("No se pudo cambiar la sucursal");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = "Error al actualizar sucursal: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        title: Text(
          "Cambiar Sucursal",
          style: TextStyle(color: scheme.onPrimary),
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : () {
              setState(() => _isRefreshing = true);
              _cargarSucursales();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          await _cargarSucursales();
          setState(() => _isRefreshing = false);
        },
        child: _cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando sucursales...',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecciona una Sucursal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_sucursales.isEmpty && !_cargando)
                              Center(
                                child: Text(
                                  'No hay sucursales disponibles',
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _sucursalSeleccionada,
                                onChanged: (nuevoValor) {
                                  setState(() {
                                    _sucursalSeleccionada = nuevoValor;
                                  });
                                },
                                items: _sucursales
                                    .map((s) => DropdownMenuItem<String>(
                                          value: s['id'].toString(),
                                          child: Text(s['nombre']),
                                        ))
                                    .toList(),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.business, color: AppTheme.primaryColor),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_mensajeError != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: scheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: scheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mensajeError!,
                                  style: TextStyle(color: scheme.onErrorContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _cargando ? null : _guardarSucursal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  "Guardar Cambios",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
} 