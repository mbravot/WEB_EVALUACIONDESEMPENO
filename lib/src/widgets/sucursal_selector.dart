import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SucursalSelector extends StatefulWidget {
  const SucursalSelector({super.key});

  @override
  State<SucursalSelector> createState() => _SucursalSelectorState();
}

class _SucursalSelectorState extends State<SucursalSelector> {
  List<Map<String, dynamic>> _sucursales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sucursales = await authProvider.getSucursalesDisponibles();
      setState(() {
        _sucursales = sucursales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sucursales: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarSucursal(BuildContext context, String? idSucursalActual) async {
    if (_sucursales.isEmpty) return;
    final seleccion = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona una sucursal'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _sucursales.length,
              itemBuilder: (context, index) {
                final suc = _sucursales[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: Text(suc['nombre'] ?? suc['nombre_sucursal'] ?? 'Sin nombre'),
                  selected: suc['id'].toString() == idSucursalActual,
                  onTap: () => Navigator.pop(context, suc),
                );
              },
            ),
          ),
        );
      },
    );
    if (seleccion != null && seleccion['id'].toString() != idSucursalActual) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final exito = await authProvider.cambiarSucursal(seleccion['id'].toString());
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Sucursal cambiada a ${seleccion['nombre'] ?? seleccion['nombre_sucursal']}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final idSucursalActual = authProvider.userData?['id_sucursal']?.toString();
    final nombreSucursal = () {
      if (_sucursales.isNotEmpty && idSucursalActual != null) {
        final actual = _sucursales.firstWhere(
          (s) => s['id'].toString() == idSucursalActual,
          orElse: () => {},
        );
        return actual['nombre'] ?? actual['nombre_sucursal'] ?? 'Sucursal';
      }
      return authProvider.userData?['nombre_sucursal'] ?? 'Sucursal';
    }();

    return GestureDetector(
      onTap: _isLoading ? null : () => _seleccionarSucursal(context, idSucursalActual),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                )
              : Text(
                  nombreSucursal,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
} 