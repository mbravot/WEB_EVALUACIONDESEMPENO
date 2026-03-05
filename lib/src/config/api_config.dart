/// Configuración centralizada de la API.
/// Cambia aquí la URL base para que todos los servicios la usen.
class ApiConfig {
  ApiConfig._();

  /// URL base de la API (sin barra final).
  /// Ejemplo: https://mi-servidor.com/api o http://192.168.1.196:5000/api
  static const String baseUrl = 'http://192.168.1.196:5000/api';

  // Opcional: si más adelante usas .env:
  // static String get baseUrl => dotenv.env['API_URL'] ?? 'http://192.168.1.196:5000/api';
}
