import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CambiarClaveScreen extends StatefulWidget {
  const CambiarClaveScreen({super.key});

  @override
  State<CambiarClaveScreen> createState() => _CambiarClaveScreenState();
}

class _CambiarClaveScreenState extends State<CambiarClaveScreen> {
  final TextEditingController _claveActualController = TextEditingController();
  final TextEditingController _nuevaClaveController = TextEditingController();
  final TextEditingController _confirmarClaveController = TextEditingController();
  bool _cargando = false;
  String? _errorMensaje;
  bool _mostrarClaveActual = false;
  bool _mostrarNuevaClave = false;
  bool _mostrarConfirmarClave = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _claveActualController.dispose();
    _nuevaClaveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  String? _validarClave(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _cambiarClave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMensaje = null;
      _cargando = true;
    });

    try {
      String claveActual = _claveActualController.text;
      String nuevaClave = _nuevaClaveController.text;
      String confirmarClave = _confirmarClaveController.text;

      if (nuevaClave != confirmarClave) {
        setState(() {
          _errorMensaje = "Las nuevas contraseñas no coinciden";
          _cargando = false;
        });
        return;
      }

      await AuthService().cambiarClave(claveActual, nuevaClave);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Contraseña cambiada con éxito"),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMensaje = "Error al cambiar la contraseña: ${e.toString()}";
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cambiar Contraseña"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
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
                          'Ingresa tus Contraseñas',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _claveActualController,
                          obscureText: !_mostrarClaveActual,
                          validator: _validarClave,
                          decoration: InputDecoration(
                            labelText: "Contraseña actual",
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarClaveActual ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarClaveActual = !_mostrarClaveActual;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nuevaClaveController,
                          obscureText: !_mostrarNuevaClave,
                          validator: _validarClave,
                          decoration: InputDecoration(
                            labelText: "Nueva contraseña",
                            prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarNuevaClave ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarNuevaClave = !_mostrarNuevaClave;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmarClaveController,
                          obscureText: !_mostrarConfirmarClave,
                          validator: _validarClave,
                          decoration: InputDecoration(
                            labelText: "Confirmar nueva contraseña",
                            prefixIcon: const Icon(Icons.lock_clock, color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarConfirmarClave ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarConfirmarClave = !_mostrarConfirmarClave;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMensaje != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMensaje!,
                              style: const TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _cargando ? null : _cambiarClave,
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
                          children: const [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Cambiar Contraseña",
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