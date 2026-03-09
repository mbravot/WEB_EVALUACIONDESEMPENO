import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Servicio CRUD para cargos (rrhh_dim_cargo). Prefijo /api/cargos. Requiere JWT.
class CargosService {
  static final AuthService _authService = AuthService();

  static Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/cargos - Lista todos los cargos.
  static Future<List<Map<String, dynamic>>> getList() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cargos'),
      headers: await _headers(),
    );
    developer.log('GET cargos: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al cargar cargos (${response.statusCode})',
    );
  }

  /// GET /api/cargos/<id> - Devuelve un cargo por id.
  static Future<Map<String, dynamic>> getById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cargos/$id'),
      headers: await _headers(),
    );
    developer.log('GET cargos/$id: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    if (response.statusCode == 404) throw Exception('Cargo no encontrado.');
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al obtener cargo (${response.statusCode})',
    );
  }

  /// POST /api/cargos - Crea un cargo. Body: { "nombre": "...", "nivel": 1 }. nivel opcional.
  /// 201: { "id", "nombre", "nivel", "mensaje": "Cargo creado correctamente" }
  static Future<Map<String, dynamic>> create(String nombre, {int? nivel}) async {
    final body = <String, dynamic>{'nombre': nombre.trim()};
    if (nivel != null) body['nivel'] = nivel;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cargos'),
      headers: await _headers(),
      body: json.encode(body),
    );
    developer.log('POST cargos: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al crear cargo (${response.statusCode})',
    );
  }

  /// PUT /api/cargos/<id> - Actualiza un cargo. Body: { "nombre"?, "nivel"? }.
  static Future<Map<String, dynamic>> update(int id, {String? nombre, int? nivel}) async {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre.trim();
    if (nivel != null) body['nivel'] = nivel;
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/cargos/$id'),
      headers: await _headers(),
      body: json.encode(body),
    );
    developer.log('PUT cargos/$id: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    if (response.statusCode == 404) throw Exception('Cargo no encontrado.');
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al actualizar cargo (${response.statusCode})',
    );
  }

  /// DELETE /api/cargos/<id>. Puede fallar con 409 si está referenciado (pivot, colaboradores, etc.).
  static Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/cargos/$id'),
      headers: await _headers(),
    );
    developer.log('DELETE cargos/$id: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 409) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'No se puede eliminar: el cargo está en uso (funciones asignadas o colaboradores).',
      );
    }
    if (response.statusCode == 404) throw Exception('Cargo no encontrado.');
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al eliminar cargo (${response.statusCode})',
    );
  }
}
