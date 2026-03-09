# Despliegue a Firebase Hosting

**Importante:** El despliegue debe realizarse **siempre con la cuenta**  
**mbravo@lahornilla.cl**

---

## Requisitos

- Flutter SDK
- Firebase CLI (`npm install -g firebase-tools`)
- Cuenta de Firebase/Google: **mbravo@lahornilla.cl**

---

## Pasos

### 1. Build de la app web

```bash
flutter pub get
flutter build web
```

Si falla el build por permisos (p. ej. en OneDrive), prueba desde otra carpeta o con `--web-renderer html`:

```bash
flutter build web --web-renderer html
```

### 2. Iniciar sesión en Firebase con la cuenta correcta

```bash
firebase login
```

- En el navegador, inicia sesión con **mbravo@lahornilla.cl**.
- Para comprobar la cuenta actual: `firebase login:list`

Si ya tienes otra cuenta y quieres cambiar:

```bash
firebase logout
firebase login
```

y usa **mbravo@lahornilla.cl**.

### 3. Vincular o crear el proyecto Firebase

Si es la primera vez en esta carpeta:

```bash
firebase use --add
```

- Elige “Create a new project” o un proyecto existente de la cuenta **mbravo@lahornilla.cl**.
- Asigna un alias si lo pide (por ejemplo `default`).

### 4. Desplegar

```bash
firebase deploy --only hosting
```

O solo:

```bash
firebase deploy
```

La URL de hosting será del tipo:  
`https://<project-id>.web.app` o `https://<project-id>.firebaseapp.com`

---

## Resumen

| Paso | Comando / Acción |
|------|-------------------|
| Build | `flutter build web` |
| Login | `firebase login` → **mbravo@lahornilla.cl** |
| Proyecto | `firebase use --add` (crear o elegir proyecto) |
| Deploy | `firebase deploy --only hosting` |

**Cuenta obligatoria para despliegue:** **mbravo@lahornilla.cl**
