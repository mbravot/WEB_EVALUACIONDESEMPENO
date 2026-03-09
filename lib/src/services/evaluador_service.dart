import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'funciones_service.dart';

class EvaluadorService {
  static final AuthService _authService = AuthService();

  /// GET /api/evaluador/evaluaciones-pendientes
  /// Requiere JWT. Lista de colaboradores que el usuario logueado debe evaluar,
  /// con indicador realizada (true/false) e id_evaluacion_realizada cuando aplica.
  static Future<List<Map<String, dynamic>>> getEvaluacionesPendientes() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/evaluador/evaluaciones-pendientes'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    developer.log('GET evaluaciones-pendientes: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final body = response.body;
      developer.log('Error evaluaciones-pendientes: $body');
      throw Exception(
        body.isNotEmpty ? body : 'Error al cargar evaluaciones (${response.statusCode})',
      );
    }
  }

  /// GET /api/evaluador/mis-evaluaciones
  /// Requiere JWT. Devuelve la lista de evaluaciones realizadas por el usuario logueado.
  static Future<List<Map<String, dynamic>>> getMisEvaluaciones() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/evaluador/mis-evaluaciones'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    developer.log('GET mis-evaluaciones: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final body = response.body;
      developer.log('Error mis-evaluaciones: $body');
      throw Exception(
        body.isNotEmpty ? body : 'Error al cargar evaluaciones (${response.statusCode})',
      );
    }
  }

  /// POST /api/evaluador/evaluaciones
  /// Crea una evaluación de desempeño.
  /// Requiere JWT (Authorization: Bearer <token>); solo puede crear el usuario
  /// que sea id_usuarioevaluador para el par (id_evaluador, id_evaluado) en la dimensión.
  ///
  /// Body mínimo: id_evaluador, id_evaluado, id_cargoevaluador, id_cargoevaluado, fecha, notafinal.
  /// Opcionales: id_sucursal, comentarioevaluador, comentarioevaluado, factorbono,
  ///             firmaevaluador, firmaevaluado, competencias[], funciones[], plan_trabajo[].
  /// Los IDs deben coincidir con GET /api/evaluador/evaluaciones-pendientes.
  /// 201 → { "id_evaluacion": "uuid", "mensaje": "..." }
  /// 409 → ya existe evaluación para ese par

  /// Funciones del cargo: usa GET /api/funciones/cargo/<id_cargo> y devuelve
  /// formato esperado por crear evaluación (id_cargofuncion = id pivot, nombre = nombre_funcion).
  static Future<List<Map<String, dynamic>>> getFuncionesCargo(int idCargo) async {
    final lista = await FuncionesService.getByCargo(idCargo);
    return lista
        .map((e) => {
              'id_cargofuncion': e['id'],
              'nombre': e['nombre_funcion'] ?? e['nombre'] ?? 'Función',
            })
        .toList();
  }

  /// GET /api/evaluador/cargos/{id}/competencias
  /// Lista competencias asociadas al cargo (varían por cargo).
  static Future<List<Map<String, dynamic>>> getCompetenciasCargo(int idCargo) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/evaluador/cargos/$idCargo/competencias'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    developer.log('GET cargos/$idCargo/competencias: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (response.statusCode == 404) return [];
    throw Exception(response.body.isNotEmpty ? response.body : 'Error al cargar competencias');
  }

  static Future<Map<String, dynamic>> crearEvaluacion(Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/evaluador/evaluaciones'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    developer.log('POST evaluador/evaluaciones: ${response.statusCode}');
    developer.log('Body competencias: ${body['competencias']}');

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    if (response.statusCode == 409) {
      throw Exception('Ya existe una evaluación para este evaluador y colaborador.');
    }
    final respBody = response.body;
    developer.log('Error crear evaluación: $respBody');
    throw Exception(
      respBody.isNotEmpty ? respBody : 'Error al crear evaluación (${response.statusCode})',
    );
  }

  /// PUT o PATCH /api/evaluador/evaluaciones/<id_evaluacion>
  /// Solo puede editar el usuario que es id_usuarioevaluador de esa evaluación.
  /// Body (todos opcionales): fecha, comentarioevaluador, comentarioevaluado, notafinal, factorbono,
  /// firmaevaluador, firmaevaluado, id_sucursal. Si envías competencias/funciones/plan_trabajo
  /// se reemplazan los actuales (mismo formato que al crear).
  /// 200: { "id_evaluacion": "...", "mensaje": "Evaluación actualizada correctamente" }. 404: no existe o sin permiso.
  static Future<void> actualizarEvaluacion(String idEvaluacion, Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/evaluador/evaluaciones/$idEvaluacion'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    developer.log('PUT evaluador/evaluaciones/$idEvaluacion: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) return;
    final respBody = response.body;
    developer.log('Error actualizar evaluación: $respBody');
    throw Exception(
      respBody.isNotEmpty ? respBody : 'Error al actualizar evaluación (${response.statusCode})',
    );
  }

  /// DELETE /api/evaluador/evaluaciones/<id_evaluacion>
  /// Solo puede borrar el usuario que es id_usuarioevaluador. 200: { "mensaje": "Evaluación eliminada correctamente" }. 404: no existe o sin permiso.
  static Future<void> eliminarEvaluacion(String idEvaluacion) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No autorizado');

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/evaluador/evaluaciones/$idEvaluacion'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    developer.log('DELETE evaluador/evaluaciones/$idEvaluacion: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) return;
    final respBody = response.body;
    developer.log('Error eliminar evaluación: $respBody');
    throw Exception(
      respBody.isNotEmpty ? respBody : 'Error al eliminar evaluación (${response.statusCode})',
    );
  }
}
