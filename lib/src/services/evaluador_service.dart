import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

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
}
