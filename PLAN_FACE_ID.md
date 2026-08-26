# Plan — Ingreso con Face ID / Huella

> Redactado el 2026-08-25.
> Decisiones tomadas con el usuario: cerrojo **y** login biométrico, secreto = *refresh token*
> emitido por el backend, fallback al PIN/patrón del dispositivo, interruptor en el drawer.
>
> La parte del backend está aparte, en [`PLAN_FACE_ID_BACKEND.md`](PLAN_FACE_ID_BACKEND.md).

---

## Estado al 2026-08-25

Se decidió partir la función en dos y **entregar primero la mitad que no depende de nadie**.

### ✅ HECHO — El cerrojo (fases 1 a 3)

Construido, con tests, y probado en el Oppo CPH2639 (Android 16, API 36).
**No necesita absolutamente nada del backend.**

- `local_auth` 3.x, `MainActivity` como `FlutterFragmentActivity`, `USE_BIOMETRIC` en el
  manifest, `NSFaceIDUsageDescription` en el `Info.plist`.
- `NormalTheme` pasa a AppCompat — ver §6.3, era un **crash** real en aparatos antiguos.
- Capa completa: `AutenticadorBiometrico`, `BiometriaStorage`, repositorio, tres casos de uso,
  `BiometriaBloc`, `CerrojoBiometrico`, `CerrojoPantalla`, `InterruptorBiometria`.
- Interruptor en el drawer, bajo "Mi cuenta".
- 24 tests nuevos; los 868 de la suite siguen pasando.

### ❌ PENDIENTE — El login biométrico (fases 4 en adelante)

Entrar **sin teclear la contraseña** después de cerrar sesión. Es lo único que espera al
backend: tres endpoints y una tabla, todo en
[`PLAN_FACE_ID_BACKEND.md`](PLAN_FACE_ID_BACKEND.md).

Mientras no se haga, tras cerrar sesión se entra con usuario y contraseña, como siempre. Nada
queda a medias ni roto: el cerrojo funciona por su cuenta.

### ⏳ PENDIENTE — Verificación en iOS

Todo lo de iOS está escrito pero **no se ha probado**: requiere la Mac. Ver §10.

---

## 1. Lo que hay hoy (punto de partida real)

Verificado en el código, no en la documentación:

| Pieza | Estado actual |
| --- | --- |
| `SplashBloc._checkSession()` | Si existe `user_session` en `SecureStorage`, entra **directo** a `menu_principal` |
| `AuthResponse` | `status`, `msg`, `access_token`, `token_type`, `user`, `api_version`, `app_version` — **sin expiración** |
| `AuthRepositoryImpl.logout()` | `secureStorage.clearUserSession()` + `sharedPref.clear()` |
| `SecureStorage` | Keychain con `first_unlock_this_device` en iOS; cifrado propio en Android |
| `MainActivity` | `FlutterActivity` con la guarda del *launcher relaunch bug* |
| `Info.plist` | **No** tiene `NSFaceIDUsageDescription` |
| `minSdk` | 24 (`flutter.minSdkVersion`, Flutter 3.47.1) |
| `styles.xml` (×4) | Heredan de `@android:style/Theme.*.NoTitleBar` — temas de **plataforma**, no AppCompat |
| Identificador de dispositivo | **No existe**. El registro FCM manda el propio `token` de FCM, no un `device_id` estable |

**Consecuencia de diseño.** Como la sesión no caduca nunca, hoy la app ya entra sin pedir nada.
El Face ID por tanto aporta dos cosas distintas y ambas se van a hacer:

- **Cerrojo** — proteger la sesión viva. No depende del backend, se puede entregar antes.
- **Login biométrico** — volver a entrar tras *cerrar sesión* sin teclear la contraseña. Sí depende
  del backend.

---

## 2. Dependencia

```yaml
local_auth: ^3.0.2          # oficial de flutter.dev
local_auth_android: ^2.0.9  # declarados porque se importan los AuthMessages directamente
local_auth_darwin: ^2.0.3
```

**Se usa la serie 3.x, no la 2.x.** Comprobado antes de adoptarla: los errores llegan como
`LocalAuthException` con un `code` de enum en vez de códigos en texto, `authenticate()` aplana
sus parámetros, y encaja con el toolchain fijado — `local_auth_android` 2.0.9 declara
`minSdk = 24`, el mismo del proyecto, y hereda `compileSdk` de Flutter en vez de clavar una API
concreta como hace `flutter_secure_storage` 11. En iOS pide 13.0 y aquí el objetivo es 15.0.

Es lo único que se añade. **No** hace falta `device_info_plus` ni `uuid`: cuando llegue el login
biométrico, el `device_id` se generará con `Random.secure()` en hexadecimal y se guardará en
`SecureStorage`.

`flutter_secure_storage` **sigue en 10.x** — no se toca. La 11.0.0, que sí ofrece ítems del
Keychain protegidos por biometría a nivel de sistema, está bloqueada por AGP/API 37 (ver
`CLAUDE.md`). Por eso el candado es a nivel de app, no de Keychain: es aceptable y es lo que
hace la mayoría de las apps bancarias, pero conviene tenerlo escrito.

> **Plugin nativo nuevo = hot reload NO basta.** Hay que parar la app y recompilar. En la Mac,
> la limpieza obligatoria completa (`flutter clean && flutter pub get && cd ios && pod install`).

---

## 3. Arquitectura (Clean Architecture + injectable)

```
lib/src/
├── core/
│   ├── constants/app_strings.dart              ← + strings de biometría (ninguno hardcodeado)
│   └── utils/biometria_error_mapper.dart       ← NUEVO: PlatformException → mensaje legible
├── data/
│   ├── dataSource/local/
│   │   ├── AutenticadorBiometrico.dart         ← NUEVO: envoltorio fino de LocalAuthentication
│   │   └── BiometriaStorage.dart               ← NUEVO: preferencia + device_token + device_id
│   ├── dataSource/remote/services/
│   │   └── BiometriaService.dart               ← NUEVO: registrar / login / revocar
│   └── repository/BiometriaRepositoryImpl.dart ← NUEVO
├── domain/
│   ├── models/BiometriaDisponible.dart         ← NUEVO: enum ninguna | huella | rostro | credencial
│   ├── repository/BiometriaRepository.dart     ← NUEVO
│   └── useCases/biometria/
│       ├── BiometriaUseCases.dart
│       ├── ConsultarBiometriaUseCase.dart      ← qué soporta el aparato y si está activada
│       ├── AutenticarBiometriaUseCase.dart     ← el prompt nativo, a secas
│       ├── ActivarBiometriaUseCase.dart        ← prompt + registrar en backend + guardar
│       ├── DesactivarBiometriaUseCase.dart     ← revocar en backend + borrar local
│       └── LoginBiometricoUseCase.dart         ← prompt + canjear device_token → AuthResponse
└── presentation/
    ├── widgets/
    │   ├── CerrojoBiometrico.dart              ← NUEVO: overlay del cerrojo
    │   └── BotonBiometrico.dart                ← NUEVO: botón "Entrar con Face ID"
    └── pages/
        ├── biometria/bloc/                     ← NUEVO: BiometriaBloc (cerrojo + interruptor)
        ├── auth/login/includes/LoginContent.dart      ← + botón biométrico
        ├── auth/login/bloc/                           ← + evento LoginBiometricoSubmitted
        └── menu_principal/widgets/user_drawer.dart    ← + SwitchListTile
```

**Por qué `AutenticadorBiometrico` como envoltorio:** `LocalAuthentication` no se puede sustituir
en un test. Envolviéndolo detrás de una interfaz propia, los casos de uso quedan testeables con un
doble, siguiendo el patrón que ya usa el proyecto para `SecureStorage`.

Registro en `AppModule.dart`, junto a los demás (`@lazySingleton`), y regenerar con
`flutter pub run build_runner build`.

---

## 4. Flujo A — El cerrojo (sin backend)

### Dónde vive

Un widget `CerrojoBiometrico` en el **`builder:` del `MaterialApp`** de `lib/main.dart`, envolviendo
al `child`. **No** una ruta del `Navigator`.

Es deliberado y no negociable: meter el cerrojo como ruta obligaría a manipular la pila, y este
proyecto ya se comió un *Stack Overflow* por tocar el árbol de navegación (ver la sección "Volver
al login: NUNCA montar un segundo `MyApp`" en `CLAUDE.md`). Como `builder:` se aplica por encima
de todo el `Navigator`, el cerrojo tapa cualquier pantalla sin tocar la pila, sin duplicar
`restorationScopeId` y sin interferir con `restorablePushNamedAndRemoveUntil`.

### Cuándo bloquea

`WidgetsBindingObserver` dentro de `CerrojoBiometrico`:

1. `paused` / `hidden` → guardar el instante en memoria.
2. `resumed` → si la biometría está activada **y** han pasado más de **30 s**, mostrar el cerrojo.
3. Arranque en frío con sesión guardada: `SplashBloc` navega a `menu_principal` como hoy, y el
   cerrojo aparece encima. El splash **no** se toca.

**Los 30 s de gracia son obligatorios, no cosmética.** La app saca al usuario fuera de sí misma en
tres sitios: el WebView de pago, `open_filex` al abrir el ticket, y el share sheet de Facturas.
Con gracia cero, el cerrojo saltaría a media transacción de pago.

**Además, excepción explícita mientras `pago_webview` esté arriba**: nunca bloquear durante una
pasarela de pago en curso, sin importar el tiempo. Se resuelve con una bandera en el BLoC que
`PagoWebViewPage` levanta en su `initState` y baja en su `dispose`.

### Qué se ve

Fondo idéntico al de `SplashPage` (gradiente adaptivo claro/oscuro, ya resuelto y aprobado),
`LogoRedondoUno`, el nombre del usuario, y un botón grande que relanza el prompt. Si el usuario
cancela: se queda el cerrojo con la opción **"Usar contraseña"**, que hace logout limpio y lleva a
`login` con `restorablePushNamedAndRemoveUntil`. Nunca se queda atrapado.

### Extra opcional (recomendado, decidir aparte)

Ocultar el contenido en el conmutador de apps: `FLAG_SECURE` en Android y una capa opaca en el
`applicationWillResignActive` de iOS. Es lo que hacen las apps bancarias. **Ojo:** `FLAG_SECURE`
impide también las capturas de pantalla del usuario y, en la práctica, complica la depuración por
adb (las capturas salen en negro — ya pasa con el teclado seguro del Oppo). Lo dejo fuera del
alcance de esta fase y lo anoto como decisión pendiente.

---

## 5. Flujo B — Login biométrico (requiere backend)

### Alta

1. Login normal con contraseña, con éxito.
2. Si el aparato soporta biometría **y** aún no está activada → `AlertDialog` (nunca SnackBar,
   regla del proyecto): *"¿Quieres entrar con Face ID la próxima vez?"*.
3. Si acepta → prompt nativo una vez → `POST /api/v1/biometria/registrar` con el `access_token`
   recién obtenido → el backend devuelve un `device_token` opaco.
4. Se guardan en `SecureStorage`: `device_token`, `device_id`, el `username` y el nombre para
   saludar (*"Entrar como Carlos"*).

### Uso

1. `LoginPage` arranca, `LoginInitialEvent` consulta si hay `device_token`.
2. Si lo hay → `BotonBiometrico` sobre el botón de "Iniciar Sesión", con el icono correcto según
   `getAvailableBiometrics()`: `Icons.face` para rostro, `Icons.fingerprint` para huella. El texto
   también cambia — *"Entrar con Face ID"* vs *"Entrar con huella"*. Nada de llamar "Face ID" a un
   lector de huellas Android.
3. Pulsar → prompt nativo → `POST /api/v1/biometria/login` con `device_token` + `device_id`.
4. El backend devuelve **el mismo JSON que `/api/v1/login`** → se reutiliza `AuthResponse.fromJson`
   sin tocar el parser, y se dispara la misma cascada que ya hay en `LoginResponse.dart`
   (`LoginSaveUserSession`, `MenuPrincipalRegistrarFcm`, y el refresco de `MenuPrincipalBloc`,
   `HomeBloc`, `EdoCtaListBloc`, `EdoCtaPagadosBloc` y `FacturaBloc`).

Ese último punto es lo que hace que esto no rompa nada: el login biométrico desemboca exactamente
en el mismo `Success(AuthResponse)` que el login con contraseña.

### Baja

- Interruptor del drawer apagado → `POST /api/v1/biometria/revocar` + borrar local.
- `/biometria/login` responde 401 → borrar local, apagar el interruptor y pedir contraseña, con
  `AlertDialog` explicando que hay que volver a activarlo.
- Cambio o recuperación de contraseña → el backend revoca (ver el documento del backend); la app
  se entera en el siguiente 401.

---

## 6. Los tres puntos donde esto se puede romper solo

Escritos aparte porque son los que se olvidan.

### 6.1 `logout()` borra la preferencia si se guarda mal

`AuthRepositoryImpl.logout()` hace `sharedPref.clear()`. Si la preferencia de biometría o el
`device_token` viven en `SharedPref`, **cerrar sesión los destruye** — y el login biométrico
existe precisamente para el momento posterior a cerrar sesión. Función inútil desde el primer día.

→ Todo lo de biometría va en `SecureStorage`, en claves **propias**, y `clearUserSession()` no las
toca (borra `user_session`, `access_token` y `refresh_token`, nada más). Hay un test guardián para
esto en §9.

### 6.2 `MainActivity` tiene que cambiar de clase base

`local_auth` necesita una `FragmentActivity` para poder mostrar el `BiometricPrompt`. Cambio:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity   // en vez de FlutterActivity
class MainActivity : FlutterFragmentActivity() { ... }
```

**El `onCreate` con la guarda del *launcher relaunch bug* se conserva letra por letra.** `isTaskRoot`
y `intent` existen igual en `FragmentActivity`; el `launchMode="singleTop"` del manifest tampoco
cambia. Pero la guarda es código que ya salvó a la app una vez, así que hay que **volver a probarla
a mano**: abrir un ticket, aceptar el diálogo "Abrir con", y volver por el icono del launcher. Si
la app se cierra al pulsar atrás, la guarda se rompió.

### 6.3 El tema de Android — era un crash, ya está corregido

**Resuelto, y resultó más serio de lo que parecía.**

Se leyó el bytecode de `androidx.biometric:1.1.0` para salir de dudas, y esto es lo que hay:

- `BiometricFragment.isUsingFingerprintDialog()` decide qué diálogo se muestra.
- Cuando da `true`, el diálogo lo dibuja la **propia librería** con
  `androidx.appcompat.app.AlertDialog$Builder` — verificado en el bytecode de
  `FingerprintDialogFragment.onCreateDialog`.
- Ese constructor lanza *"You need to use a Theme.AppCompat theme (or descendant) with this
  activity"* si el tema de la actividad no desciende de AppCompat. Los `styles.xml` heredaban de
  `@android:style/Theme.*.NoTitleBar`, que no lo es. **Crash**, no aviso.
- Da `true` cuando `SDK_INT < 28` —y el `minSdk` del proyecto es 24—, **y además** cuando
  `SDK_INT == 28` y el aparato no declara el sensor de huella. O sea, no era solo cosa de
  teléfonos viejos.

**Corrección aplicada:** `NormalTheme` deriva ahora de `Theme.AppCompat.Light.NoActionBar` en
`values/styles.xml` y de `Theme.AppCompat.NoActionBar` en `values-night/styles.xml`.

Lo que **no** se tocó, y por qué:

- **`LaunchTheme`**, en los cuatro archivos: es el del splash y ahí viven los ajustes de
  edge-to-edge.
- **`values-v31/` y `values-night-v31/`**: cubren API 31+, donde ese camino no se toma, y son
  justo los que mandan en el edge-to-edge de Android 12+.

`NormalTheme` es el tema que la actividad lleva puesto mientras corre la app, y lo aplica el
meta-data `io.flutter.embedding.android.NormalTheme` del manifest.

**No se pudo reproducir el crash en dispositivo**: el Oppo disponible es API 36 y ahí el prompt
lo pinta el sistema. La corrección se apoya en la lectura del bytecode, y compila y funciona en
API 36. Si algún día hay un emulador API 26 a mano, conviene confirmarlo.

Y como siempre: **no se ejecuta `flutter_native_splash:create` bajo ningún concepto** — destroza
los cuatro `styles.xml` y borra los `drawable-night-*/splash.png`.

Comprobado en el APK con `aapt2`: `LaunchTheme` conserva sus padres de plataforma
(`0x0103000d` claro, `0x01030009` oscuro) y solo `NormalTheme` pasó a AppCompat, en las dos
variantes.

### 6.4 La pausa espuria — el fallo que dejaba el cerrojo sin hacer nada

**Encontrado probando en el Oppo el 2026-08-25.** Es el fallo más serio de todo el trabajo, y no
se habría visto sin probar en dispositivo: no daba crash, no daba error, simplemente **el cerrojo
no se echaba nunca**.

Android **no manda una sola pausa por salida**. Manda `hidden` y `paused` al irse, y —esto es lo
que rompía todo— **manda otra pausa justo antes de la reanudación**, mientras la ventana vuelve a
entrar. Medido en el aparato:

```
12:07:31  App al fondo        ← salida real del usuario
12:08:09  App al fondo        ← pausa espuria, 0,1 s antes de volver
12:08:10  Vuelta al frente
```

El código hacía `_instantePausa = ahora()`, así que esa última pausa **pisaba el instante bueno**.
El tiempo fuera se calculaba en 0,1 s en vez de 39 s, nunca superaba la gracia, y el cerrojo no se
echaba jamás.

El arreglo es `_instantePausa ??= ahora()`: se conserva la **primera** pausa y solo se borra al
volver al frente. Lo que hay que medir es cuándo salió el usuario, no cuál fue el último evento
del sistema.

Hay test de regresión: *"cuenta desde la primera pausa, no desde la última"* en
`test/unit/blocs/biometria_bloc_test.dart`.

### 6.5 El botón atrás lo atraviesa, y se deja así a propósito

Con el cerrojo echado, el atrás de Android llega al `Navigator` de debajo. **No se puede
interceptar desde donde vive el cerrojo**, y conviene saberlo para que nadie lo "arregle" con algo
inerte:

- `PopScope` se registra contra `ModalRoute.of(context)`, que es **null** en el `builder` del
  MaterialApp. Queda inerte: parece que protege y no protege. Se llegó a poner y se quitó.
- Sobrescribir `didPopRoute` tampoco sirve: `_WidgetsAppState` se registra como observador en su
  propio `initState`, antes que cualquier descendiente, y `handlePopRoute` se detiene en el
  primero que responde.

**No expone nada.** Lo que se cierra queda tapado por el cerrojo, y al volver a abrir la app el
cerrojo se echa otra vez, porque la preferencia vive en `SecureStorage`. El atrás cierra la app;
no la abre.

---

## 7. iOS

> **Verificado en iPhone 17 Pro Max el 2026-08-25** sobre el build release, tras la limpieza
> obligatoria completa. La lista de abajo se recorrió y salió correcta. Queda **un solo cabo de
> documentación**: el punto 5 pide anotar qué `LocalAuthExceptionCode` llega al denegar el
> permiso de Face ID, y ese dato sigue sin escribirse.

### Lo que ya está hecho y verificado sobre el papel

| Qué | Estado |
| --- | --- |
| `NSFaceIDUsageDescription` en `Info.plist` | ✅ Añadida. **Obligatoria**: sin ella iOS no da error, **mata el proceso** al invocar Face ID |
| Capability / entitlement | Ninguno hace falta. Face ID no lleva capability en Xcode |
| Deployment target | 15.0 del proyecto ≥ 13.0 que pide `local_auth_darwin` 2.0.3 ✓ |
| Swift Package Manager | `local_auth_darwin` trae `Package.swift` con `.iOS("13.0")`. El proyecto usa SPM y el `post_install` del Podfile fuerza el paquete generado a `.iOS("15.0")`: 13 ≤ 15, **no hay conflicto** ✓ |
| Textos del prompt | `IOSAuthMessages` en español. En la 3.x solo existen `cancelButton` y `localizedFallbackTitle` |
| `localizedFallbackTitle` | Deliberadamente **sin poner**: iOS pone su propio texto ya traducido para el botón del código, y pasarle cadena vacía **oculta el botón** |
| Nombre del método | `Platform.isIOS` + `BiometricType.face` → dice "Face ID"; con Touch ID dice "Touch ID". En Android nunca usa esas marcas ✓ |
| Ciclo de vida | En iOS el sheet de Face ID manda `inactive`, que el cerrojo **ignora a propósito**. Solo reacciona a `paused` y `hidden`, que es cuando el usuario sale de verdad ✓ |
| El fallo de la pausa espuria (§6.4) | El arreglo (`??=`) es independiente de plataforma: sirva o no en iOS, no estorba ✓ |
| App Store | Basta el *usage description*. **No** añade preguntas de privacidad: el dato biométrico jamás sale del Secure Enclave ni llega a ningún servidor |

### Lo que hay que hacer y comprobar EN LA MAC

1. Limpieza obligatoria completa —es imprescindible aquí, hay un plugin nativo nuevo:
   ```bash
   flutter clean && flutter pub get && cd ios && pod install
   ./scripts/build_ios.sh
   ```
2. Comprobar que `pod install` dejó `Package.swift` en `.iOS("15.0")` y `LastUpgradeCheck = 2630`.
   Ambos los restaura el `post_install`; solo hay que verificarlo.
3. Abrir `Runner.xcworkspace` (nunca `Runner.xcodeproj`) y rechazar "Update to recommended
   settings" si lo ofrece.
4. En el iPhone, con Face ID dado de alta:
   - Activar el interruptor del drawer → debe salir el sheet de Face ID y quedar encendido.
   - El interruptor debe decir **"Face ID"**, no "huella" ni "desbloqueo biométrico".
   - Salir de la app más de 30 s y volver → cerrojo con el icono de rostro.
   - Salir menos de 30 s y volver → **no** debe pedir nada.
   - Entrar al WebView de pago, salir de la app un minuto, volver → **no** debe bloquear.
   - "Entrar con mi contraseña" → cierra sesión y lleva al login.
5. **El caso que solo se da en iOS:** la primera vez que la app invoca Face ID, iOS pide permiso.
   **Denegarlo** y comprobar que la app sigue usable —debe caer al código del dispositivo, porque
   `biometricOnly: false`— y que no se queda colgada. Anotar aquí qué `LocalAuthExceptionCode`
   llega en ese caso: si llega como `noDisponible`, el cerrojo se apagará solo, que es un
   comportamiento seguro pero conviene dejarlo escrito.
6. Tema claro y tema oscuro en la pantalla del cerrojo y en el interruptor.
7. En un iPhone con Touch ID, si hay alguno a mano: debe decir "Touch ID" y salir el icono de
   huella.

---

## 8. Android

| Qué | Detalle |
| --- | --- |
| `MainActivity` | `FlutterFragmentActivity` (§6.2) |
| Manifest | `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`. Es de instalación, **no** pide diálogo en tiempo de ejecución. `USE_FINGERPRINT` está obsoleto: no añadirlo |
| minSdk | 24, se queda. Ver §6.3 |
| Textos del prompt | `AndroidAuthMessages` de `local_auth_android`, en español |
| Fuerza del sensor | `biometricOnly: false` (decidido). Permite caer al PIN/patrón. En Android acepta tanto biometría *strong* (Clase 3) como *weak* (Clase 2) más credencial del dispositivo |

Opciones del `authenticate()` en ambas plataformas:

```dart
options: const AuthenticationOptions(
  biometricOnly: false,      // decidido: se permite PIN/patrón del dispositivo
  stickyAuth: true,          // sobrevive a que la app pase a segundo plano durante el prompt
  useErrorDialogs: true,     // el sistema ofrece ir a Ajustes si no hay biometría dada de alta
  sensitiveTransaction: true,
)
```

`stickyAuth: true` importa aquí: sin él, si llega una notificación push mientras el prompt está
abierto, la autenticación se cancela sola.

---

## 9. Tests

Obligatorios por la regla del proyecto. Siguiendo los patrones que ya existen:

| Archivo | Qué cubre |
| --- | --- |
| `test/unit/local/biometria_storage_test.dart` | Guardar/leer/borrar `device_token`, `device_id`, preferencia |
| `test/unit/usecases/biometria_use_cases_test.dart` | Los cinco casos de uso con un `AutenticadorBiometrico` doble: éxito, cancelación, `notEnrolled`, `lockedOut`, `permanentlyLockedOut` |
| `test/unit/services/biometria_service_test.dart` | `runWithClient` (patrón ya establecido): 200, 401, HTML en vez de JSON, timeout |
| `test/unit/blocs/biometria_bloc_test.dart` | La gracia de 30 s, la excepción de `pago_webview`, el ciclo pausa/reanudación |
| `test/unit/biometria_no_en_sharedpref_test.dart` | **Guardián nuevo.** Falla si alguien escribe algo de biometría en `SharedPref` — el fallo de §6.1 |

El guardián existente `services_no_filtran_excepciones_test.dart` cubrirá `BiometriaService` en
cuanto esté en `services/`; hay que asegurarse de que use `mensajeErrorRed(e)` y nunca
`Error(e.toString())`.

**Lo que ningún test cubre:** el prompt nativo. Es un diálogo del sistema, fuera del alcance de
Flutter. Verificación en dispositivo obligatoria (§10) antes de decir que funciona.

---

## 10. Verificación en dispositivo — la lista real

Nada de esto se da por bueno sin captura de pantalla.

### Android — hecho el 2026-08-25 en el Oppo CPH2639 (Android 16, API 36)

| # | Qué | Resultado |
| --- | --- | --- |
| 1 | Login normal, menú, drawer: nada roto | ✅ |
| 2 | El interruptor aparece en "Mi cuenta" y se puede activar | ✅ |
| 3 | Activar lanza el `BiometricPrompt` **del sistema** — sin crash | ✅ |
| 4 | Cancelar la activación **no** enciende el interruptor | ✅ |
| 5 | Arranque en frío con sesión y bloqueo activo → cerrojo + prompt | ✅ |
| 6 | Arranque en frío **sin** sesión → login, sin cerrojo | ✅ |
| 7 | Fuera 38 s y volver → bloquea | ✅ (tras arreglar §6.4) |
| 8 | Fuera 11 s y volver → **no** bloquea | ✅ |
| 9 | El cerrojo **absorbe los toques**: tocar donde estaría "Pagos Pendientes" no navega | ✅ |
| 10 | Cancelar el prompt deja el cerrojo puesto, sin diálogo molesto | ✅ |
| 11 | "Entrar con mi contraseña" → `DELETE /dispositivo/eliminar` **200** → login | ✅ |
| 12 | La preferencia sobrevive a reinstalar con `-r` | ✅ |
| 13 | Guarda del *launcher relaunch bug*: la tarea sigue en `sz=1` | ✅ |
| 14 | Tema oscuro: login, menú y cerrojo | ✅ |
| 15 | `USE_BIOMETRIC` presente y `NormalTheme` en AppCompat dentro del APK (`aapt2`) | ✅ |

**Dato útil:** el Oppo reporta `BiometriaDisponible.generica` —Android suele decir solo
`strong`/`weak`, sin el tipo de sensor—, así que la app dice "desbloqueo biométrico" y **no** le
promete al usuario ni cara ni huella. Era justo el caso que se previó.

**No verificable en este aparato:** el crash de tema en API ≤ 27 (§6.3). El Oppo es API 36 y ahí
el prompt lo pinta el sistema. Si algún día hay un emulador API 26, conviene confirmarlo.

**No probado todavía:** fallar la huella cinco veces seguidas para ver `bloqueoTemporal`, y borrar
todas las huellas del aparato para ver que el cerrojo se apaga solo.

### iOS — pendiente, requiere la Mac

Ver la lista de la sección 7.

---

## 11. Orden de trabajo

| Fase | Qué | Estado |
| --- | --- | --- |
| 1 | `local_auth`, `MainActivity`, manifest, `Info.plist`, tema AppCompat | ✅ Hecho |
| 2 | `AutenticadorBiometrico`, `BiometriaStorage`, casos de uso, DI, strings | ✅ Hecho |
| 3 | Cerrojo (`CerrojoBiometrico` + BLoC + gracia + excepción de pago) | ✅ Hecho |
| 3b | Interruptor en el drawer | ✅ Hecho |
| 4 | Tests (§9) | ✅ Hecho — 24 nuevos, 868 en total |
| 5 | Verificación en el Oppo (§10) | ✅ Hecho, salvo lo que pide huella real |
| 6 | Verificación en iPhone (§10) | ⏳ Requiere la Mac |
| 7 | Release `1.0.27+36`: AAB en la Linux, Archive en la Mac | ⏳ Pendiente |
| — | **El backend implementa lo suyo** (documento aparte) | ❌ No empezado |
| 8 | `BiometriaService`, botón de Face ID en el login, diálogo de alta | ❌ Bloqueada por el backend |

La versión ya está subida a **`1.0.27+36`** en `pubspec.yaml`: la `1.0.26+35` está publicada en
las dos tiendas, y la regla del proyecto obliga a que la nueva sea mayor.

**El cerrojo se puede publicar hoy.** El login biométrico (fase 8) es lo único que espera al
backend, y no publicarlo no deja nada a medias.

---

## 12. Lo que NO se toca

- `SplashBloc` / `SplashPage` — el cerrojo va por encima, no dentro.
- La pila del `Navigator` y `restorationScopeId`.
- `LaunchTheme` y los `drawable-night-*/splash.png`.
- `flutter_secure_storage`, que se queda en 10.x.
- El parser de `AuthResponse`: el backend devuelve el mismo JSON en el canje.
- `flutter_native_splash:create`: no se ejecuta.
