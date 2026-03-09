import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Servicio para competencias: catálogo, competencia-nivel y asignación a cargos.
/// Prefijo /api/competencias. Todos los endpoints requieren JWT.
class CompetenciasService {
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

  // --- Catálogo (rrhh_dim_competencia) ---

  /// GET /api/competencias
  static Future<List<Map<String, dynamic>>> getCatalog() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/competencias'),
      headers: await _headers(),
    );
    developer.log('GET competencias: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception(
      response.body.isNotEmpty ? response.body : 'Error al cargar competencias (${response.statusCode})',
    );
  }

  /// GET /api/competencias/<id>
  static Future<Map<String, dynamic>> getById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/competencias/$id'),
      headers: await _headers(),
    );
    developer.log('GET competencias/$id: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    if (response.statusCode == 404) throw Exception('Competencia no encontrada.');
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// POST /api/competencias — body: { "nombre": "..." }
  static Future<Map<String, dynamic>> create(String nombre) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/competencias'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre.trim()}),
    );
    developer.log('POST competencias: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Error al crear competencia (${response.statusCode})');
  }

  /// PUT /api/competencias/<id> — body: { "nombre": "..." }
  static Future<void> update(int id, String nombre) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/competencias/$id'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre.trim()}),
    );
    developer.log('PUT competencias/$id: ${response.statusCode}');
    if (response.statusCode == 200) return;
    if (response.statusCode == 404) throw Exception('Competencia no encontrada.');
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// DELETE /api/competencias/<id> — 409 si tiene niveles definidos
  static Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/competencias/$id'),
      headers: await _headers(),
    );
    developer.log('DELETE competencias/$id: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 409) throw Exception('No se puede eliminar: tiene niveles definidos.');
    if (response.statusCode == 404) throw Exception('Competencia no encontrada.');
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  // --- Competencia–nivel (rrhh_dim_competencianivel) ---

  /// GET /api/competencias/niveles — query: ?id_nivel=1 y/o ?id_competencia=1
  static Future<List<Map<String, dynamic>>> getNiveles({int? idNivel, int? idCompetencia}) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/competencias/niveles');
    final q = <String, String>{};
    if (idNivel != null) q['id_nivel'] = idNivel.toString();
    if (idCompetencia != null) q['id_competencia'] = idCompetencia.toString();
    if (q.isNotEmpty) uri = uri.replace(queryParameters: q);
    final response = await http.get(uri, headers: await _headers());
    developer.log('GET competencias/niveles: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// GET /api/competencias/niveles/<id_nivel> — opciones para cargos de ese nivel
  static Future<List<Map<String, dynamic>>> getNivelesByNivel(int idNivel) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/competencias/niveles/$idNivel'),
      headers: await _headers(),
    );
    developer.log('GET competencias/niveles/$idNivel: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (response.statusCode == 404) return [];
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// POST /api/competencias/niveles — body: { "id_competencia", "id_nivel", "definicion" }
  static Future<Map<String, dynamic>> createNivel(int idCompetencia, int idNivel, String definicion) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/competencias/niveles'),
      headers: await _headers(),
      body: json.encode({
        'id_competencia': idCompetencia,
        'id_nivel': idNivel,
        'definicion': definicion.trim(),
      }),
    );
    developer.log('POST competencias/niveles: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// PUT /api/competencias/niveles/<id> — body: { "definicion": "..." }
  static Future<void> updateNivel(int id, String definicion) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/competencias/niveles/$id'),
      headers: await _headers(),
      body: json.encode({'definicion': definicion.trim()}),
    );
    developer.log('PUT competencias/niveles/$id: ${response.statusCode}');
    if (response.statusCode == 200) return;
    if (response.statusCode == 404) throw Exception('No encontrado.');
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// DELETE /api/competencias/niveles/<id> — 409 si está asignado a algún cargo
  static Future<void> deleteNivel(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/competencias/niveles/$id'),
      headers: await _headers(),
    );
    developer.log('DELETE competencias/niveles/$id: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 409) throw Exception('No se puede eliminar: está asignado a algún cargo.');
    if (response.statusCode == 404) throw Exception('No encontrado.');
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  // --- Asignación a cargos (rrhh_pivot_cargocompetencia) ---

  /// GET /api/competencias/cargo/<id_cargo>/disponibles
  /// Competencia-nivel asignables al cargo (id_nivel = nivel del cargo). 400 si el cargo no tiene nivel.
  static Future<List<Map<String, dynamic>>> getDisponiblesByCargo(int idCargo) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/competencias/cargo/$idCargo/disponibles'),
      headers: await _headers(),
    );
    developer.log('GET competencias/cargo/$idCargo/disponibles: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (response.statusCode == 400) {
      throw Exception(response.body.isNotEmpty ? response.body : 'El cargo no tiene nivel. Asigne nivel al cargo.');
    }
    if (response.statusCode == 404) return [];
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// GET /api/competencias/cargo/<id_cargo>
  static Future<List<Map<String, dynamic>>> getByCargo(int idCargo) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/competencias/cargo/$idCargo'),
      headers: await _headers(),
    );
    developer.log('GET competencias/cargo/$idCargo: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (response.statusCode == 404) return [];
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// POST /api/competencias/cargo/<id_cargo> — body: { "id_competencianivel": 5 }
  static Future<void> assignToCargo(int idCargo, int idCompetenciaNivel) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/competencias/cargo/$idCargo'),
      headers: await _headers(),
      body: json.encode({'id_competencianivel': idCompetenciaNivel}),
    );
    developer.log('POST competencias/cargo/$idCargo: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 400) {
      throw Exception(response.body.isNotEmpty ? response.body : 'El nivel del cargo no coincide con la competencia.');
    }
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }

  /// DELETE /api/competencias/asignacion/<id> — id = id del pivot
  static Future<void> deleteAsignacion(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/competencias/asignacion/$id'),
      headers: await _headers(),
    );
    developer.log('DELETE competencias/asignacion/$id: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(response.body.isNotEmpty ? response.body : 'Error (${response.statusCode})');
  }
}
