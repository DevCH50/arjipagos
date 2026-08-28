# Arjipagos - Aplicación de Pagos

## Descripción

Aplicación móvil Flutter para gestión de pagos. Plataformas: Android e iOS.

## Comandos

```bash
# Desarrollo
flutter run                              # Ejecutar app
flutter pub get                          # Instalar dependencias
flutter pub run build_runner build       # Generar código (injectable)

# Tests
flutter test                             # Ejecutar todos los tests
flutter test --coverage                  # Tests con cobertura

# Build
flutter build apk --release              # APK para Android
./scripts/build_ios.sh                   # Build iOS (restaura LastUpgradeCheck automáticamente)

# Release (script automatizado)
./scripts/release.sh                     # Build APK
./scripts/release.sh 1.2.0               # Build con nueva versión
./scripts/release.sh --install           # Build e instalar en dispositivo
./scripts/release.sh 1.2.0 --install     # Build, versión e instalar
./scripts/release.sh 1.2.0 --bundle      # Build APK + App Bundle (Play Store)

# Utilidades
flutter pub run flutter_launcher_icons   # Regenerar iconos
# NO ejecutar flutter_native_splash:create — ver aviso mas abajo
```

## Assets: qué se empaqueta y qué no

`pubspec.yaml` declara los assets **archivo por archivo**, NO por carpeta. Es
deliberado: declarar `assets/arji/` empaqueta todo lo que haya dentro —incluido
lo que git ignora—, y así se colaron **34 MB** de insumos de diseño y respaldos
dentro de la app (el APK pasó de 95.5 MB a 61.6 MB al sacarlos).

| Carpeta | Se empaqueta | Va al repo | Para qué |
| --- | --- | --- | --- |
| `assets/` | Sí, solo los archivos declarados | Sí | Lo que carga el código en runtime |
| `assets/disenio/iconos/` | No | Sí | Fuentes del icono para flutter_launcher_icons |
| `assets/disenio/iconos/anterior/` | No | Sí | Icono anterior, por si hay que volver atrás |
| `assets/disenio/splash/` | No | Sí | Fuente del splash |
| `otros/` | No | **No** | Almacén local (ver abajo) |

**`assets/disenio/` vive DENTRO de `assets/` y aun así no se empaqueta**, porque lo único que
entra al bundle es lo declarado archivo por archivo. Comprobado con `flutter build bundle`:
`build/flutter_assets/assets/` pesa 364 KB y contiene solo `logo_arji.png` y
`background_shopping.jpg`.

Eso vuelve la regla de arriba **más** crítica, no menos: bastaría con que alguien cambiara la
lista por un `- assets/` para meter los insumos de diseño en la app de golpe. Si algún día hace
falta declarar una carpeta entera, sacar `disenio/` de `assets/` primero.

## `otros/` — el almacén local

**En `otros/` va todo aquello que no debe subir al repositorio pero sí hay que conservar.**

Insumos en bruto, respaldos, material que ya no usa nadie, notas, exportaciones, capturas de
depuración. Si algo hay que guardar y no pinta nada en el repositorio, ahí va. Está en el
`.gitignore` desde siempre, así que basta con mover el archivo dentro para que deje de subir.

Es lo contrario de borrar: nada se pierde, simplemente deja de viajar al remoto. Ante la duda
entre borrar algo y dejarlo en el repo "por si acaso", la respuesta es **moverlo a `otros/`**.

Hoy guarda, entre otras cosas, `otros/sin_usar/` (34 MB de material de diseño que no usa
ningún build) y `otros/iconos_3d/` con las instrucciones del icono de iOS 18.

**Al añadir un asset nuevo:** darlo de alta en `pubspec.yaml` **y** en
`test/unit/assets_declarados_test.dart`, que falla si el código carga algo sin
declarar. Sin ese test, olvidarlo compila pero revienta en runtime con
"Unable to load asset".

## NO ejecutar `flutter_native_splash:create`

El splash generado está **hecho a mano encima de lo que produjo el generador** y
volver a ejecutarlo lo destroza. Comprobado el 2026-08-23: reescribe los cuatro
`styles.xml` (rompiendo el edge-to-edge de Android 15), **borra** los
`drawable-night-*/splash.png`, y cambia `ios/Runner/Info.plist` y
`LaunchScreen.storyboard`.

No depende de la ruta de la imagen: es la versión actual del paquete, que genera
distinto de la que se usó en su día. Si alguien lo ejecuta por error:
`git checkout -- android/app/src/main/res ios/Runner`.

Cambiar el splash implica rehacer a mano el edge-to-edge después. Los drawables
y el storyboard ya generados están versionados; ahí es donde se toca.

## Dos máquinas: la Mac hace iOS, la Linux hace Android

**Los builds están repartidos y no son intercambiables.**

| Máquina | Qué se hace ahí |
| --- | --- |
| **Mac** | Solo iOS: limpieza obligatoria, `./scripts/build_ios.sh`, Archive y Distribute a App Store Connect |
| **Linux** | Solo Android: `flutter build apk --release`, `flutter build appbundle --release`, `adb install` y la subida a Play Console |

Las instrucciones de release de abajo describen **el trabajo de Android**, y por tanto solo
aplican en la Linux. En la Mac no hay que lanzarlas: ni siquiera hace falta el SDK de Android.

Dos consecuencias prácticas:

- **No dar por hecho que un APK o un AAB existe en la máquina donde se está.** Si
  `ARJIPAGOS_PROGRESS.md` dice que el AAB "ya está generado", puede estar en la otra máquina
  —o haber desaparecido aquí—: `build/` es local y el `flutter clean` de la limpieza iOS lo
  borra entero. Pasó el 2026-08-24, con el AAB de la 1.0.26+35 listo.
- **Al listar lo que falta para publicar, separar por máquina.** Que iOS esté subido no dice
  nada del estado de Android, y al revés.

## Instrucciones para Release (Agente)

> **Esto se ejecuta en la máquina Linux.** Ver la sección anterior.


**Cuando el usuario diga:** "nueva versión", "release", "sube versión", "build release", "genera APK"

**Ejecutar estos comandos en paralelo:**

```bash
# 1. Build APK (en paralelo)
flutter build apk --release

# 2. Build App Bundle (en paralelo)
flutter build appbundle --release
```

**Después de los builds: PREGUNTAR antes de instalar en el dispositivo.**

El Oppo es el teléfono de diario de Carlos, no un banco de pruebas. Y la instalación no es
inocua: el release y el debug tienen firmas distintas, así que hay que **desinstalar primero**
—lo que borra la sesión y los datos de la app—. Pasó el 2026-08-25 con la 1.0.27+36.

Para verificar en dispositivo, usar el build de `flutter run` (debug). El release solo se
instala si Carlos lo pide:

```bash
# Solo cuando lo pida. Requiere desinstalar antes: las firmas no coinciden.
adb uninstall mx.moriah.arjipagos
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Si especifica versión** (ej: "nueva versión 1.3.0"):

1. Editar `pubspec.yaml` línea `version:` → `version: 1.3.0+N` (incrementar N)
2. Ejecutar builds e instalar

**Rutas de salida:**

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

**Reglas de versionado — OBLIGATORIAS:**

1. La versión en `pubspec.yaml` debe ser MAYOR a la publicada en Play Store y App Store. Si coincide o es menor, incrementar patch +1 y build number +1 (ej: `1.0.19+27` → `1.0.20+28`).
2. Si ya existe una versión en `pubspec.yaml` que aún NO ha sido publicada en ninguna tienda, NO crear ni incrementar a una nueva versión. Usar esa versión pendiente para el release. Solo crear versión nueva si el usuario lo indica explícitamente.

**Verificar antes de release a producción:**

- `ApiConfig.isProduction = true`
- Permiso INTERNET en AndroidManifest.xml

## iOS — Archive & Distribute (App Store)

### Limpieza obligatoria antes de cualquier build iOS

> **Todo lo de esta sección ocurre en la Mac.**

Siempre ejecutar esta secuencia antes de Archive o build en dispositivo físico, para garantizar que se usen las últimas versiones:

```bash
flutter clean
flutter pub get
cd ios && pod install
./scripts/build_ios.sh    # En lugar de `flutter build ios` directo
```

Luego abrir `Runner.xcworkspace` (NO `Runner.xcodeproj`).

### Checklist antes de Archive

1. Ejecutar limpieza obligatoria (ver sección anterior)
2. Verificar `ApiConfig.isProduction = true`
3. Abrir `Runner.xcworkspace` (NO `Runner.xcodeproj`)
4. Menú: **Product → Archive**
5. En Organizer: **Distribute App → App Store Connect**

Si Xcode ofrece **"Update to recommended settings"**, rechazarlo: reescribe
`LastUpgradeCheck` y tira abajo el blindaje de 2630.

### Apariencias del icono (iOS 18) — decidido: NO se usan

**Resuelto el 2026-08-23. El catálogo no lleva variantes Dark ni Tinted, y es
deliberado.** No volver a añadirlas sin leer esto entero.

**Por qué.** `AppIcon.appiconset` está en formato antiguo: 11 entradas `iphone`,
13 `ipad`, 1 `ios-marketing`, y **ningún slot `universal`**. En ese formato
**Xcode no muestra el control "Appearances" en el inspector** — no existe ningún
hueco Dark/Tinted donde soltar un PNG. Habilitarlo exige migrar al formato
*single-size* (un solo 1024 universal), lo que **borra las 25 entradas por
tamaño**, y el objetivo de despliegue es iOS 15.

**Qué pasa si alguien arrastra PNG al catálogo.** Xcode los copia dentro de
`AppIcon.appiconset/` pero **no los referencia en `Contents.json`**, porque no hay
slot al que asignarlos. Quedan como *huérfanos* y Xcode avisa en cada build:

```
The app icon set "AppIcon" has N unassigned children.
```

Es un **aviso amarillo** —no bloquea build, instalación, Archive ni la subida a
App Store Connect— pero ensucia el log. Pasó dos veces el 2026-08-23 antes de
entender la causa.

**Estado actual.** El appiconset tiene 25 entradas en `Contents.json` y 21 PNG,
con **0 huérfanos y 0 fantasmas**. Verificable así:

```bash
python3 -c "
import json,os
p='ios/Runner/Assets.xcassets/AppIcon.appiconset'
d=json.load(open(p+'/Contents.json'))
refs={i.get('filename') for i in d['images'] if i.get('filename')}
files={f for f in os.listdir(p) if f.endswith('.png')}
print('HUERFANOS (causan el aviso):',sorted(files-refs) or 'ninguno')
print('FANTASMAS (rompen el build):',sorted(refs-files) or 'ninguno')
"
```

En iOS 18+ el sistema aplica su propio tratamiento automático al icono normal en
modo oscuro y con tinte. Se pierde el control fino sobre esas dos variantes; a
cambio, el catálogo queda coherente y sin avisos.

**Dónde está el material, por si algún día se retoma:**

| Ruta | Qué hay |
| --- | --- |
| `assets/disenio/iconos/` | Fuentes 3D, incluidas `icono_ios_oscuro_3d.png` e `icono_ios_tinte_3d.png` (1024×1024). Va al repo, **no** se empaqueta |
| `otros/iconos_3d/` | Los `Icon-App-1024x1024@1x-dark.png` y `-tinted.png` que estuvieron versionados hasta el 2026-08-23. **No** va al repo (`otros/` está en `.gitignore`) |

Retomarlo implica la migración a *single-size* y volver a probar el icono en
dispositivo antes de un Archive. **No** editar `Contents.json` a mano: además de
ser frágil, `flutter_launcher_icons` lo reescribe entero en cada ejecución.

Para deshacer cualquier cambio del catálogo: `git checkout ios/Runner/Assets.xcassets/`.

### Configuración crítica — NO modificar sin revisar

| Archivo           | Valor fijo                                    | Motivo                                           |
| ----------------- | --------------------------------------------- | ------------------------------------------------ |
| `project.pbxproj` | `LastUpgradeCheck = 2630`                     | Valor correcto para Xcode 26.3 estable           |
| `Runner.xcscheme` | `LastUpgradeVersion = "2630"`                 | Mismo motivo                                     |
| `Runner.xcscheme` | `LaunchAction buildConfiguration = "Release"`  | El botón Run instala un build AOT autónomo en el iPhone físico (sobrevive cerrar/reabrir). Flujo solo-dispositivo; no se usan simuladores |
| `Runner.xcscheme` | `ArchiveAction buildConfiguration = "Release"` | El Archive/Distribute usa ESTA acción (no LaunchAction) |
| `Podfile`         | `objective_c` usa `dwarf`                     | XCFramework precompilado — no puede generar dSYM |
| `Package.swift` (SPM generado) | plataforma `.iOS("15.0")`        | Firebase exige 15.0; el `post_install` del Podfile lo fuerza |

### Errores conocidos y soluciones

**Ruido normal en la consola de Xcode — NO son fallos**

Estos mensajes salen en cada arranque y **no hay nada que corregir**. Verificados
en iPhone 17 Pro Max con iOS 26.6.1 el 2026-08-23, ampliados el 2026-08-24 tras
recorrer todos los módulos de la app, y de nuevo el 2026-08-26 con la 1.0.28+37
(las cinco últimas filas). La fila de `xpc_user_sessions_get_foreground_uid` se añadió el
2026-08-28 con la 1.0.29+38, al entrar a pagar. Ninguno de estos símbolos aparece en `lib/`,
`ios/Runner/` ni en los Pods — se comprueba con `grep -rI` antes de darlos por ruido:

| Mensaje | Qué es |
| --- | --- |
| `FIRMessaging ... will swizzle remote notification receiver handlers` | Firebase avisa de que intercepta los handlers de push. Silenciarlo con `FirebaseAppDelegateProxyEnabled = NO` obliga a implementarlos a mano: **no tocar**, rompería las notificaciones |
| `FlutterView implements focusItemsInRect:` | Log interno del engine de Flutter sobre UIKit |
| `Using the Impeller rendering backend (Metal)` | Informativo, y es buena señal |
| `empty dSYM file detected` en `objective_c` | Esperado: es un XCFramework precompilado sin debug info. Lo que exige App Store Connect es que el **UUID** del dSYM coincida con el del binario, y coincide (comprobar con `dwarfdump --uuid`) |
| `Unable to simultaneously satisfy constraints` con `_UIModernBarButton` / `_UIButtonBarButton` | Bug interno de UIKit en la barra del *share sheet* nativo. Todas las clases implicadas son de UIKit, ninguna del proyecto. UIKit se autorepara |
| `LaunchServices`, `canmaplsdatabase`, `sandbox extension`, `RBS`, `usermanagerd`, `WebContent`, `GPUProcessProxy IdleExit` | Ruido del sistema por permisos que una app normal no tiene |
| `Failed to request default share mode` / `error fetching item for URL` al abrir un PDF o ZIP | Ruido de LaunchServices al resolver el tipo de archivo desde `open_filex`. Los archivos abren bien |
| `Reading from public effective user settings` | El sistema leyendo preferencias. Informativo |
| `Gesture: System gesture gate timed out` | UIKit cierra el reconocedor de gestos de borde cuando vence el plazo sin que el gesto se complete. Sale al navegar con gestos |
| `RTIInputSystemClient ... dismissAutoFillPanel ... requires a valid sessionID` | iOS intenta cerrar el panel de autorrelleno cuando ya no hay sesión de texto activa. Es constante en Flutter porque el engine gestiona su propio `TextInput` y UIKit no se entera. Sale una línea por cada teclado que se cierra |
| `Snapshotting a view (UIKeyboardImpl) that is not in a visible window` | UIKit fotografía su propio teclado para la animación de salida cuando ya lo quitó de pantalla. Clase de UIKit, no del proyecto |
| `The variant selector cell index number could not be found` | UIKit construyendo las celdas de variantes del teclado (los tonos de piel y variantes de presentación de emoji). Sale en tandas, una línea por celda. Comprobado el 2026-08-25: el símbolo no aparece en `lib/`, `ios/Runner/` ni en los Pods — no sale del proyecto |
| `containerToPush is nil, will not push anything to candidate receiver for request token: …` | El subsistema de continuidad de iOS evaluando si hay algo que ofrecer a un dispositivo cercano. No hay actividad que empujar, así que no empuja nada. Sale intercalado con las tandas del teclado |
| `Unable to hide query parameters from script (missing data)` | WebKit intentando aplicar su protección contra rastreo por enlace en el `WKWebView` del pago, sin datos que aplicar |
| `WebProcess::markAllLayersVolatile: Failed to mark layers as volatile` | WebKit liberando las capas de la webview al dejar de estar en primer plano |
| `xpc_user_sessions_get_foreground_uid() failed with error 1 - Operation not permitted` | El proceso `WebContent` de WebKit preguntándole a XPC qué sesión de usuario está en primer plano. Su sandbox —más estrecho que el de la app— no tiene ese permiso: la consulta falla, WebKit sigue adelante y no usa el dato para nada. Sale al abrir el `WKWebView` del pago, una línea por proceso. **Ver dos PID distintos de `WebContent` es normal**: es el *process swap* de WebKit al navegar a otro origen (la pasarela mandando del sitio de Adquira al del banco) |
| `Failed to terminate process … RBSRequestErrorDomain Code=3 "No such process found"` | WebKit cerrando un proceso `WebContent` que ya había salido solo. Llega tarde y no encuentra a quién matar |
| `-- LLDB integration loaded --` | El depurador de Xcode adjuntándose. Solo sale al correr desde Xcode, nunca en la app instalada |

**Con el botón Run no sale NI UNA línea de la app, y es lo esperado**

`AppLogger._log()` está envuelto en `if (kDebugMode)`, y el botón **Run** de Xcode usa
`LaunchAction buildConfiguration = "Release"`. Resultado: en el iPhone físico la consola es
solo sistema, Flutter y WebKit — cero salida de ArjiPagos. **Un log sin líneas de la app no
significa que algo no se ejecutara.**

Consecuencia a tener presente: el aviso del contrato 2 provisional
(`CarritoBloc.dart:230`, cuando `configuracion.esProvisional`) **también es invisible ahí**. Es
uno de los tres recordatorios de que el dinero de "Otros pagos" entra en la cuenta del emisor 1.
Para verlo dispararse hace falta `flutter run`, que fuerza Debug. Comprobado el 2026-08-28.

**Error: `Failed to change device orientation ... BSActionErrorDomain Code=1`**

- Causa: `main.dart` pedía `DeviceOrientation.portraitDown`, pero el `Info.plist`
  solo declara `UIInterfaceOrientationPortrait`, y los iPhone con Dynamic Island
  no admiten upside-down por hardware. iOS respondía `response-not-possible`.
- Solución (aplicada el 2026-08-23): `setPreferredOrientations` pide **solo**
  `portraitUp`. No añadir `portraitDown` sin declarar antes
  `UIInterfaceOrientationPortraitUpsideDown` en el `Info.plist` — y aun así no
  funcionará en iPhone moderno.

**Error: "Missing dSYM" al subir a App Store Connect**

- Causa: pod `objective_c` es XCFramework precompilado, no puede generar dSYM
- Solución: ya está en `Podfile` — el pod usa `dwarf` en vez de `dwarf-with-dsym`
- Si reaparece, verificar que el bloque `if target.name == 'objective_c'` siga en el Podfile y correr `pod install`

**Flujo de ejecución: solo dispositivo físico (sin simuladores)**

- Decisión del proyecto: NO se usan simuladores (consumen mucho espacio). El botón **Run** de Xcode usa `LaunchAction buildConfiguration = "Release"`, que instala en el iPhone físico un build AOT **autónomo** que sobrevive cerrar/reabrir la app.
- Un build **Debug** en dispositivo físico es "tethered-only" (JIT): funciona conectado a la Mac pero **crashea al cerrarlo y reabrirlo suelto**. Por eso NO se usa Debug para correr en dispositivo.
- Las configs `Release` y `Profile` tienen `SUPPORTED_PLATFORMS = iphoneos` (solo dispositivo). Con `LaunchAction = Release`, Xcode no ofrece simuladores — es intencional.
- Si algún día se necesita el simulador o hot reload: usar `flutter run` (fuerza Debug) o cambiar temporalmente `LaunchAction` a `Debug` en **Edit Scheme**, pero NO commitear ese cambio (el valor versionado debe seguir en `Release`).
- El **Archive** NO depende de la `LaunchAction`; usa la `ArchiveAction`, que también está en `Release`.

**Error: "The package product 'firebase-core'/'firebase-messaging' requires minimum platform version 15.0 ... but this target supports 13.0"**

- Causa: el proyecto usa Swift Package Manager. Flutter regenera `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` con el default `.iOS("13.0")` en cada `flutter pub get` / `flutter clean`, pero Firebase exige 15.0. La corrección de Flutter (`updateMinimumDeployment`) solo se aplica en `flutter build ios` por CLI, NO al compilar desde Xcode.
- Solución permanente (automática): el `post_install` del `Podfile` fuerza la plataforma a `.iOS("15.0")` en cada `pod install`. Como `pod install` es parte del flujo manual (`flutter clean && flutter pub get && pod install`) y de todo `flutter build`, la corrección es automática.
- NO borrar ese bloque del Podfile. Si el error reaparece, correr `pod install` desde `ios/` y verificar que `Package.swift` quede en `.iOS("15.0")`. NO editar el `Package.swift` a mano (es efímero y se regenera).

**Nota: `flutter build ios` resetea `LastUpgradeCheck` / `LastUpgradeVersion` a `1510`**

- Causa: Flutter 3.x no reconoce Xcode 26.3 (2630) y lo degrada a su versión conocida más reciente
- Solución permanente (automática): el `post_install` del `Podfile` restaura ambos valores a **2630** en cada `pod install`. Como `flutter build ios` / `flutter run` ejecutan `pod install` DESPUÉS de degradarlos, la corrección es automática y no requiere pasos manuales. El bloque responsable en el Podfile fija `LastUpgradeCheck` en `project.pbxproj` (vía `root_object.attributes`) y `LastUpgradeVersion` en `Runner.xcscheme` (por texto).
- NO borrar ese bloque del Podfile. Si se toca, verificar con un `pod install` que ambos valores queden en 2630.
- `./scripts/build_ios.sh` sigue siendo válido como capa extra, pero ya no es imprescindible para este fix.

## Bloqueo biométrico (Face ID / huella) — tres cosas que no se pueden tocar

Añadido el 2026-08-25 con `local_auth` 3.x. El plan completo está en `PLAN_FACE_ID.md`; lo que
falta del backend, en `PLAN_FACE_ID_BACKEND.md`. **Solo está hecho el cerrojo** —pedir la
identidad al volver a la app—, que es 100 % local y no habla con el servidor. El login
biométrico está sin hacer y espera tres endpoints.

**1. `MainActivity` extiende `FlutterFragmentActivity`, no `FlutterActivity`.**
`BiometricPrompt` de androidx necesita una `FragmentActivity` para adjuntar su fragmento. La
guarda del *launcher relaunch bug* del `onCreate` se conserva intacta y sigue funcionando
(comprobado: la tarea se queda en `sz=1` tras un intent del launcher).

**2. `NormalTheme` deriva de AppCompat en `values/` y `values-night/`. No devolverlo a
`@android:style/Theme.*`: es un CRASH, no un detalle estético.**
`androidx.biometric` 1.1.0 pinta su propio diálogo con `androidx.appcompat.app.AlertDialog$Builder`
cuando `isUsingFingerprintDialog()` da true, y ese constructor revienta con *"You need to use a
Theme.AppCompat theme"* si el tema no desciende de AppCompat. Ocurre con `SDK_INT < 28` —el
`minSdk` aquí es 24— y también en API 28 sin sensor de huella. Verificado leyendo el bytecode.
Los `values-v31/` **no** se tocaron: cubren API 31+, donde ese camino no se toma, y son los que
mandan en el edge-to-edge. `LaunchTheme` tampoco.

**3. La preferencia del bloqueo vive en `SecureStorage`, JAMÁS en `SharedPref`.**
`AuthRepositoryImpl.logout()` hace `sharedPref.clear()`. Lo que se guarde ahí se borra en cada
cierre de sesión — que es exactamente cuando el login biométrico lo va a necesitar. Sería un
fallo silencioso, sin crash. Hay test guardián:
`test/unit/biometria_no_en_sharedpref_test.dart`.

**Detalles de diseño que parecen arbitrarios y no lo son:**

- El cerrojo es un **overlay en el `builder` del `MaterialApp`**, como `ActualizacionObserver`.
  No es una ruta del `Navigator`: ver la sección de abajo sobre el *Stack Overflow*.
- **Gracia de 30 s** antes de bloquear al volver del segundo plano, y **nunca** encima de
  `pago_webview`. Sin eso, el cerrojo salta cuando el usuario sale a copiar el código que le
  mandó el banco y no puede terminar de pagar. La ruta visible la sigue `RutaActualObserver`,
  para no tocar `PagoWebViewPage`.
- Mientras el diálogo nativo está abierto se **ignoran los cambios de ciclo de vida**: en
  Android el propio `BiometricPrompt` hace que la app reporte `paused`, y sin esa guarda el
  cerrojo se rebloquea a sí mismo en bucle.
- Si el aparato deja de admitir biometría, **el bloqueo se apaga solo**. El interruptor para
  apagarlo está dentro de la app; sin esto, quien borre sus huellas se queda encerrado fuera.

`ios/Runner/Info.plist` **debe** llevar `NSFaceIDUsageDescription`: sin esa clave iOS no da un
error, **mata el proceso** en cuanto se invoca Face ID.

## Emisores fiscales: cada uno es una app aparte, y no se pueden mezclar

**Un cobro de Adquira entra en UNA cuenta bancaria.** Cada `emisorfiscal_id` es un contrato
distinto con el proveedor, con su propia cuenta. De ahí sale toda la regla: **los emisores son
totalmente independientes y ninguno sabe que existe el otro.**

El backend manda `emisorfiscal_id` **dentro de cada pago** de `estado_de_cuenta[]` (no en la
raíz de la respuesta, donde estuvo al principio). `EstadoDeCuenta.emisorFiscalId` lo lee
tolerando texto, número y ausencia; si falta cae en `kEmisorFiscalPredeterminado` (1), que es
como se comportaba la app cuando había un solo contrato.

### Todo lo que va por emisor

| Qué | Dónde |
| --- | --- |
| Endpoint y parámetros de Adquira (`idexpress`…) | `ConfiguracionAdquira` |
| Reglas de selección y referencia | `PoliticaEmisor` |
| Clave del almacén de selección | `seleccion_pagos_ef1`, `_ef2`, … |
| Instancia de `EdoCtaListBloc` y `CarritoBloc` | `lib/src/di/RegistroEmisores.dart` |
| Ruta y título de su pantalla | `ConfiguracionAdquira.ruta` / `.titulo` |

**Añadir un EF3 es una entrada más en `ConfiguracionAdquira` y su ruta en `main.dart`.** No hay
que tocar pantallas, widgets ni BLoCs: el registro instancia uno por cada emisor conocido.

### Lo que NO se puede volver a hacer

1. **Ni una clave de almacén compartida.** Hasta el 2026-08-26 los dos emisores escribían en
   `edo_cta_pagos_seleccionados`. Consecuencia: recargar una lista, limpiar la selección,
   vaciar un carrito **o completar un pago** borraba también la selección del otro emisor. El
   del pago era el peor: liquidabas en uno y perdías el carrito preparado en el otro. Esa clave
   se descarta al arrancar (`descartarSeleccionCompartidaAntigua`); no repartirla es
   deliberado, porque aquí no se sabe de qué emisor es cada pago guardado.

2. **`EdoCtaListBloc` y `CarritoBloc` NO van en `blocProviders`.** Hay una instancia por emisor
   y viven en el registro; cada pantalla toma la suya con `BlocProvider.value`, así que los
   widgets de dentro siguen usando `context.read<...>()` sin enterarse. El cierre de sesión las
   vacía **todas** recorriendo `.todos`, y `LoginResponse` las recarga todas — el contrato de la
   sección anterior sigue en pie, pero por registro y no por `context.read`.
   Al sacarlos de `blocProviders` se perdió el `..add(EdoCtaListInitialEvent())` que los
   arrancaba: por eso la carga inicial la dispara ahora `EdoCtaPage`, y solo si su BLoC está
   vacío.

3. **El ámbito de emisor va junto al de ciclo, siempre.** La respuesta del servidor trae los
   pagos de todos los emisores juntos, así que cualquier recorrido de `alumno.estadoDeCuenta`
   tiene que filtrar por emisor además de por ciclo. Sin eso: el orden ascendente pedía marcar
   antes pagos de la otra pantalla, el arrastre al deseleccionar vaciaba el carrito ajeno, y el
   tope de la referencia contaba pagos que ese cobro no incluye.

4. **El push de pago solo refresca su emisor.** Llega con `campania: "pago"`,
   `accion: "pago_exitoso"` y `emisorfiscal_id` (texto, como todo en FCM). Cada `EdoCtaListBloc`
   lo escucha y **descarta el que no es suyo**. `EdoCtaPagadosBloc` es otra historia: se
   refresca con cualquier pago, porque muestra todos. Probado con un push real el 2026-08-26.

5. **Pagos Realizados no se toca.** No tiene `emisorfiscal_id` ni le hace falta.

6. **`emisorfiscal_id` se manda en las dos peticiones**, desde el 2026-08-28: en el `toMap()` de
   `PagoRequest` que va a Adquira, y en el body de `POST /alumno/estado-de-cuenta-sin-pagar/`.
   Comprobado en dispositivo que el backend **ya filtra en servidor** por ese campo: el mismo
   usuario y el mismo endpoint devuelven pagos con el 1 y una lista vacía con el 2.

   **En el endpoint el parámetro es opcional, y omitirlo significa «todos». No ponerle valor por
   defecto.** `MenuPrincipalBloc` usa ese mismo endpoint para la familia y los alumnos del menú,
   que no son de ningún emisor; con un filtro allí, los alumnos que solo tuvieran pagos del
   emisor 2 desaparecerían del menú sin que nada fallara. Hay test guardián.

   Mientras el contrato 2 siga con datos prestados, los dos emisores mandan el mismo `idexpress`
   ('928'), así que **`emisorfiscal_id` es lo único que los distingue** del lado del cobro.

### ⚠️ El contrato 2 lleva datos prestados del 1

`ConfiguracionAdquira.ef2` usa hoy el `endpoint` y el `idExpress` del emisor 1, puestos a
propósito para poder montar la pantalla mientras llegan los reales. **Con eso, todo lo que se
cobre en "Otros pagos" entra en la cuenta bancaria del emisor 1**, y Adquira no da ningún error
porque para él la operación es válida.

Está marcado con `esProvisional: true`, avisa por `AppLogger` en cada cobro y hay tests que lo
recuerdan (`test/unit/configuracion_adquira_test.dart`).

**Publicar así está AUTORIZADO por el cliente desde el 2026-08-26**, mientras su proveedor le
entrega la cuenta del contrato 2. Es una decisión suya, con conocimiento de que el dinero de
"Otros pagos" entra en la cuenta del emisor 1 y hay que reasignarlo a mano.

No es permanente: en cuanto lleguen los datos reales, sustituir `endpoint` e `idExpress` en
`ConfiguracionAdquira.ef2`, revisar el resto de parámetros, quitar `esProvisional` y borrar el
grupo de tests "contrato 2 (PROVISIONAL)", que existe solo para no olvidarlo.

## «No hay…» no es «Error al cargar»

**Un `404` con `success: false` significa «este usuario no tiene nada», y debe pintar el estado
vacío de la pantalla, nunca el de error.** Lo devuelve el backend cuando no hay familia asignada
—ni alumnos, ni estados de cuenta, ni facturas—:

```json
{"success": false, "message": "El usuario no tiene una familia asignada."}
```

Hasta el 2026-08-28 los services metían eso en su rama de error y la pantalla sacaba **«Error al
cargar»** en rojo con un `AlertDialog` encima. Los estados vacíos ya existían; no se llegaba a
ellos porque el cuerpo de cada pantalla comprueba el error **antes** que la lista vacía.

Lo resuelve `esRespuestaSinDatos()` (`lib/src/data/api/RespuestaSinDatos.dart`), que usan
`EdoCtaService`, `EdoCtaPagadosService`, `FacturaService` y `HomeService` para devolver un
`Success` vacío —hay un constructor `.vacio()` en cada modelo de respuesta—.

**Se exigen las dos condiciones, `404` Y `success: false`.** El `404` de Laravel cuando la ruta
no existe llega **sin** esa clave y tiene que seguir siendo un error de verdad. Tragarse
cualquier `404` convertiría un fallo de despliegue —una ruta renombrada, un prefijo mal puesto—
en una pantalla vacía y silenciosa, que es peor que el problema original. Hay tests por los dos
lados en `test/unit/respuesta_sin_datos_test.dart`.

**El usuario siempre debe poder recargar.** Las cuatro pantallas llevan **refresh en el App Bar**
—sin condicionarlo a ningún estado, tampoco a `isLoading`— y botón **Reintentar** tanto en el
estado de error como en el vacío. Que ahora no haya nada no significa que no vaya a haberlo en
cuanto el colegio dé de alta un pago.

## El concepto del pago se lee entero

**No abreviar y no recortar.** El concepto es lo que le dice al usuario qué está pagando.

`EstadoDeCuenta.descripcionCompleta` devuelve el texto tal como llega, solo con los espacios
colapsados —el backend manda `'REINSCRIPCION SECUNDARIA  26 / 27  '`— y en mayúsculas, porque no
es constante con ellas. **No volver a meter un mapa de sustituciones**: hasta el 2026-08-28
'COLEGIATURA' salía como 'COL' y 'SECUNDARIA' como 'SEC', y el usuario leía un código. Hay un
test guardián que falla si reaparece cualquiera de aquellas abreviaciones.

Lo pinta **`ConceptoPago`** (`lib/src/presentation/widgets/ConceptoPago.dart`), y las tres
pantallas que muestran conceptos usan ese mismo widget: Estados de Cuenta, Carrito y Pagos
Realizados. **Tamaño fijo `bodyLarge`, sin `maxLines` y sin `overflow`**: si no cabe, envuelve.

**No devolverlo a la rampa que encogía.** Antes se llamaba `ConceptoEscalonado` y medía con
`TextPainter` para bajar de escalón (16 → 14 → 12) hasta caber en una línea. Con los conceptos
enteros casi todos bajaban, la lista quedaba con un renglón a 16 y el siguiente a 14, y además
descuadraba con el importe, que conservaba su tamaño. **Decisión de Carlos el 2026-08-28:**
entre altura pareja con letras dispares y tipografía uniforme con alturas dispares, se elige la
segunda — el tamaño de la letra es lo que el ojo compara entre renglones, la altura no.

El importe va del **mismo tamaño que el concepto y en negrita**: destaca por peso y color, no por
ser más grande. Hay tests que fijan las dos cosas.

## Volver al login: NUNCA montar un segundo `MyApp`

**`MyApp` solo se instancia en el `runApp` de `lib/main.dart`.** Para volver al login —cierre
de sesión, o al terminar de cambiar la contraseña— se navega a la ruta con nombre:

```dart
Navigator.restorablePushNamedAndRemoveUntil(context, 'login', (route) => false);
```

**Por qué.** Hasta el 2026-08-24 el cierre de sesión hacía esto:

```dart
navigator.pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const MyApp()),  // ← MAL
  (route) => false,
);
```

Eso monta un **segundo `MaterialApp` dentro del que ya corre**. Los dos declaran el mismo
`navigatorKey` (`appNavigatorKey`, un `GlobalKey<NavigatorState>`), así que Flutter
**reparenta** el `Navigator` existente hacia dentro del nuevo `MaterialApp`… que vive dentro
de una ruta de **ese mismo `Navigator`**. El árbol queda cíclico y `redepthChildren` desborda
la pila:

```
I flutter : Stack Overflow
I flutter : #3  SlottedContainerRenderObjectMixin.redepthChildren
I flutter : #4  RenderObject.redepthChild        ← se repite hasta agotar la pila
```

Es un fallo de Dart: reventaba **igual en Android y en iOS**. Los `restorationScopeId`
duplicados iban por el mismo camino.

**Usar la variante `restorable*`**, como ya hace `SplashPage`. Sin ella, la pila que Android
guarda al reciclar el proceso conserva `menu_principal` y devuelve al usuario a una pantalla
para la que ya no hay sesión.

**Los BLoCs sobreviven al cierre de sesión.** Los de `blocProviders` viven en la raíz de la
app, así que al no recrearse `MyApp` conservan los datos del usuario anterior. Se ataca por los
dos lados, y hacen falta los dos:

1. **Al cerrar sesión se vacían.** `cerrarSesionCompleta(context)` manda un evento
   `…LimpiarSesion` a `MenuPrincipalBloc`, `HomeBloc`, `EdoCtaListBloc`, `EdoCtaPagadosBloc` y
   `FacturaBloc`, y cada uno emite su **estado inicial entero**. No vale un `copyWith`: el de
   estos estados nunca vacía un campo (`familia ?? this.familia`), así que arrastraría lo del
   usuario que se va. `CarritoBloc` y `NotificacionBloc` se recargan solos en el `initState` de
   su página, y `BannerBloc` al montarse la tirilla.
2. **Al entrar se recargan, y en orden.** `LoginResponse` **espera** (`await`) a que la sesión
   esté escrita antes de mandar los eventos de recarga, porque cada servicio lee el token y el
   `user_id` del almacenamiento. El guardado va directo por el `locator`, no por el BLoC: un
   evento de BLoC no se puede esperar.

**Si se añade un BLoC de datos a `blocProviders`, hay que vaciarlo en `cerrarSesionCompleta` y
recargarlo en `LoginResponse`.**

**No volver al `Future.delayed(500 ms)`.** Hasta el 2026-08-25 la recarga se lanzaba con un
temporizador a ojo, sin ninguna garantía de que la sesión nueva estuviera guardada. Cuando
`flutter_secure_storage` —que cifra contra el keystore— tardaba más que el temporizador, la
recarga leía una sesión que aún no existía, no emitía nada, y **la familia del usuario anterior
se quedaba en pantalla para siempre**, sin error ni aviso. Reproducido en el Oppo entrando con
`CATutorM974` y luego con `CATutorM820`.

Hay dos tests guardianes: `test/unit/no_reinstancia_myapp_test.dart` falla si alguien vuelve a
instanciar `MyApp` fuera de `lib/main.dart`, y
`test/unit/sesion_no_arrastra_usuario_anterior_test.dart` falla si vuelve el temporizador, si
se deja de esperar el guardado, o si aparece un BLoC de datos nuevo sin vaciar.

## Arquitectura

Clean Architecture con BLoC pattern:

```
lib/src/
├── core/           # Utilidades, constantes, extensiones
├── data/           # Repositorios, datasources, modelos
├── di/             # Inyección de dependencias (get_it + injectable)
├── domain/         # Entidades, casos de uso, interfaces
└── presentation/   # Páginas, widgets, BLoCs
```

## Dependencias principales

- **State management:** flutter_bloc
- **DI:** get_it + injectable
- **HTTP:** http
- **Storage local:** shared_preferences
- **Caché imágenes:** cached_network_image

### Dependencias bloqueadas — NO reintentar

**`flutter_secure_storage` se queda en la serie 10.x (`^10.1.0`).**

Comprobado el 2026-08-23: subir a **11.0.0 no compila** con el toolchain actual. El plugin
declara `compileSdk = 37` en su `android/build.gradle` y eso choca por partida doble:

1. Google ya **no publica la plataforma `android-37` a secas**. El repositorio solo ofrece
   `android-37.0`, `android-37.1` y las beta de `37.2`. AGP traduce el 37 entero al hash
   `android-37` y el build muere con *"Failed to find target with hash string 'android-37'"*.
2. Forzar `compileSdkMinor = 0` desde `android/build.gradle.kts` resuelve el hash pero destapa
   el bloqueo de fondo: **AGP 9.0.1 no soporta API 37**. El propio Gradle lo dice —
   *"Update this project's version of the Android Gradle plugin to one that supports 37"*.

Salir de ahí exigiría subir AGP a una versión que soporte API 37, otro salto mayor de toolchain
sobre el que ya está fijado (AGP 9.0.1 / Gradle 9.3.1 / KGP 2.3.20). No compensa: la 11.0.0 solo
quita APIs deprecadas que este proyecto **ya no usa** (`SecureStorage` está migrado a v10, sin
`encryptedSharedPreferences` ni `sharedPreferencesName`) y añade opciones biométricas que no se
usan aquí. Cero beneficio, riesgo de toolchain alto.

Reintentar solo cuando AGP estable soporte API 37 **y** el plugin declare la versión menor.

**`injectable_generator` se queda en 3.0.2** — no puede subir a 3.1.x porque el SDK fija
`test_api` en 0.7.11. No forzar con `dependency_overrides`.

## Reglas del código

- Busca la mejor manera de hacer tu trabajo sin consumir tantos tokens.
- Usa agentes y subagentes.
- Antes de implementar, asegúrate de planificar en modo plan y luego escribe.
- Todo en español (comentarios, commits, documentación)
- Widgets < 200 líneas
- No utilizar más de 3 niveles de anidación de widgets
- Los widgets deben ser finamente responsivos para Android e iOS
- Tests obligatorios para features nuevas
- Material Design 3
- Revisa que tengas todos los permisos necesarios tanto para iOS como para Android tanto de manera implícita como explícita
- Archivos bien comentados
- Guardar todo el progreso en ARJIPAGOS_PROGRESS.md — solo trabajo realizado dentro del proyecto arjipagos; nunca registrar cambios de otros proyectos (ArjiApp, backend, etc.)
- Guarda todo lo que ya esta aprobado y funcionando bien
- No borrar nada sin preguntar
- Asegúrate de que todos los widgets y pantallas estén bien optimizados para Android e iOS y en ambos temas, oscuros y claros
- Debes asegurarte de no romper nada y que se apegue estrictamente a las arquitecturas limpias y la inyección de dependencias
- Si tienes dudas, pregunta, antes de proceder
- Si tienes que crear un nuevo archivo, asegúrate de que esté bien comentado y que esté bien estructurado
- No Toast, no SnackBar — utiliza `AlertDialog` (con `showDialog`) para mostrar mensajes de éxito o error al usuario. Usar `dialogContext` del builder para `Navigator.pop` del dialog, y `context` externo solo para navegar fuera de la pantalla.
- Quita del git, todo aquello que no debe ir o que es peligroso que este en git. Me refiero al  
  remoto. Incluye la carpeta "otros".
- **En `otros/` va todo aquello que no debe subir al repo pero sí hay que conservar.** Es el
  almacén local: insumos en bruto, respaldos, material que ya no usa nadie, notas. Antes de
  borrar algo por no ensuciar el repositorio, moverlo ahí. Ver la sección "`otros/` — el
  almacén local".
- Revisa que no haya desperdicio de memoria o de espacio en disco. Sino que tengas un uso eficiente de los recursos. Y que no quede ningun tipo de basura. Por ejemplo, si vas a usar una variable, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar una función, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar una clase, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar un widget, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un evento, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un estado, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un repositorio, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un caso de uso, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un modelo, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar una entidad, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar una interfaz, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar un servicio, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar una utilidad, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar un archivo de configuración, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un archivo de prueba, asegúrate de que lo uses y no lo dejes ahí sin usar.
- Todos los strings hardcodeados en el código que deberían estar en AppStrings
- Nunca mostrar una excepción cruda al usuario. En los `catch` de los Services usar
  `Error(mensajeErrorRed(e))` (de `lib/src/core/utils/network_error_mapper.dart`), **nunca**
  `Error(e.toString())`. El detalle técnico va a `AppLogger`, no al `AlertDialog`. Hay un test
  guardián (`test/unit/services/services_no_filtran_excepciones_test.dart`) que falla si
  reaparece la fuga. Motivo: el 2026-08-13 un `HandshakeException` por cadena TLS incompleta
  llegó literal a la pantalla de login.
- La selección de pagos (Estados de Cuenta y Carrito) siempre se evalúa con ámbito de `ciclo_id`: el orden ascendente al seleccionar, el arrastre al deseleccionar y el poder quitar del carrito se aplican dentro de cada ciclo por separado. Los pagos de un ciclo nunca condicionan la selección de otro. La estructura de selección es `{cicloId: {alumnoId: [pagoId]}}` y se persiste vía `SeleccionPagosStorage`.
- No te metas al backend a menos que el usuario te lo pida.
- Revisa minuciosamente que en iOS y Android no tenga fallos o errores, que todo funcione  
  perfectamente bien, y que se vea en todas los distintos tamaños de pantallas tando de iOS como  
  de Android
- Para GIT solo del proyecto actual ArjiPagos, y solo de los archivos que tengan cambios. No  
  incluyas archivos de log, ni de editor, ni de version de sistema operativo, ni nada por el estilo.
- No me refiero a los archivos que estan en el .gitignore, sino a los archivos que no son  
  necesarios para el funcionamiento del proyecto. Por ejemplo: .claude, .idea, .vscode, etc.  
  Estos archivos solo me deben servir a mi para trabajar en el proyecto.
- Tambien cuando tengas que ejecutar algun comando en la consola, asegurate de que se  
  ejecute correctamente y que no haya ningun error.
