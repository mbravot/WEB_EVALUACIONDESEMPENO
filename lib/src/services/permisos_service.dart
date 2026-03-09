import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Servicio para consultar permisos de acceso.
///
/// El acceso a las pantallas "Consultar evaluaciones", "Funciones del cargo" y "Competencias por cargo"
/// se controla con el permiso id_permiso = 7 en la tabla usuario_dim_permiso, asignado al usuario
/// mediante la tabla usuario_pivot_permiso_usuario (id_usuario, id_permiso).
/// El backend expone GET /api/permisos/acceso-pantalla y responde acceso_permitido según exista
/// una fila activa en usuario_pivot_permiso_usuario con id_permiso = '7' para el usuario logueado.
class PermisosService {
  static final AuthService _authService = AuthService();

  /// GET /api/permisos/acceso-pantalla
  /// Comprueba si el usuario tiene id_permiso = 7 en usuario_pivot_permiso_usuario (FK a usuario_dim_permiso).
  /// Respuesta: { "acceso_permitido": true|false, "permiso_id": "7" }
  static Future<bool> getAccesoPantalla() async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/permisos/acceso-pantalla'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    developer.log('GET permisos/acceso-pantalla: ${response.statusCode}');

    if (response.statusCode != 200) return false;
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final permitido = data['acceso_permitido'];
      return permitido == true;
    } catch (_) {
      return false;
    }
  }
}
