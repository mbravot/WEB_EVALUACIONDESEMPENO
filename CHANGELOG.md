# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere al [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-XX

### 🎉 Lanzamiento Inicial

#### ✅ Agregado
- **Sistema de Autenticación Completo**
  - Login con usuario y contraseña
  - Gestión de tokens JWT
  - Logout seguro
  - Verificación de estado de autenticación
  - Persistencia de sesión

- **Gestión de Temas**
  - Tema claro y oscuro
  - Cambio dinámico de tema
  - Paleta de colores personalizable
  - Configuración de temas en `AppTheme`

- **Gestión de Sucursales**
  - Cambio de sucursal activa
  - Listado de sucursales disponibles
  - Persistencia de sucursal seleccionada
  - Pantalla dedicada para cambio de sucursal

- **Gestión de Contraseñas**
  - Cambio de contraseña
  - Validación de contraseña actual
  - Confirmación de nueva contraseña
  - Validaciones de seguridad

- **Interfaz de Usuario**
  - Dashboard responsive con estadísticas
  - Menú lateral (drawer) con opciones
  - AppBar con información del usuario
  - Navegación fluida entre pantallas
  - Widgets reutilizables (`MainScaffold`, `UserInfo`, `SucursalSelector`)

- **Arquitectura Modular**
  - Estructura de carpetas organizada
  - Providers para gestión de estado (`AuthProvider`, `ThemeProvider`)
  - Servicios para comunicación con API (`AuthService`)
  - Separación clara de responsabilidades

- **Comunicación con API**
  - Integración con endpoints de autenticación
  - Manejo de errores robusto
  - Headers de autenticación automáticos
  - Logging para debugging

#### 🔧 Mejorado
- **Rutas de API corregidas**
  - Cambio de `/api/auth/sucursales` a `/api/sucursales/`
  - Uso correcto de endpoints según documentación del backend

- **Visualización del Usuario**
  - Corrección para mostrar solo el nombre (sin apellidos)
  - Uso del campo `nombre` del backend
  - Fallback seguro a `usuario` si `nombre` no está disponible

- **Manejo de Errores**
  - Mejora en la gestión de errores de API
  - Mensajes de error más descriptivos
  - Logging mejorado para debugging

#### 🐛 Corregido
- **Errores de Compilación**
  - Eliminación de referencias a providers inexistentes
  - Corrección de imports faltantes
  - Limpieza de código no utilizado

- **Problemas de UI**
  - Corrección de colores de tema (`AppTheme.secondaryColor` → `AppTheme.accentColor`)
  - Mejora en la visualización del drawer
  - Corrección de navegación entre pantallas

#### 📚 Documentación
- **README.md completo**
  - Descripción detallada de funcionalidades
  - Guía de instalación y configuración
  - Documentación de API endpoints
  - Información de arquitectura

- **DEVELOPER_GUIDE.md**
  - Guía técnica para desarrolladores
  - Patrones de diseño utilizados
  - Buenas prácticas de desarrollo
  - Ejemplos de código

- **CHANGELOG.md**
  - Registro de cambios por versión
  - Formato estándar de changelog

#### 🗂️ Estructura del Proyecto
```
lib/
├── main.dart                 # Punto de entrada
├── src/
│   ├── app.dart             # Configuración principal
│   ├── providers/           # Gestión de estado
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/             # Pantallas
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

#### 🔌 Endpoints de API Soportados
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/refresh` - Renovar token
- `POST /api/auth/cambiar-clave` - Cambiar contraseña
- `POST /api/auth/cambiar-sucursal` - Cambiar sucursal
- `GET /api/auth/me` - Obtener datos del usuario
- `PUT /api/auth/me` - Actualizar datos del usuario
- `GET /api/sucursales/` - Obtener sucursales del usuario

#### 🎨 Paleta de Colores
- **Primary**: `#2E7D32` (Verde oscuro)
- **Primary Light**: `#4CAF50` (Verde medio)
- **Primary Dark**: `#1B5E20` (Verde muy oscuro)
- **Accent**: `#66BB6A` (Verde claro)
- **Success**: `#4CAF50` (Verde para éxito)
- **Error**: `#F44336` (Rojo para errores)
- **Warning**: `#FF9800` (Naranja para advertencias)
- **Info**: `#2196F3` (Azul para información)

#### 📦 Dependencias Principales
- `flutter`: SDK de Flutter
- `provider: ^6.0.5` - Gestión de estado
- `http: ^1.1.0` - Comunicación HTTP
- `flutter_secure_storage: ^9.0.0` - Almacenamiento seguro
- `flutter_dotenv: ^5.1.0` - Variables de entorno

---

## [Unreleased]

### 🚧 Próximas Funcionalidades
- [ ] Sistema de permisos granular
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Exportación de datos
- [ ] Reportes avanzados
- [ ] Integración con más APIs
- [ ] Tests automatizados
- [ ] CI/CD pipeline

### 🔧 Mejoras Planificadas
- [ ] Optimización de performance
- [ ] Mejoras en la accesibilidad
- [ ] Soporte para más idiomas
- [ ] Mejoras en la UI/UX
- [ ] Documentación de API más detallada

---

## Convenciones de Versionado

Este proyecto usa [Semantic Versioning](https://semver.org/):

- **MAJOR**: Cambios incompatibles con versiones anteriores
- **MINOR**: Nuevas funcionalidades compatibles
- **PATCH**: Correcciones de bugs compatibles

## Tipos de Cambios

- **✅ Agregado**: Nuevas funcionalidades
- **🔧 Mejorado**: Mejoras en funcionalidades existentes
- **🐛 Corregido**: Correcciones de bugs
- **📚 Documentación**: Cambios en documentación
- **🗂️ Estructura**: Cambios en estructura del proyecto
- **🔌 API**: Cambios en endpoints o comunicación con API
- **🎨 UI/UX**: Cambios en interfaz de usuario
- **📦 Dependencias**: Cambios en dependencias
- **🧪 Testing**: Cambios en tests
- **🚀 Deployment**: Cambios en configuración de deployment 