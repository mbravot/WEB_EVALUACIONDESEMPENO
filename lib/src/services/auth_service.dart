import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://192.168.1.196:5000/api';
  final storage = const FlutterSecureStorage();

  //Login
  Future<Map<String, dynamic>> login(String usuario, String password) async {
    developer.log('Intentando login con usuario: $usuario');
    developer.log('URL de la API: $baseUrl/auth/login');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'usuario': usuario,
          'clave': password,
        }),
      );

      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Datos decodificados: $data');
        
        // Guardar el token
        await storage.write(key: 'token', value: data['access_token']);
        
        // Guardar los datos del usuario individualmente
        await storage.write(key: 'nombre', value: data['nombre'] ?? data['usuario']);
        await storage.write(key: 'id_sucursal', value: data['id_sucursal']?.toString());
        await storage.write(key: 'nombre_sucursal', value: data['sucursal_nombre']);
        await storage.write(key: 'id_rol', value: data['id_rol']?.toString());
        
        // Guardar los datos completos del usuario
        await storage.write(key: 'user_data', value: json.encode({
          'nombre': data['nombre'] ?? data['usuario'],
          'id_sucursal': data['id_sucursal'],
          'nombre_sucursal': data['sucursal_nombre'],
          'id_rol': data['id_rol'],
        }));

        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error de autenticación');
      }
    } catch (e) {
      developer.log('Error durante el login: $e');
      rethrow;
    }
  }

  //Cerrar sesión
  Future<void> logout() async {
    await storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userDataStr = await storage.read(key: 'user_data');
      if (userDataStr != null) {
        return json.decode(userDataStr);
      }
      return null;
    } catch (e) {
      developer.log('Error al obtener datos del usuario: $e');
      return null;
    }
  }

//Cambiar contraseña
  Future<void> cambiarClave(String claveActual, String nuevaClave) async {
    developer.log('Intentando cambiar contraseña');
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/cambiar-clave'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'clave_actual': claveActual,
          'nueva_clave': nuevaClave,
        }),
      );

      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Contraseña cambiada exitosamente');
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cambiar la contraseña');
      }
    } catch (e) {
      developer.log('Error durante el cambio de contraseña: $e');
      rethrow;
    }
  }

  // Obtener las sucursales disponibles del usuario
  Future<List<Map<String, dynamic>>> getSucursalesDisponibles() async {
    developer.log('Obteniendo sucursales disponibles');
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.get(
        Uri.parse('$baseUrl/sucursales/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener las sucursales');
      }
    } catch (e) {
      developer.log('Error al obtener sucursales: $e');
      rethrow;
    }
  }

  // Cambiar la sucursal activa del usuario
  Future<Map<String, dynamic>> cambiarSucursal(String idSucursal) async {
    developer.log('Cambiando sucursal activa a: $idSucursal');
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('No autorizado');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/cambiar-sucursal'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_sucursal': idSucursal,
        }),
      );

      developer.log('Código de respuesta: ${response.statusCode}');
      developer.log('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Actualizar los datos del usuario en el storage
        final currentUserData = await getCurrentUser();
        if (currentUserData != null) {
          currentUserData['id_sucursal'] = int.tryParse(idSucursal);
          currentUserData['nombre_sucursal'] = data['sucursal_nombre'];
          
          await storage.write(key: 'user_data', value: json.encode(currentUserData));
          await storage.write(key: 'id_sucursal', value: idSucursal);
          await storage.write(key: 'nombre_sucursal', value: data['sucursal_nombre']);
        }
        
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cambiar la sucursal');
      }
    } catch (e) {
      developer.log('Error al cambiar sucursal: $e');
      rethrow;
    }
  }
} 