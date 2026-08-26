# Face ID / Huella — Lo que hace falta del backend

> Documento para pasar **tal cual** al desarrollador del backend.
> El lado de la app está en [`PLAN_FACE_ID.md`](PLAN_FACE_ID.md).

---

## ⚠️ ESTADO: nada de este documento está hecho todavía

**Al 2026-08-25 el backend no ha tocado nada de esto, y la app tampoco lo necesita para
funcionar.**

Lo que ya está construido y probado en la app es el **cerrojo**: al volver a la aplicación se
pide huella o Face ID. Eso es **100 % local al teléfono** y no habla con el servidor en ningún
momento. Se puede publicar tal cual, hoy, sin que el backend se entere.

Este documento describe la **segunda mitad**, que es opcional y aún no está construida: el
**login biométrico**, es decir, entrar sin escribir usuario y contraseña después de haber
cerrado sesión. Esa mitad sí necesita las tres rutas nuevas de abajo, y **es lo único que está
esperando al backend**.

| | ¿Hecho? | ¿Necesita backend? |
| --- | --- | --- |
| **Cerrojo** — pedir la huella al volver a la app | ✅ Sí, hecho y probado | **No. Nada.** |
| **Login biométrico** — entrar sin teclear la contraseña | ❌ No | **Sí: todo lo de aquí** |

Si nunca se pide la segunda mitad, **este documento no hay que ejecutarlo**. Nada se rompe: la
app seguirá pidiendo usuario y contraseña tras cerrar sesión, como hasta ahora.

---

## Primero, lo que NO tienes que hacer

**El backend nunca ve datos biométricos.** El rostro y la huella no salen del Secure Enclave del
iPhone ni del TEE de Android: ni siquiera la app los ve. El sistema operativo solo nos responde
"sí" o "no".

Lo que necesitamos del backend es otra cosa: **un token de dispositivo, de larga vida y revocable
desde el servidor**, que la app canjee por un `access_token` normal después de que el usuario
pase el Face ID. Es exactamente el mismo patrón de "mantener la sesión iniciada" de cualquier app
bancaria.

Son **tres endpoints nuevos**, **una tabla** y **dos retoques** en endpoints que ya existen.

---

## 1. Tabla nueva

```
biometria_dispositivos
  id                bigint, PK
  user_id           bigint, FK → usuarios
  device_id         varchar(64)      -- lo genera la app; único junto a user_id
  device_type       enum('ios','android')
  device_name       varchar(120), nullable
  token_hash        char(64)         -- SHA-256 del device_token. NUNCA el token en claro
  last_used_at      datetime, nullable
  expires_at        datetime
  revoked_at        datetime, nullable
  created_at / updated_at

  UNIQUE (user_id, device_id)
  INDEX  (token_hash)
```

**El `device_token` se guarda hasheado (SHA-256), nunca en claro.** Se devuelve una sola vez, en el
alta. Si alguien se lleva un volcado de la base de datos, no puede entrar con lo que hay ahí.

`device_id` lo genera la app (32 bytes aleatorios en hexadecimal) y lo guarda en el Keychain de
iOS / Keystore de Android. Es estable mientras no se desinstale la app. **No** reutilizamos el
token de FCM para esto, porque FCM lo rota por su cuenta.

---

## 2. `POST /api/v1/biometria/registrar`

Alta del dispositivo. Se llama justo después de un login normal con contraseña, cuando el usuario
acepta activar el Face ID.

**Autenticación:** `Authorization: Bearer {access_token}` — el que acaba de obtener del login.

**Petición:**
```json
{
  "device_id":   "a3f9...c1",
  "device_type": "ios",
  "device_name": "iPhone de Carlos"
}
```

**Respuesta 200:**
```json
{
  "status": 1,
  "msg": "Dispositivo registrado",
  "device_token": "<cadena opaca, mínimo 32 bytes aleatorios en base64url>",
  "expires_at": "2026-11-23T10:00:00Z"
}
```

Reglas:
- El `device_token` se genera con un generador **criptográficamente seguro**. Nada de `md5(user_id)`
  ni de secuencias predecibles.
- Si ya existe una fila para ese `(user_id, device_id)`, se **reemplaza** el token. No se acumulan.
- Un mismo usuario puede tener varios dispositivos dados de alta. Un mismo dispositivo puede tener
  varios usuarios (familias que comparten tablet).

---

## 3. `POST /api/v1/biometria/login`

El canje. Se llama después de que el usuario pase el Face ID en la pantalla de login.

**Autenticación:** ninguna. El `device_token` es la credencial.

**Petición:**
```json
{
  "device_token": "...",
  "device_id":    "a3f9...c1",
  "device_type":  "ios"
}
```

**Respuesta 200 — muy importante:**

Tiene que devolver **exactamente el mismo JSON que `/api/v1/login`**, con los mismos campos y los
mismos nombres:

```json
{
  "status": 1,
  "msg": "...",
  "access_token": "...",
  "token_type": "Bearer",
  "user": { ... },
  "api_version": "...",
  "app_version": "..."
}
```

Así la app reutiliza el parser que ya tiene y no hay que tocar nada más. Si el JSON cambia de
forma, se rompe el login normal también.

**Respuesta 401** (token inválido, revocado, caducado, o `device_id` que no corresponde):
```json
{ "status": 0, "msg": "Vuelve a iniciar sesión con tu contraseña" }
```
Con eso la app borra el token local, apaga el interruptor y pide la contraseña. No hay que dar más
detalle: no conviene distinguir "revocado" de "caducado" de cara al cliente.

Reglas:
- Validar que el `device_id` de la petición **coincide** con el de la fila del `token_hash`. Si no
  coincide, 401. Sin esta comprobación, un token robado sirve desde cualquier aparato.
- Actualizar `last_used_at` en cada canje con éxito.
- Si el usuario está deshabilitado, bloqueado o dado de baja, este endpoint tiene que fallar
  **igual que `/login`**. No puede ser una puerta trasera que se salte esas comprobaciones.
- **Rate limit**: sugerido 10 intentos por hora y por `device_id`, y 20 por IP. Es el endpoint más
  expuesto de los tres.
- Registrar en auditoría: `user_id`, `device_id`, IP, resultado.
- El `device_token` **solo** se acepta aquí. Nunca como `Bearer` en el resto del API.

---

## 4. `POST /api/v1/biometria/revocar`

Baja. Se llama cuando el usuario apaga el interruptor en la app.

**Autenticación:** `Authorization: Bearer {access_token}`

**Petición:**
```json
{ "device_id": "a3f9...c1" }
```
o bien `{ "todos": true }` para cerrar todos los dispositivos del usuario.

**Respuesta 200:** `{ "status": 1, "msg": "Acceso biométrico desactivado" }`

Marcar `revoked_at`, o borrar la fila. Cualquiera de las dos vale.

---

## 5. Dos retoques en endpoints que ya existen

Estos dos son de seguridad, no de funcionalidad. Sin ellos la función queda con un agujero.

### 5.1 `POST /api/v1/user/change/password/mobile` y `POST /api/v1/user/recovery/password/mobile`

**Al cambiar o recuperar la contraseña, revocar TODOS los `device_token` de ese usuario.**

Motivo: el escenario que esto protege es el de alguien que conocía la contraseña vieja. Si cambio
mi contraseña porque sospecho que alguien la sabía, y ese alguien había activado el Face ID en su
propio teléfono, su acceso **sigue vivo** mientras no se revoque. El cambio de contraseña no le
afecta lo más mínimo.

Efecto en la app: en el siguiente intento recibe 401, borra su token y pide la contraseña otra vez.
Se vuelve a activar en dos toques. Es una molestia pequeña a cambio de cerrar el agujero.

### 5.2 `POST /api/v1/dispositivo/eliminar`

Ese endpoint ya existe para dar de baja el token de FCM. **Que revoque también el `device_token`
biométrico del mismo dispositivo**, para que "quitar este dispositivo" signifique una sola cosa y
no deje media puerta abierta.

---

## 6. Recomendado, pero no bloqueante

### 6.1 Añadir la expiración al login

Hoy `/api/v1/login` devuelve el `access_token` **sin decir cuándo caduca**. La app no puede
distinguir "tu sesión expiró" de "se cayó la red", y por eso hoy la sesión en la app no caduca
nunca: entra directa al menú aunque el token lleve meses muerto.

Sugerencia: añadir un campo al JSON de `/api/v1/login` (y al de `/biometria/login`):

```json
"expires_in": 2592000      // segundos, o bien "expires_at": "2026-09-24T10:00:00Z"
```

Es un campo **nuevo y opcional**: la app actual lo ignora y no se rompe nada. Cuando esté, la app
podrá renovar la sesión sola con el `device_token` en vez de plantar al usuario en el login.

### 6.2 Caducidad del `device_token`

Sugerido: **90 días desde el último uso** (`last_used_at`, no `created_at`). Quien usa la app cada
mes no vuelve a ver el formulario nunca; un teléfono abandonado en un cajón deja de ser una llave
válida a los tres meses.

---

## 7. Resumen en una tabla

| # | Qué | Dónde | Prioridad |
| --- | --- | --- | --- |
| 1 | Tabla `biometria_dispositivos`, con el token **hasheado** | BD | Bloqueante |
| 2 | `POST /api/v1/biometria/registrar` | Nuevo | Bloqueante |
| 3 | `POST /api/v1/biometria/login` — **mismo JSON que `/login`** | Nuevo | Bloqueante |
| 4 | `POST /api/v1/biometria/revocar` | Nuevo | Bloqueante |
| 5 | Validar que `device_id` coincide con el del token | En el #3 | Bloqueante |
| 6 | Rate limit + auditoría en el canje | En el #3 | Bloqueante |
| 7 | Revocar todo al cambiar/recuperar contraseña | Existente | Bloqueante |
| 8 | Revocar también en `/dispositivo/eliminar` | Existente | Alta |
| 9 | `expires_in` en `/login` | Existente | Media |
| 10 | Caducidad de 90 días por inactividad | En el #1 | Media |

Del 1 al 7 hacen falta para poder publicar la función. El 8, 9 y 10 pueden ir después.

---

## 8. Las tres preguntas que hay que devolverle

1. **¿El `access_token` actual caduca?** Si caduca, ¿en cuánto tiempo? De eso depende si hace falta
   el punto 6.1 ya o puede esperar.
2. **¿Prefiere reutilizar la tabla de dispositivos que ya usa para FCM**, en vez de crear
   `biometria_dispositivos`? Da igual cuál, pero conviene decidirlo antes para que `device_id`
   signifique lo mismo en los dos sitios.
3. **¿Cuánto quiere que dure el `device_token`?** Propuesta: 90 días desde el último uso.
