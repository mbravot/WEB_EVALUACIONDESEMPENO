# Guía de Desarrollador - App Base Web

## 📋 Índice

1. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
2. [Patrones de Diseño](#patrones-de-diseño)
3. [Gestión de Estado](#gestión-de-estado)
4. [Comunicación con API](#comunicación-con-api)
5. [Temas y UI](#temas-y-ui)
6. [Testing](#testing)
7. [Deployment](#deployment)
8. [Buenas Prácticas](#buenas-prácticas)

## 🏗️ Arquitectura del Proyecto

### Estructura Modular

La aplicación sigue una arquitectura modular basada en capas:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (Screens, Widgets, Navigation)    │
├─────────────────────────────────────┤
│           Business Logic            │
│      (Providers, Services)         │
├─────────────────────────────────────┤
│           Data Layer               │
│    (API, Local Storage)           │
└─────────────────────────────────────┘
```

### Responsabilidades por Capa

#### Presentation Layer
- **Screens**: Pantallas principales de la aplicación
- **Widgets**: Componentes reutilizables
- **Navigation**: Gestión de rutas y navegación

#### Business Logic Layer
- **Providers**: Gestión de estado global
- **Services**: Lógica de negocio y comunicación con API

#### Data Layer
- **API Services**: Comunicación con backend
- **Local Storage**: Persistencia local de datos

## 🎯 Patrones de Diseño

### Provider Pattern
```dart
class AuthProvider extends ChangeNotifier {
  // Estado privado
  bool _isAuthenticated = false;
  
  // Getters públicos
  bool get isAuthenticated => _isAuthenticated;
  
  // Métodos para modificar estado
  Future<bool> login(String email, String password) async {
    // Lógica de login
    notifyListeners(); // Notificar cambios
  }
}
```

### Service Pattern
```dart
class AuthService {
  final String baseUrl = 'http://192.168.1.37:5000/api';
  
  Future<Map<String, dynamic>> login(String usuario, String password) async {
    // Lógica de comunicación con API
  }
}
```

### Repository Pattern (Recomendado para futuras implementaciones)
```dart
abstract class UserRepository {
  Future<User> getUser();
  Future<void> saveUser(User user);
}

class UserRepositoryImpl implements UserRepository {
  final ApiService _apiService;
  final LocalStorage _localStorage;
  
  // Implementación
}
```

## 🔄 Gestión de Estado

### Providers Implementados

#### AuthProvider
```dart
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;
  
  // Métodos principales
  Future<bool> login(String email, String password);
  Future<void> logout();
  Future<void> checkAuthStatus();
  Future<List<Map<String, dynamic>>> getSucursalesDisponibles();
  Future<bool> cambiarSucursal(String idSucursal);
}
```

#### ThemeProvider
```dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
```

### Uso de Providers

```dart
// En un widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Text('Usuario: ${auth.userData?['nombre']}');
      },
    );
  }
}
```

## 🌐 Comunicación con API

### Estructura de Servicios

#### AuthService
```dart
class AuthService {
  final String baseUrl = 'http://192.168.1.37:5000/api';
  final storage = const FlutterSecureStorage();
  
  // Métodos principales
  Future<Map<String, dynamic>> login(String usuario, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<Map<String, dynamic>?> getCurrentUser();
  Future<void> cambiarClave(String claveActual, String nuevaClave);
  Future<List<Map<String, dynamic>>> getSucursalesDisponibles();
  Future<Map<String, dynamic>> cambiarSucursal(String idSucursal);
}
```

### Manejo de Errores

```dart
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

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data;
  } else {
    final errorData = json.decode(response.body);
    throw Exception(errorData['error'] ?? 'Error de autenticación');
  }
} catch (e) {
  developer.log('Error durante el login: $e');
  rethrow;
}
```

### Headers de Autenticación

```dart
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
```

## 🎨 Temas y UI

### Configuración de Temas

#### AppTheme
```dart
class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color primaryLightColor = Color(0xFF4CAF50);
  static const Color primaryDarkColor = Color(0xFF1B5E20);
  static const Color accentColor = Color(0xFF66BB6A);
  
  // Colores de estado
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Temas
  static ThemeData lightTheme = ThemeData(/* configuración */);
  static ThemeData darkTheme = ThemeData(/* configuración */);
}
```

### Uso de Temas

```dart
// En un widget
Container(
  decoration: BoxDecoration(
    color: AppTheme.primaryColor,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Texto',
    style: TextStyle(color: Colors.white),
  ),
)
```

### Widgets Reutilizables

#### MainScaffold
```dart
class MainScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? drawer;
  final VoidCallback? onRefresh;
  
  // Implementación con AppBar, Drawer, etc.
}
```

#### UserInfo
```dart
class UserInfo extends StatelessWidget {
  // Widget que muestra información del usuario en AppBar
}
```

## 🧪 Testing

### Estructura de Tests

```
test/
├── unit/
│   ├── providers/
│   │   ├── auth_provider_test.dart
│   │   └── theme_provider_test.dart
│   └── services/
│       └── auth_service_test.dart
├── widget/
│   └── screens/
│       ├── login_screen_test.dart
│       └── home_screen_test.dart
└── integration/
    └── app_test.dart
```

### Ejemplo de Test Unitario

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/src/providers/auth_provider.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('should start with not authenticated', () {
      expect(authProvider.isAuthenticated, false);
    });

    test('should start with no user data', () {
      expect(authProvider.userData, null);
    });
  });
}
```

### Ejemplo de Test de Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows form fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

## 🚀 Deployment

### Build para Producción

```bash
# Build optimizado para web
flutter build web --release --web-renderer html

# Build con configuración específica
flutter build web \
  --release \
  --web-renderer html \
  --dart-define=API_BASE_URL=https://api.produccion.com
```

### Configuración de Servidor Web

#### Nginx
```nginx
server {
    listen 80;
    server_name tu-dominio.com;
    root /var/www/app_web_base/build/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Configuración para API
    location /api/ {
        proxy_pass http://backend-server:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Apache
```apache
<VirtualHost *:80>
    ServerName tu-dominio.com
    DocumentRoot /var/www/app_web_base/build/web
    
    <Directory /var/www/app_web_base/build/web>
        AllowOverride All
        Require all granted
    </Directory>
    
    # Rewrite rules para SPA
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ /index.html [QSA,L]
</VirtualHost>
```

## ✅ Buenas Prácticas

### Código

1. **Nomenclatura**
   ```dart
   // ✅ Correcto
   class AuthProvider extends ChangeNotifier {}
   String userName = 'John';
   
   // ❌ Incorrecto
   class authProvider extends ChangeNotifier {}
   String user_name = 'John';
   ```

2. **Organización de Imports**
   ```dart
   // Imports de Flutter
   import 'package:flutter/material.dart';
   
   // Imports de terceros
   import 'package:provider/provider.dart';
   import 'package:http/http.dart' as http;
   
   // Imports locales
   import '../providers/auth_provider.dart';
   import '../services/auth_service.dart';
   ```

3. **Manejo de Errores**
   ```dart
   try {
     final result = await apiCall();
     return result;
   } catch (e) {
     developer.log('Error: $e');
     rethrow; // Re-lanzar para manejo superior
   }
   ```

### Performance

1. **Uso de const**
   ```dart
   // ✅ Correcto
   const SizedBox(height: 16);
   const Text('Hola');
   
   // ❌ Incorrecto
   SizedBox(height: 16);
   Text('Hola');
   ```

2. **Lazy Loading**
   ```dart
   // Para listas grandes
   ListView.builder(
     itemCount: items.length,
     itemBuilder: (context, index) {
       return ListTile(
         title: Text(items[index].title),
       );
     },
   )
   ```

3. **Memoización**
   ```dart
   class ExpensiveWidget extends StatelessWidget {
     final String data;
     
     const ExpensiveWidget({Key? key, required this.data}) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Text(data);
     }
   }
   ```

### Seguridad

1. **Almacenamiento Seguro**
   ```dart
   // ✅ Usar FlutterSecureStorage para datos sensibles
   await storage.write(key: 'token', value: token);
   
   // ❌ No usar SharedPreferences para tokens
   await prefs.setString('token', token);
   ```

2. **Validación de Input**
   ```dart
   String? validateEmail(String? value) {
     if (value == null || value.isEmpty) {
       return 'El email es requerido';
     }
     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
       return 'Email inválido';
     }
     return null;
   }
   ```

### Testing

1. **Cobertura de Tests**
   ```bash
   # Ejecutar tests con coverage
   flutter test --coverage
   
   # Ver reporte de coverage
   genhtml coverage/lcov.info -o coverage/html
   ```

2. **Mocks para Tests**
   ```dart
   class MockAuthService extends Mock implements AuthService {}
   
   void main() {
     late MockAuthService mockAuthService;
     
     setUp(() {
       mockAuthService = MockAuthService();
     });
     
     test('login should return success', () async {
       when(mockAuthService.login(any, any))
           .thenAnswer((_) async => {'success': true});
       
       // Test implementation
     });
   }
   ```

---

**Nota**: Esta guía se actualiza regularmente. Para la versión más reciente, consulta el repositorio del proyecto. 