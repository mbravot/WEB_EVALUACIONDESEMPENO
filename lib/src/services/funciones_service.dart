import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Servicio CRUD para funciones (rrhh_dim_funcion) y asignación cargo-función (rrhh_pivot_cargofuncion).
/// Todos los endpoints requieren JWT (Authorization: Bearer <token>).
class FuncionesService {
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

  /// GET /api/funciones
  /// Catálogo: lista todas las funciones (id, nombre) para combos.
  static Future<List<Map<String, dynamic>>> getCatalog() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/funciones'),
      headers: await _headers(),
    );
    developer.log('GET funciones (catálogo): ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al cargar catálogo de funciones (${response.statusCode})',
    );
  }

  /// POST /api/funciones o POST /api/funciones/catalogo
  /// Crea una función en el catálogo. Body: { "nombre": "..." }.
  /// 201: { "id", "nombre", "mensaje": "Función creada correctamente" }
  static Future<Map<String, dynamic>> createFuncion(String nombre) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/funciones/catalogo'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre.trim()}),
    );
    developer.log('POST funciones/catalogo (crear): ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al crear función (${response.statusCode})',
    );
  }

  /// PUT /api/funciones/catalogo/<id>
  /// Edita una función del catálogo. Body: { "nombre": "..." }. <id> = id en rrhh_dim_funcion.
  /// 404 si no existe.
  static Future<void> updateFuncionCatalogo(int id, String nombre) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/funciones/catalogo/$id'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre.trim()}),
    );
    developer.log('PUT funciones/catalogo/$id: ${response.statusCode}');
    if (response.statusCode == 200) return;
    if (response.statusCode == 404) {
      throw Exception('Función no encontrada.');
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al actualizar función (${response.statusCode})',
    );
  }

  /// DELETE /api/funciones/catalogo/<id>
  /// Elimina una función del catálogo. <id> = id en rrhh_dim_funcion.
  /// 409 si está asignada a algún cargo. 404 si no existe.
  static Future<void> deleteFuncionCatalogo(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/funciones/catalogo/$id'),
      headers: await _headers(),
    );
    developer.log('DELETE funciones/catalogo/$id: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 409) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'No se puede eliminar: la función está asignada a uno o más cargos. Quite las asignaciones primero.',
      );
    }
    if (response.statusCode == 404) {
      throw Exception('Función no encontrada.');
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al eliminar función (${response.statusCode})',
    );
  }

  /// GET /api/funciones/cargo/<id_cargo>
  /// Lista las funciones asignadas a un cargo (pivot con nombre).
  /// Respuesta: [{ "id", "id_cargo", "id_funcion", "nombre_funcion" }, ...]
  static Future<List<Map<String, dynamic>>> getByCargo(int idCargo) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/funciones/cargo/$idCargo'),
      headers: await _headers(),
    );
    developer.log('GET funciones/cargo/$idCargo: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (response.statusCode == 404) return [];
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al cargar funciones del cargo (${response.statusCode})',
    );
  }

  /// POST /api/funciones/cargo/<id_cargo>
  /// Asigna una función al cargo. Body: { "id_funcion": 5 }.
  /// 409 si la función ya está asignada a ese cargo.
  static Future<void> assignToCargo(int idCargo, int idFuncion) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/funciones/cargo/$idCargo'),
      headers: await _headers(),
      body: json.encode({'id_funcion': idFuncion}),
    );
    developer.log('POST funciones/cargo/$idCargo: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 409) {
      throw Exception('Esa función ya está asignada a este cargo.');
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al asignar función (${response.statusCode})',
    );
  }

  /// PUT /api/funciones/<id>
  /// Actualiza la asignación (cambia id_funcion). Body: { "id_funcion": 7 }.
  static Future<void> update(int idPivot, int idFuncion) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/funciones/$idPivot'),
      headers: await _headers(),
      body: json.encode({'id_funcion': idFuncion}),
    );
    developer.log('PUT funciones/$idPivot: ${response.statusCode}');
    if (response.statusCode == 200) return;
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al actualizar función (${response.statusCode})',
    );
  }

  /// DELETE /api/funciones/<id>
  /// Elimina la asignación cargo-función (id = id del pivot).
  static Future<void> delete(int idPivot) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/funciones/$idPivot'),
      headers: await _headers(),
    );
    developer.log('DELETE funciones/$idPivot: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al eliminar asignación (${response.statusCode})',
    );
  }
}
