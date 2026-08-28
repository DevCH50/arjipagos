# TLS en móviles antiguos, badge de iOS y notificaciones marcables

**Hecho y verificado en dispositivo el 2026-08-27.**

Tres arreglos de la app. Las otras tres peticiones de la misma tanda son del
panel web y están en
`/home/carlos/Projects/Laravel/ArjiApp/ENCARGO_NOTIFICACIONES.md`.

| # | Petición | Dónde se arregló |
| --- | --- | --- |
| 1 | «No se pudo establecer una conexión segura» en algunos móviles | Servidor **+ esta app** |
| 2 | El círculo rojo no se quita | Servidor + **esta app** |
| 3 | Que toda notificación se pueda marcar como leída | **Esta app** |

---

## Punto 1 — La conexión segura que fallaba en móviles antiguos

### Qué pasaba

No era un fallo del código. El servidor cerraba su cadena de certificados en una
raíz que esos teléfonos no tenían, el handshake fallaba con `HandshakeException`
y `mensajeErrorRed()` lo traducía —correctamente— a ese diálogo. El mapeo de
errores funcionaba bien; lo que fallaba estaba por debajo.

El cliente HTTP de Dart valida contra el almacén de confianza **del sistema
operativo**, y ese almacén se congela con la versión de Android: un teléfono que
no recibe actualizaciones no conoce las raíces emitidas después de salir de
fábrica. Los navegadores de escritorio no fallaban porque completan la cadena
por AIA fetching; Dart no lo hace. De ahí el «en la web se ve bien, en el móvil
no».

En su momento la cadena terminaba en **Sectigo Public Server Authentication Root
R46** (de 2021), que solo está en Android reciente. Comprobado en el Oppo
(Android 16, API 36): la tenía, por eso ahí sí entraba.

### Qué se hizo en el servidor

Se cambió el certificado. Hoy sirve **Let's Encrypt**:

```
leaf → LE YE2 → ISRG Root YE → ISRG Root X2 → ISRG Root X1
```

`ISRG Root X1` está en Android desde la **7.1.1 (2016)**, así que los teléfonos
que no entraban ya entran. Verificado con un handshake real confiando *solo* en
esa raíz:

```bash
openssl s_client -connect arjipagos.moriah.mx:443 \
  -servername arjipagos.moriah.mx -CAfile isrg_x1.pem -no-CApath
# Verify return code: 0 (ok)
```

### Qué se hizo en la app

**`lib/src/data/api/ConfianzaTls.dart`** (nuevo) empaqueta **ISRG Root X1** y la
añade a las autoridades de confianza, instalándose como `HttpOverrides.global`
en `main.dart` **antes** de `Firebase.initializeApp()`, que ya hace red.

Sigue haciendo falta aunque el servidor esté arreglado: el `minSdk` del proyecto
es **24 (Android 7.0)** y la raíz llegó al almacén en la **7.1.1**. Sin esto, un
Android 7.0 exacto seguiría fuera.

**No es certificate pinning.** El `SecurityContext` usa `withTrustedRoots: true`,
así que conserva todas las raíces del sistema y solo **añade** una. Si mañana
cambian de autoridad, la app sigue funcionando sin publicar versión.

**Por qué un `HttpOverrides` y no tocar los servicios:** ninguno crea su propio
`http.Client` —todos usan las funciones de nivel superior de `package:http`, que
por debajo construyen un `HttpClient` de `dart:io`—, así que sustituir la fábrica
global cubre los quince y pico servicios sin tocar ninguno, y de paso las
descargas de `cached_network_image`. Los tests con `runWithClient` no se ven
afectados: son mecanismos independientes.

Lo que **no** se hizo: un `badCertificateCallback` que acepte todo. Eso desactiva
TLS de hecho.

---

## Punto 2 — El círculo rojo que no se quitaba

Eran dos cosas distintas, y las dos estaban rotas.

### a) El punto rojo dentro de la app

`notificacion_badge_button.dart` lo pintaba **solo** cuando `hayNueva` era cierto
—no cuando había pendientes—, y `hayNueva` únicamente se apagaba al **tocar la
campana**.

Al abrir la app desde un push, `_onNotificacionAbiertaDesdeBackground` lo
encendía y navegaba solo a Notificaciones; allí se limpiaba `debeNavegar` pero
nadie tocaba `hayNueva`. Como el `onPressed` de la campana nunca se ejecutaba, el
punto se quedaba encendido para siempre. Y si el aviso llegaba después de la
carga inicial —lo normal con `getInitialMessage()` en iOS, que resuelve tarde—,
ni siquiera lo apagaba la recarga.

**Arreglo:** `NotificacionesPage` emite `ResetNuevaNotificacionEvent` al
montarse, no solo al tocar la campana. Y el punto ahora sale de `noLeidas > 0`,
que es el estado real; `hayNueva` gobierna únicamente la animación de pulso.
Antes el indicador mentía por los dos lados: no aparecía con avisos pendientes
de días atrás, y se quedaba puesto cuando nadie lo apagaba.

### b) El globo del icono en iOS

El backend manda `aps.badge` en el payload de APNs, así que iOS enciende el
contador; **bajarlo es cosa de la app y no lo hacía nadie**. En Android no se
nota porque el sistema no pinta ese contador por su cuenta — de ahí que solo se
viera en iPhone.

**Arreglo:** `lib/src/data/dataSource/local/BadgeIconoApp.dart` (nuevo) habla
por `MethodChannel` con el canal registrado en `ios/Runner/AppDelegate.swift`
(`setBadgeCount` en iOS 16+, con `applicationIconBadgeNumber` de respaldo).

Sin dependencias nuevas: los paquetes al uso llevan años sin mantenimiento y
esto son unas pocas líneas de Swift.

### El globo lleva el conteo real (2026-08-28)

La primera versión solo sabía **apagarlo**, y lo hacía desde la pantalla:
`BadgeIconoApp.limpiar()` en el `initState` de `NotificacionesPage` y en el botón
de marcar todas. Dos fallos:

1. **Mentía.** Asomarse a la lista sin leer nada dejaba el icono a cero mientras
   el servidor seguía contando avisos pendientes.
2. **Era fácil de olvidar.** `noLeidas` cambia desde siete sitios del BLoC y solo
   dos pasaban por la pantalla.

Ahora lo lleva **`NotificacionBloc.onChange`**, que espeja `noLeidas` en el globo
pase lo que pase, y `limpiar()` desapareció por quedarse sin uso. Se compara el
conteo antes de llamar: los cambios de estado que no lo tocan —`isLoading`,
`hayNueva`, la paginación— no molestan al canal nativo.

La sincronización se **inyecta** en el constructor (`sincronizarBadge`), como ya
se hacía con los streams de FCM, porque el original solo funciona en iOS.

El backend ya manda el conteo real en APNs (`'badge' => $sinLeer`, §B del encargo
de ArjiApp), así que las dos mitades coinciden.

> Sigue **sin verificar en un iPhone**: Android no pinta ese contador, así que el
> `MethodChannel` solo se comprueba en dispositivo iOS. Pendiente para la Mac.

---

## Punto 3 — Notificaciones que no se podían marcar como leídas

### Qué pasaba

Las que llegaban con la app **abierta** se construían con `id: 0`, tirando el
identificador que el backend manda en el payload. Al abrirlas, el detalle pedía
`POST /api/v1/notificaciones/0/leer`, el servidor lo rechazaba y el usuario
recibía un **diálogo de error** mientras el contador se quedaba clavado. Le
pasaba a cualquier aviso recibido en primer plano, los de prueba incluidos.

Además, `_onMarcarLeida` emparejaba por `n.id == event.id`: con id 0 habría
marcado de golpe todas las que estuvieran en ese caso.

### El dato ya venía en el push

`PushNotificationService::enviarAlUsuario()` crea **siempre** una fila
`usermobile_message` y manda `'usermessage_id' => (string) $mensaje->id` dentro
de `data` — también en las de prueba, porque `marcarComoPrueba()` solo antepone
`[PRUEBA]` al texto. La app lo tenía delante y lo estaba tirando.

### Arreglo

- `NotificacionBloc._onFcmForegroundMessage` lee
  `int.tryParse(message.data['usermessage_id'])`.
- Guarda en `_onMarcarLeida`: con un id inválido no se llama al servidor **ni se
  marca en local** —sin identificador no hay forma de distinguir una notificación
  de otra, y emparejar por `id == 0` las marcaría todas—. Se sale en silencio y
  la lista se reconcilia en la siguiente carga. Nunca un diálogo de error.

### El único push que no deja historial, y está bien así

`refrescarTirillaEnSilencio()` manda multicast directo sin crear fila. Es un
`data-only` con `apns-push-type: background`: no es un mensaje para el usuario,
es una orden para el cliente. No debe aparecer en la bandeja. **No tocar.**

---

## Limpieza

Se quitó `badges: ^3.1.2` del `pubspec.yaml`: no se importaba en ningún archivo
de `lib/`.

---

## Archivos

| Archivo | Qué |
| --- | --- |
| `lib/src/data/api/ConfianzaTls.dart` | **Nuevo.** Añade ISRG Root X1 a la confianza |
| `lib/src/data/dataSource/local/BadgeIconoApp.dart` | **Nuevo.** Pone el globo del icono de iOS en el conteo real |
| `assets/certs/isrg_root_x1.pem` | **Nuevo.** La raíz empaquetada |
| `ios/Runner/AppDelegate.swift` | Canal nativo del badge |
| `lib/main.dart` | Instala el `HttpOverrides` antes de Firebase |
| `NotificacionBloc.dart` | Lee `usermessage_id`; guarda del id inválido; `onChange` espeja el conteo en el badge |
| `NotificacionesPage.dart` | Apaga `hayNueva` al abrirse. Ya **no** toca el badge |
| `notificacion_badge_button.dart` | El punto sale de `noLeidas`, no de `hayNueva` |
| `dart_test.yaml` | **Nuevo.** Declara la etiqueta `red` |

**Tests nuevos:** `test/unit/confianza_tls_test.dart` (5),
`test/unit/blocs/notificacion_marcar_leida_test.dart` (6),
`test/unit/badge_icono_app_test.dart` (4) y
`test/unit/blocs/notificacion_badge_sincroniza_test.dart` (6). Suite completa:
**934 en verde**, `flutter analyze` sin incidencias.

El test de TLS incluye un handshake **real** contra `arjipagos.moriah.mx` con
`withTrustedRoots: false`: si la cadena del servidor no se pudiera validar solo
con lo que la app empaqueta, falla. Es lo único que demuestra que el arreglo
sirve, y por eso no se sustituye por un doble de pruebas. Lleva la etiqueta
`red`; para correr sin conexión: `flutter test --exclude-tags red`.

---

## Verificación en dispositivo (Oppo, Android 16)

Con push reales de la cuenta de pruebas `CATutorP641`:

```
[TLS] Confianza TLS reforzada con ISRG Root X1
...
usermessage_id: 1276                    ← el backend lo manda; antes se tiraba
Notificaciones no leídas: 1             ← llega y cuenta
Notificación 1276 marcada como leída    ← el id REAL, no un 0
Notificaciones no leídas: 0             ← baja contra el servidor
```

Comprobado además por pantalla: el punto rojo **se enciende** al llegar el push y
**se apaga** al abrir Notificaciones (dos ciclos completos), el detalle abre sin
diálogo de error, y todas las peticiones HTTPS responden 200. Cero `[ERROR]` en
todo el recorrido.

**Lo que NO se pudo verificar aquí:** el globo del icono de iOS. Android no lo
pinta, así que el `MethodChannel` solo se comprueba en un iPhone — pendiente
para la Mac.
