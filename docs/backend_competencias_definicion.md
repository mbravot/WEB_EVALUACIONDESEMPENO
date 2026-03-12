# Pedido al backend: incluir descripción de competencias en evaluaciones

Para que en la app se muestre la **descripción (definición)** de cada competencia al ver una evaluación realizada (Mis evaluaciones, Consultar evaluaciones y PDF), el backend debe devolver esos datos en las respuestas de detalle de evaluación.

---

## Dónde debe incluirse

En **todas las respuestas que devuelven el detalle de una evaluación** (objeto con `competencias`, `funciones`, etc.), el array `competencias` debe venir **enriquecido** con nombre y definición, no solo con IDs y nota.

Endpoints afectados (según cómo esté implementado el API):

- **GET /api/evaluador/mis-evaluaciones** — cada ítem de la lista es una evaluación con detalle; si ahí va el array `competencias`, cada elemento debe incluir `nombre_competencia` y `definicion`.
- **GET /api/evaluaciones** (consultar todas) — mismo criterio: cada evaluación con su array `competencias` enriquecido.
- Cualquier otro **GET** que devuelva una evaluación con su objeto completo (por ejemplo GET por `id_evaluacion` si existe).

---

## Formato esperado del array `competencias`

Cada elemento del array `competencias` debe tener al menos:

| Campo                 | Tipo   | Descripción |
|-----------------------|--------|-------------|
| `id_competencianivel` | number | ID en `rrhh_dim_competencianivel` (ya lo guardan) |
| `nota`                | number | Nota 1–5 (ya lo guardan) |
| `nombre_competencia`  | string | Nombre de la competencia (ej. desde `rrhh_dim_competencia.nombre`) |
| `definicion`          | string | Descripción del nivel (desde `rrhh_dim_competencianivel.definicion`) |

Opcional: pueden enviar también `nombre` como alias de `nombre_competencia`; la app acepta ambos.

**Ejemplo de ítem en `competencias`:**

```json
{
  "id_competencianivel": 5,
  "nota": 4,
  "nombre_competencia": "Trabajo en equipo",
  "definicion": "Colabora con el equipo, comparte información y apoya las metas comunes."
}
```

---

## Cómo obtener los datos en el backend

- Al armar la respuesta de la evaluación, por cada `id_competencianivel` guardado:
  - Hacer **join** (o consulta equivalente) con la tabla de competencia-nivel (ej. `rrhh_dim_competencianivel`) y con la tabla de competencia (ej. `rrhh_dim_competencia`).
  - Tomar de ahí:
    - **nombre de la competencia** → enviar como `nombre_competencia` (y opcionalmente `nombre`).
    - **definición del nivel** → enviar como `definicion`.

El mismo formato que ya devuelve **GET /api/competencias/cargo/{id_cargo}/disponibles** (nombre + definición por competencia-nivel) es el que se necesita en cada ítem de `competencias` dentro del detalle de la evaluación.

---

## Resumen en una frase

**En las respuestas de “mis evaluaciones” y “consultar evaluaciones” (y cualquier GET de detalle de evaluación), cada elemento del array `competencias` debe incluir, además de `id_competencianivel` y `nota`, los campos `nombre_competencia` y `definicion` (nombre y descripción del nivel de la competencia).**
