# App Base Web - Flutter

Una aplicación base de Flutter para desarrollo web con sistema de autenticación, gestión de temas y estructura modular.

## 🚀 Características

### ✅ Funcionalidades Implementadas

- **🔐 Sistema de Autenticación**
  - Login con usuario y contraseña
  - Gestión de tokens JWT
  - Logout seguro
  - Verificación de estado de autenticación

- **🎨 Gestión de Temas**
  - Tema claro y oscuro
  - Cambio dinámico de tema
  - Paleta de colores personalizable

- **🏢 Gestión de Sucursales**
  - Cambio de sucursal activa
  - Listado de sucursales disponibles
  - Persistencia de sucursal seleccionada

- **🔑 Gestión de Contraseñas**
  - Cambio de contraseña
  - Validación de contraseña actual
  - Confirmación de nueva contraseña

- **📱 Interfaz de Usuario**
  - Dashboard responsive
  - Menú lateral (drawer)
  - AppBar con información del usuario
  - Navegación fluida

## 🏗️ Arquitectura

### Estructura de Carpetas

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── src/
│   ├── app.dart             # Configuración principal de la app
│   ├── providers/           # Providers de estado
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/             # Pantallas de la aplicación
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── splash_screen.dart
│   │   ├── cambiar_clave_screen.dart
│   │   └── cambiar_sucursal_screen.dart
│   ├── services/            # Servicios de API
│   │   ├── auth_service.dart
│   │   └── tarja_service.dart
│   ├── theme/              # Configuración de temas
│   │   └── app_theme.dart
│   └── widgets/            # Widgets reutilizables
│       ├── main_scaffold.dart
│       ├── user_info.dart
│       └── sucursal_selector.dart
```

### Providers

- **AuthProvider**: Gestión de autenticación y datos del usuario
- **ThemeProvider**: Gestión de temas (claro/oscuro)

### Servicios

- **AuthService**: Comunicación con API de autenticación
- **TarjaService**: Servicios específicos (base para futuras funcionalidades)

## 🔌 API Endpoints

### Autenticación (`/api/auth/`)
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/refresh` - Renovar token
- `POST /api/auth/cambiar-clave` - Cambiar contraseña
- `POST /api/auth/cambiar-sucursal` - Cambiar sucursal
- `GET /api/auth/me` - Obtener datos del usuario
- `PUT /api/auth/me` - Actualizar datos del usuario

### Sucursales
- `GET /api/sucursales/` - Obtener sucursales del usuario

## 🎨 Temas y Colores

### Paleta de Colores
- **Primary**: `#2E7D32` (Verde oscuro)
- **Primary Light**: `#4CAF50` (Verde medio)
- **Primary Dark**: `#1B5E20` (Verde muy oscuro)
- **Accent**: `#66BB6A` (Verde claro)
- **Success**: `#4CAF50` (Verde para éxito)
- **Error**: `#F44336` (Rojo para errores)
- **Warning**: `#FF9800` (Naranja para advertencias)
- **Info**: `#2196F3` (Azul para información)

## 📱 Pantallas

### Login Screen
- Formulario de autenticación
- Validación de campos
- Manejo de errores
- Redirección automática al dashboard

### Home Screen (Dashboard)
- Dashboard principal con estadísticas
- Menú lateral con opciones
- Acciones rápidas
- Información del usuario

### Cambiar Sucursal Screen
- Listado de sucursales disponibles
- Selección de sucursal activa
- Confirmación de cambios
- Actualización automática de datos

### Cambiar Clave Screen
- Formulario de cambio de contraseña
- Validación de contraseña actual
- Confirmación de nueva contraseña
- Validaciones de seguridad

## 🔧 Configuración

### Variables de Entorno
Crear archivo `.env` en la raíz del proyecto:
```env
API_BASE_URL=http://192.168.1.37:5000/api
```

### Dependencias Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  flutter_dotenv: ^5.1.0
```

## 🚀 Instalación y Ejecución

### Prerrequisitos
- Flutter SDK (versión 3.0 o superior)
- Dart SDK
- Navegador web compatible

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd app_web_base
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**
   ```bash
   # Crear archivo .env con la URL de tu API
   echo "API_BASE_URL=http://tu-api-url.com/api" > .env
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run -d chrome
   ```

## 🧪 Testing

### Ejecutar Tests
```bash
flutter test
```

### Ejecutar Tests con Coverage
```bash
flutter test --coverage
```

## 📦 Build para Producción

### Web
```bash
flutter build web
```

### Optimización para Producción
```bash
flutter build web --release --web-renderer html
```

## 🌐 Despliegue a Firebase

**El despliegue debe realizarse con la cuenta:** **mbravo@lahornilla.cl**

Pasos resumidos: build web → `firebase login` (con esa cuenta) → `firebase use --add` → `firebase deploy --only hosting`.  
Instrucciones completas en **[DEPLOY.md](DEPLOY.md)**.

## 🔄 Flujo de Autenticación

1. **Splash Screen** → Verifica token existente
2. **Login Screen** → Autenticación del usuario
3. **Home Screen** → Dashboard principal
4. **Menú Lateral** → Acceso a funcionalidades

## 🛠️ Desarrollo

### Agregar Nuevas Pantallas
1. Crear archivo en `lib/src/screens/`
2. Implementar la pantalla
3. Agregar navegación en el menú lateral
4. Actualizar documentación

### Agregar Nuevos Providers
1. Crear archivo en `lib/src/providers/`
2. Extender `ChangeNotifier`
3. Registrar en `main.dart`
4. Usar en las pantallas necesarias

### Agregar Nuevos Servicios
1. Crear archivo en `lib/src/services/`
2. Implementar métodos de API
3. Manejar errores y respuestas
4. Integrar con providers

## 🐛 Troubleshooting

### Problemas Comunes

**Error de conexión a API**
- Verificar URL en `.env`
- Verificar que el servidor esté corriendo
- Revisar logs de la consola

**Error de autenticación**
- Verificar credenciales
- Limpiar storage local
- Revisar token de autorización

**Problemas de tema**
- Verificar configuración en `app_theme.dart`
- Reiniciar la aplicación
- Limpiar cache del navegador

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📞 Soporte

Para soporte técnico o preguntas sobre el proyecto:
- Crear un issue en el repositorio
- Contactar al equipo de desarrollo
- Revisar la documentación de Flutter

---

**Versión**: 1.0.0  
**Última actualización**: Diciembre 2024  
**Desarrollado con**: Flutter 3.0+
