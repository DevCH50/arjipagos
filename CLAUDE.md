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

## Instrucciones para Release (Agente)

**Cuando el usuario diga:** "nueva versión", "release", "sube versión", "build release", "genera APK"

**Ejecutar estos comandos en paralelo:**

```bash
# 1. Build APK (en paralelo)
flutter build apk --release

# 2. Build App Bundle (en paralelo)
flutter build appbundle --release
```

**Después de los builds, instalar en dispositivo:**

```bash
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
en iPhone 17 Pro Max con iOS 26.6.1 el 2026-08-23:

| Mensaje | Qué es |
| --- | --- |
| `FIRMessaging ... will swizzle remote notification receiver handlers` | Firebase avisa de que intercepta los handlers de push. Silenciarlo con `FirebaseAppDelegateProxyEnabled = NO` obliga a implementarlos a mano: **no tocar**, rompería las notificaciones |
| `FlutterView implements focusItemsInRect:` | Log interno del engine de Flutter sobre UIKit |
| `Using the Impeller rendering backend (Metal)` | Informativo, y es buena señal |
| `empty dSYM file detected` en `objective_c` | Esperado: es un XCFramework precompilado sin debug info. Lo que exige App Store Connect es que el **UUID** del dSYM coincida con el del binario, y coincide (comprobar con `dwarfdump --uuid`) |
| `Unable to simultaneously satisfy constraints` con `_UIModernBarButton` / `_UIButtonBarButton` | Bug interno de UIKit en la barra del *share sheet* nativo. Todas las clases implicadas son de UIKit, ninguna del proyecto. UIKit se autorepara |
| `LaunchServices`, `canmaplsdatabase`, `sandbox extension`, `RBS`, `usermanagerd`, `WebContent`, `GPUProcessProxy IdleExit` | Ruido del sistema por permisos que una app normal no tiene |
| `Failed to request default share mode` / `error fetching item for URL` al abrir un PDF o ZIP | Ruido de LaunchServices al resolver el tipo de archivo desde `open_filex`. Los archivos abren bien |

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
app, así que al no recrearse `MyApp` conservan los datos del usuario anterior. `LoginResponse`
refresca al entrar `MenuPrincipalBloc`, `HomeBloc`, `EdoCtaListBloc`, `EdoCtaPagadosBloc` y
`FacturaBloc` —los que solo cargaban al crearse—. `CarritoBloc` y `NotificacionBloc` ya se
recargan en el `initState` de su página, y `BannerBloc` al montarse la tirilla. **Si se añade
un BLoC de datos a `blocProviders`, hay que refrescarlo ahí también.**

Hay test guardián: `test/unit/no_reinstancia_myapp_test.dart` falla si alguien vuelve a
instanciar `MyApp` fuera de `lib/main.dart`.

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
