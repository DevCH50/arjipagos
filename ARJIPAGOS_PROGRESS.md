# Arjipagos - Progreso del Proyecto

<!--
  Este archivo contiene todo el historial de desarrollo.
  Actualizar al final de cada sesión de trabajo.
-->

## Estado actual del proyecto

### En progreso

_(ninguno)_

### Pendiente

- Mejorar manejo de errores en WebView (timeout, sin conexión)
- Manejo automático de token expirado (refresh token o logout automático)
- **Verificación de número celular vía SMS (OTP):** el usuario escribe su número → backend envía SMS con código (Twilio/AWS SNS) → usuario ingresa OTP → backend confirma. Requiere endpoint en Laravel y pantalla de verificación en Flutter.

### Completado recientemente

- **`flutter pub upgrade` — paso 2, sin cambiar constraints (2026-07-30):**

  **Alcance real:** el `--dry-run` previo mostró que solo **1 dependencia** podía moverse dentro de los constraints actuales: `jni` **1.0.2 → 1.0.3** (patch, transitiva de `path_provider_android`). Único cambio en el repo: 2 líneas de `pubspec.lock` (versión + sha256). Era lo esperado tras el upgrade de 26 dependencias del 2026-07-29.

  **Lo que NO se tocó:** 19 paquetes tienen versiones nuevas **incompatibles con los constraints** y requerirían `--major-versions`, que no se ejecutó. Entre ellos `injectable_generator 3.1.1`, que sigue bloqueado por el SDK (fija `test_api 0.7.11`) — ver la nota de `819da44`. También quedan atrás `analyzer 14.1.0`, `package_config 3.0.0`, `record_use 1.0.0` y `lean_builder 1.2.0`.

  **Verificación:** `flutter analyze` limpio, **569 tests en verde**, APK (93.2 MB) y AAB (91.9 MB) recompilados sin errores. Como `jni` tiene componente nativo, no bastaba con compilar: se instaló en dispositivo y se comprobó que el proceso arranca y **sobrevive** (sin `FATAL` ni `AndroidRuntime` en logcat, sin errores de `path_provider`/`jni`).

  **iOS:** no afectado — `jni` llega vía `path_provider_android`, que es exclusivo de Android.

- **Selección de pagos con ámbito de `ciclo_id` (2026-07-29):**

  **Qué cambia:** las reglas de selección existentes (orden de ID ascendente al seleccionar, arrastre de los de ID mayor al deseleccionar, quitar del carrito solo el más alto) **no se modificaron**; ahora se evalúan **dentro de cada ciclo por separado**. Un pago del ciclo A ya no condiciona el orden de selección del ciclo B.

  **Punto de partida:** `EstadoDeCuenta` ya traía `cicloId` y `nivelId` del backend, pero no se usaban en ninguna parte. `nivelId` queda disponible y **no** participa del ámbito.

  **Estructura:** `pagosSeleccionados` pasó de `Map<int, List<int>>` a `Map<int, Map<int, List<int>>>` (`{cicloId: {alumnoId: [pagoId]}}`) en `EdoCtaListState` y `CarritoState`.

  **Bug de parseo corregido:** `cicloId: json['ciclo_id'] ?? 0` asignaba a un `int` no-nulable y `??` solo atrapa `null`. Si el backend mandaba `"2024"` (String) reventaba con `TypeError` y tumbaba el parseo del estado de cuenta completo. No era hipotético: `EstadosDeCuentaResponse.fromJson` hace `.toString()` sobre el ciclo, señal de que no llega tipado de forma confiable. Se añadió `_parseIntSeguro()` (acepta `int`, `num`, `String`, cae a 0) aplicado a `id`, `ciclo_id` y `nivel_id`.

  **Nuevo `SeleccionPagosStorage`** (`lib/src/data/dataSource/local/`): `EdoCtaListBloc` y `CarritoBloc` tenían **duplicada** la pareja `_cargar/_guardarPagosSeleccionados` y declaraban la clave de SharedPreferences dos veces. Se extrajo a un único datasource inyectado (registrado en `AppModule`). Incluye **migración transparente** del formato plano anterior (`{alumnoId: [pagoId]}`) agrupándolo bajo ciclo `0`, para que un carrito ya guardado no se pierda al actualizar la app.

  **Decisión de alcance:** totales, contador y **referencia de pago siguen agregando todos los ciclos** (comportamiento previo intacto). El ámbito por ciclo aplica a las reglas de orden, no al cobro. Si se quiere impedir cobrar ciclos mezclados en una misma referencia, es un cambio menor sobre este diseño.

  **UI:** solo cambió `pago_item.dart` (filtra `idsDisponibles` por ciclo). El resto de widgets consume getters cuya firma no se tocó, incluido `puedeEliminarPago(pagoId)`, que ahora deriva el ciclo del propio pago.

  **Fix de UI en el carrito (2 iteraciones):** el tooltip del botón de quitar deshabilitado (`carrito_pago_item.dart`) se renderizaba como una **cinta vertical ilegible** en el primer pago —el único con `puedeEliminar = false`—, porque el texto largo de `carritoQuitarOrden` quedaba aplastado contra el borde derecho del `trailing`. Se reemplazó el parámetro `tooltip:` del `IconButton` por un `Tooltip` explícito con `margin` y `preferBelow: false`.

  Al probar en dispositivo apareció un segundo síntoma con la misma causa raíz: el banner `RIGHT OVERFLOWED BY 0.853 PIXELS`. El `trailing` de un `ListTile` recibe un ancho **acotado**, así que importe + separador + `IconButton` (48 px) lo desbordaban por fracciones de pixel; el `softWrap: false` añadido en la primera iteración eliminó el corte carácter por carácter pero dejó al `Row` sin poder encoger, convirtiendo el problema en overflow. Se eliminó el `ListTile` y se maquetó con `Padding` + `Row` + `Expanded` (mismo patrón que `PagoItem`): el bloque derecho toma su **ancho intrínseco** y es la columna de texto la que cede espacio, por lo que el desbordamiento es imposible a cualquier ancho. La fecha de vencimiento pasó a `Flexible` + `ellipsis`. Cubierto por tests de overflow; **pendiente de reconfirmar en dispositivo.**

  **Verificación:** `flutter analyze` sin issues; **569 tests pasan** (532 → 569, +37 nuevos). Cubren: orden evaluado solo dentro del mismo ciclo, deseleccionar en un ciclo sin arrastrar el otro, `puedeEliminarPago` con máximo por ciclo, `totalSeleccionado` que ignora pagos registrados bajo el ciclo equivocado, migración del formato plano, parseo de `ciclo_id` como `int`/`String`/ausente y —nuevo `test/widgets/carrito/carrito_pago_item_test.dart` (9 tests)— ausencia de overflow a 320/360/375 px, con importe y descripción largos, con texto ampliado a 1.5× por accesibilidad y en tema oscuro.

  **Build de release 1.0.22+31 (2026-07-30):** `flutter analyze` limpio, 569 tests en verde, `ApiConfig.isProduction = true` y permiso INTERNET verificados. APK (93.2 MB) y AAB (91.9 MB) generados sin errores. **Versión sin cambios** por regla de versionado #2: 1.0.22+31 sigue pendiente de publicar.

  **Limitación de la verificación:** el entorno de desarrollo es **Linux**, por lo que iOS no se pudo compilar ni verificar en dispositivo. El cambio es de capa Flutter (widgets) y no toca `ios/`, pero el Archive de iOS queda pendiente de hacerse desde la Mac siguiendo el checklist de `CLAUDE.md`.

  **Captura de depuración:** se añadió `assets/errores/` al `.gitignore` (no está declarada en `pubspec.yaml`, así que nunca viajó en el bundle; ahora tampoco entra al repo).

  **Regla añadida a CLAUDE.md** en `## Reglas del código`.

- **Actualización de Flutter 3.44.8 y dependencias — paso 1, sin cambios de constraints (2026-07-29):**

  **Verificación previa (antes de tocar nada):** baseline capturado con **532 tests en verde**, `flutter analyze` sin issues, working tree limpio en `1ae4755` y `pubspec.lock` versionado (revertir es un `git checkout`). Se revisó el `--dry-run` y los changelogs de los cambios no-patch antes de ejecutar.

  **Riesgos evaluados y descartados:**
  - `firebase_core_platform_interface` 7.1.0 → **8.0.0** (major transitivo): bump de fachada por regeneración de pigeon, igual que el 7.0.0. El código no importa el platform interface en ningún archivo; solo usa `Firebase.initializeApp()` y `FirebaseMessaging.instance`. Sin impacto.
  - `flutter_local_notifications` 22.0.1 → **22.2.0**: 22.1.0 y 22.2.0 son puramente aditivas (`showBigPictureWhenCollapsed`, `dismissIsolate` opt-in, fix del manifest SPM iOS 11→13). Los breaking changes fueron en 20.0.0. `FcmService.dart` no se ve afectado.
  - `objective_c` 9.4.1 → **9.5.0**: el fix de dSYM del `Podfile` matchea por nombre de target y por rutas de build, no por versión. Sigue válido.
  - `jni_util` 1.0.0 (nuevo transitivo): no se invoca desde el código.
  - `webview_flutter` (único `platform_interface` que sí se importa, en un test) no cambió.

  **Flutter SDK:** 3.44.5 → **3.44.8** (stable, Dart 3.12.2). El `flutter upgrade` falló primero por cambios locales en el checkout del SDK (`/home/carlos/snap/flutter/common/flutter`): era una sola línea autogenerada del `pubspec.lock` **del propio SDK** (`objective_c` 9.2.3 → 9.3.0), no una edición manual. Se respaldó y descartó antes de reintentar. `flutter doctor` sin issues.

  **Dependencias:** `flutter pub upgrade` (sin `--major-versions`) → **26 paquetes actualizados**, `pubspec.yaml` intacto. Directas: `firebase_core` 4.12.1, `firebase_messaging` 16.4.3, `flutter_local_notifications` 22.2.0, `google_fonts` 8.2.0, `package_info_plus` 10.2.1, `share_plus` 13.3.0.

  **Resultado:** `flutter analyze` sin issues; **532 tests pasan** (idéntico al baseline, cero regresiones); `flutter build apk --release` OK (93.2 MB, mismo tamaño que el release anterior). Único archivo modificado en el repo: `pubspec.lock`.

  **Pendiente de este trabajo:** verificación iOS (`pod install` + Archive) no se pudo hacer desde Linux — requiere la Mac.

- **`injectable_generator` 3.1.x: BLOQUEADO por el SDK — no reintentar (2026-07-29):**

  Se investigó subir `injectable_generator` de 3.0.2 a 3.1.1 y **no es posible**. No es un problema de constraints del proyecto: `injectable_generator: ^3.0.2` ya permite la 3.1.1, pero el solver la rechaza. La 3.1.0 falla igual, así que **toda la línea 3.1.x es inalcanzable**; el techo real es 3.0.2.

  **Cadena del conflicto:**
  - `injectable_generator >=3.1.0` → `lean_builder ^1.2.0` → `analyzer ^13.0.0`
  - El único `test` que admite `analyzer 13` es `test >=1.31.2`, que exige `test_api 0.7.13`
  - Pero `flutter_test` del SDK **fija** `test_api` en **0.7.11** (y `matcher` en 0.12.19) — pin duro, no negociable desde el pubspec
  - `bloc_test ^10.0.0` es quien arrastra `test` (lo usan **14 archivos** de `test/`)

  **Descartado deliberadamente:** quitar `bloc_test` (rompe 14 archivos de test) y meter `dependency_overrides` sobre `test_api`/`matcher` para saltarse el pin del SDK (rompe la suite en runtime). No vale la pena por un generador de código.

  **Cuándo reintentar:** cuando salga una versión de Flutter cuyo `flutter_test` fije `test_api` en 0.7.13 o superior. Verificarlo con `dart pub add 'dev:injectable_generator:^3.1.1' --dry-run` — si resuelve, ya se puede. Mientras tanto, `build_runner` 2.15.3 y `analyzer` 14 quedan bloqueados por la misma cadena.

- **Verificación integral + build de release Android 1.0.22+31 (2026-07-10):**

  **Verificación:** `flutter analyze` sin issues; **532 tests pasan** (`flutter test`, todo verde). `flutter pub get` sincronizado. Precondiciones de producción confirmadas: `ApiConfig.isProduction = true` y permiso `INTERNET` en `AndroidManifest.xml`.

  **Versión:** se mantiene **1.0.22+31** (pendiente de publicar; no se incrementa por regla de versionado #2).

  **Builds Android:** `app-release.apk` (93.2 MB) y `app-release.aab` (91.8 MB) generados sin errores. No se instaló en dispositivo (ninguno conectado por ADB).

  **Nota deps:** 15 paquetes con versiones nuevas pero con constraints incompatibles; NO se actualizan sin autorización para no romper el entorno.

- **Fix build iOS (Swift Package Manager + Firebase) y release 1.0.22+31 (2026-07-10):**

  **Contexto:** tras actualizar a Flutter 3.44.6, el proyecto quedó usando Swift Package Manager (Firebase migró de CocoaPods a SPM; `Podfile.lock` solo tiene `Flutter`). Esto introdujo varios fallos al compilar/archivar. Todo resuelto y **Archive validado OK** en App Store Connect.

  **Problemas resueltos y blindajes permanentes (en `ios/Podfile` `post_install`):**
  - **Firebase exige iOS 15.0 pero el SPM generado quedaba en 13.0:** Flutter regenera `FlutterGeneratedPluginSwiftPackage/Package.swift` con `.iOS("13.0")` en cada `pub get`/`clean`, y su corrección nativa (`updateMinimumDeployment`) solo aplica en `flutter build ios` CLI, no al compilar desde Xcode. **Fix:** el `post_install` fuerza `.iOS("15.0")` en cada `pod install` (que corre en el flujo manual y en todo `flutter build`).
  - **`LastUpgradeCheck`/`LastUpgradeVersion` se degradaban a 1510:** el `post_install` los restaura a **2630** en cada `pod install` (corre después de la degradación de Flutter). Ya no requiere pasos manuales.
  - **No aparecía el simulador como destino:** las configs `Release`/`Profile` tienen `SUPPORTED_PLATFORMS = iphoneos` (correcto para archives de dispositivo). Se decidió flujo **solo-dispositivo** (los simuladores consumen mucho espacio): `LaunchAction` (botón Run) = **Release** → instala build AOT autónomo en el iPhone que sobrevive cerrar/reabrir. Un build Debug en dispositivo físico es tethered-only y crashea al reabrirlo suelto. `ArchiveAction` sigue en Release.
  - Se corrigió el malentendido en CLAUDE.md (la `LaunchAction` no controla el Archive; eso es la `ArchiveAction`).

  **Limpieza de espacio (~56 GB liberados):** iOS DeviceSupport (33 GB), `.gradle/caches` (6.8 GB), DerivedData (5.3 GB), `build/` (12 GB). Además se eliminaron carpetas huérfanas de Firebase en `ios/Pods/` (basura pre-SPM: 69 MB → 8.4 MB).

  **Versión:** subida a **1.0.22+31** (App Store rechazó 1.0.21 porque ya está aprobada/cerrada). `aps-environment = production`, `isProduction = true`, bundle `com.example.arjipagos` — todo verificado antes del Archive.

  **Verificación:** `xcodebuild` de simulador (`BUILD SUCCEEDED`) y `flutter build ios --release` (`Built Runner.app 55.3MB`) sin errores; Archive validado en App Store Connect (falta el Upload final, pendiente para mañana).

- **Bundle ID de iOS: intento de migración a `mx.moriah` y REVERSIÓN a `com.example` (2026-07-09):**

  **Resultado final:** iOS se queda en **`com.example.arjipagos`** (NO se migra). Android sigue en `mx.moriah.arjipagos`. Las dos plataformas con bundle distinto, a propósito.

  **Qué pasó:** se cambió por error el bundle de iOS a `mx.moriah.arjipagos` (commit `17974cd`) creyendo que Apple rechazaría `com.example.*`. Al intentar el Archive salió *App Record Creation Error* (SKU/App Name en uso). Se descubrió que **la app iOS YA está publicada en el App Store con `com.example.arjipagos`** (versiones 1.0.1–1.0.20 live, 1.0.21 es la siguiente). El bundle ID de un registro de App Store es **permanente**: cambiarlo crearía una app nueva y dejaría huérfana la existente (usuarios, reseñas). Por eso se **revirtió**.

  **Reversión aplicada:**
  - `project.pbxproj`: 6 referencias `PRODUCT_BUNDLE_IDENTIFIER` de vuelta a `com.example.arjipagos` / `.RunnerTests`.
  - `GoogleService-Info.plist`: restaurado el de **com.example** (`GOOGLE_APP_ID` `...ios:0dd1bf...7a337b`), re-descargado de Firebase (la app iOS com.example sigue existiendo en el proyecto). La app iOS `mx.moriah` registrada en Firebase queda inerte, sin usarse.
  - Eliminados duplicados basura de plists (`_viejito`, ` 2`, `_2`).

  **Verificación final (todo OK):**
  - `.app` compilado: `CFBundleIdentifier` = `com.example.arjipagos`, plist empaquetado idéntico, `1.0.21 (30)`.
  - Runtime confirmado: app instalada y corriendo en iPhone 17, FCM inicializado (log swizzling `I-FCM001000`, normal).
  - Coherencia Firebase: Android e iOS en el mismo proyecto (`arjipagos`, sender `359262554914`), cada uno con su `GOOGLE_APP_ID`.
  - `flutter analyze` sin issues; **532/532 tests**; config crítica iOS intacta (`LastUpgradeCheck`/`Version` = 2630).

  **Se conserva del intento (mejora válida):**
  - `.gitignore`: comodines `ios/Runner/GoogleService-Info*.plist` y `android/app/google-services*.json` para blindar duplicados/respaldos (evita subir API keys).
  - `pubspec.yaml`: **1.0.21+29 → 1.0.21+30** (el build 29 ya se había usado en el registro).

  **Lección:** antes de proponer cambiar un bundle/applicationId, verificar si la app ya está publicada en la tienda con ese identificador. Un identificador ya publicado es fijo e intocable.

  **Notas de build conocidas (no bloqueantes):**
  - Crash `PathNotFoundException` en `build/ios/Release-iphoneos` tras `flutter clean` → bug de la herramienta; se esquiva con `mkdir -p` y reintento.
  - Warnings *"Stale file … outside allowed root paths"* al archivar → artefactos viejos en `build/ios`; se resuelven borrando esa carpeta + Clean Build Folder.
  - `Missing package product 'FlutterGeneratedPluginSwiftPackage'` al correr en dispositivo → caché SPM de Xcode; se resuelve con File → Packages → Reset Package Caches (el paquete en disco está OK).

- **Actualización de Flutter/Dart y verificación cross-platform (2026-07-09):**

  **Actualización del toolchain:**
  - Flutter `3.44.1` → **`3.44.6`** (`flutter upgrade`); Dart `3.12.1` → **`3.12.2`**.
  - Antes de actualizar hubo que descartar un `pubspec.lock` modificado dentro del checkout del SDK de Flutter (`~/develop/flutter`), no del proyecto.
  - `flutter doctor` sin problemas.

  **Dependencias del proyecto:**
  - `flutter pub upgrade --major-versions` → `No dependencies changed`. Las dependencias directas ya estaban en su última versión mayor resoluble.
  - `flutter pub outdated` → **directas: todas al día**. Los ~15 paquetes "outdated" restantes son transitivos fijados por el propio SDK de Flutter y su tooling (`matcher`, `meta`, `vector_math`, `test_api`, `injectable_generator`, `analyzer`, etc.); subirlos exigiría *major bumps* incompatibles → no se tocaron.
  - `pubspec.yaml` y `pubspec.lock` quedaron **sin cambios**.

  **Verificación minuciosa en ambas plataformas (todo OK):**
  - `flutter analyze` → **sin issues**.
  - `flutter test` → **532/532 pasan**.
  - **Android:** `flutter build apk --release` → `app-release.apk` (93.2 MB) ✅.
  - **iOS:** secuencia obligatoria (`flutter clean` → `pub get` → `pod install` → `./scripts/build_ios.sh`) → `Runner.app` (59.9 MB) ✅. El script restauró `LastUpgradeCheck`/`LastUpgradeVersion` a **2630**.
    - Nota: el primer intento de build iOS crasheó con `PathNotFoundException` sobre `build/ios/Release-iphoneos` (bug conocido de la herramienta Flutter tras `flutter clean`, no del código). Se resolvió creando el directorio y reintentando; compiló limpio.

  **Cambios versionados y pusheados a `main`:**
  - `ios/Runner.xcodeproj/.../swiftpm/Package.resolved` (commit `a7b2dc3`) y `ios/Runner.xcworkspace/.../swiftpm/Package.resolved` (commit `3a1b7c5`): Swift PM alineó los pins de Firebase iOS que trajo el nuevo Flutter — firebase-ios-sdk **12.15.0**, app-check **11.3.1**, GoogleUtilities **8.1.2**, promises **2.4.1**, nanopb **2.30910.1**, GoogleAppMeasurement **12.15.0**.
  - Se eliminaron 4 `flutter_*.log` (reportes de crash, basura local ya gitignoreada) para no dejar residuos.
  - Sin cambio de versión de la app (sigue **1.0.21+29**, pendiente de publicar).

- **Fix edge-to-edge para Android 15 / SDK 35 (2026-07-09):**

  **Motivo:** Google Play mostró la acción recomendada _"Es posible que la vista de extremo a extremo no funcione para todos los usuarios"_ al subir la versión `28 (1.0.20)`. A partir de Android 15, las apps orientadas al SDK 35 se dibujan de extremo a extremo por defecto y deben gestionar los insets de las barras de sistema.

  **Cambios aplicados:**
  - `lib/main.dart`: se agregó `await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` — equivalente a `enableEdgeToEdge()` nativo; declara el modo borde-a-borde y elimina la advertencia de Play Store.
  - `android/app/src/main/res/values/styles.xml` y `values-night/styles.xml`: se removió `android:windowFullscreen=true` de `LaunchTheme` (fullscreen deprecado en SDK 35 e incompatible con el manejo de insets edge-to-edge). Se conservan `windowDrawsSystemBarBackgrounds` y `windowLayoutInDisplayCutoutMode=shortEdges`.

  **Verificación de insets (sin cambios necesarios, ya correctos):**
  - Barras inferiores fijas (`CarritoTotalBar`, `TotalSeleccionadoBar`): montadas como `bottomNavigationBar` con `SafeArea` interno dentro del `Container` de color → pintan detrás de la barra de navegación y el contenido queda por encima.
  - Pantallas con AppBar: el `Scaffold` maneja el inset superior automáticamente.
  - Pantallas sin AppBar: `SafeArea` en Login y Register (con fondo full-bleed detrás vía `Positioned.fill`/`BackgroundImage`); Splash es full-bleed intencional (logo centrado).

  **Validación:** `flutter analyze lib/main.dart` sin issues. `flutter test` → **532 tests pasando**. Los cambios en XML no afectan el análisis. Los 532 tests son agnósticos de plataforma (aplican a iOS y Android); el archive nativo de iOS requiere macOS + Xcode.

  **Builds release regenerados con el fix (versión 1.0.21+29, sin cambio de versión por seguir pendiente de publicar):**
  - APK: `build/app/outputs/flutter-apk/app-release.apk` (93.2 MB)
  - AAB: `build/app/outputs/bundle/release/app-release.aab` (91.8 MB) — para Play Store
  - Prerrequisitos verificados: `ApiConfig.isProduction = true` y permiso `INTERNET` en AndroidManifest.

  **Verificación en dispositivo real (Oppo CPH2639, Android 16, navegación por gestos — 2026-07-09):** probado vía `adb screencap` en las dos pantallas con barra inferior fija (peor escenario para edge-to-edge). Resultado OK en ambas:
  - **Carrito** y **Estados de Cuenta**: barra de estado limpia y AppBar correctamente debajo (inset superior OK); barras inferiores fijas (Pagar / Continuar) completas, tocables y con margen respecto a la barra de gestos (inset inferior OK vía `SafeArea`).
  - Cero contenido tapado, cero botones recortados o pegados a la línea de gestos. Fix confirmado en runtime.

- **Release 1.0.21+29 — verificación, bump, build e instalación (2026-07-09):**

  **Verificación previa (todo OK):**
  - `flutter analyze` → sin issues. `flutter test` → **532 tests pasando**.
  - Flutter 3.44.5 / Dart 3.12.2. Árbol de trabajo limpio.
  - Dependencias directas ya al día; los paquetes "outdated" son transitivos/dev en sus *newest resolvable versions* (subir a `Latest` exigiría *major bumps* incompatibles → no se tocaron).

  **Cambios versionados y pusheados a `main`:**
  - `CLAUDE.md`: simplificada regla de agentes (commit `bf2ecab`).
  - `pubspec.yaml`: `1.0.20+28` → **`1.0.21+29`** (commit `f7616e1`).

  **Builds release generados (versión 1.0.21+29):**
  - APK: `build/app/outputs/flutter-apk/app-release.apk` (93.2 MB)
  - AAB: `build/app/outputs/bundle/release/app-release.aab` (91.8 MB) — para Play Store
  - Prerrequisitos verificados antes de compilar: `ApiConfig.isProduction = true` y permiso `INTERNET` en AndroidManifest.

  **Instalación en dispositivo:** falló con `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (firma distinta a la app instalada). Se resolvió con `adb uninstall mx.moriah.arjipagos` + `adb install` (instalación limpia, sin sesión previa).

  **Verificación en runtime del login (build debug en dispositivo, 2026-07-09):** flujo end-to-end contra producción sin un solo error.
  - `POST /api/v1/login` → **200** (~1.3 s), `[Auth] Login exitoso`.
  - Cascada post-login toda **200**: `POST /dispositivo/registrar` (Token FCM registrado), `POST /alumno/estado-de-cuenta-sin-pagar/` (alumnos cargados), `GET /notificaciones/no-leidas`, `GET /notificaciones?page=1` (20 elementos).
  - Cero respuestas 4xx/5xx, cero excepciones, cero timeouts.
  - Confirmado: el `Logger` emite trazas `[NETWORK]/[Auth]/[FCM]/[EdoCta]` en debug y queda silenciado en release (comportamiento correcto). Para ver la petición de login hay que usar `flutter run` en debug, no `--release`.
  - Nota operativa: instalar debug sobre release (o viceversa) falla por firma → hay que `adb uninstall mx.moriah.arjipagos` antes.

  **Nota iOS:** los 532 tests son agnósticos de plataforma y pasan; el build/archive nativo de iOS requiere macOS + Xcode (`./scripts/build_ios.sh`), no compilable desde este entorno Linux.

- **Cobertura de tests para blindar upgrades de riesgo (2026-07-08):** +120 tests nuevos (412 → 532), `flutter analyze` sin issues.

  **Hallazgo clave:** los Services usan funciones top-level `http.post(...)` sin inyectar `http.Client`. Se testean con `http.runWithClient(body, () => MockClient(...))` — intercepta el cliente vía Zone **sin tocar código de producción**.

  **Nuevos archivos de test:**
  - Services HTTP (`test/unit/services/`): Auth, Pago, Home, EdoCta, Factura, Notificacion, FCM (parte REST). Cubren parsing, status codes, sesión y errores Timeout/Socket.
  - Storage (`test/unit/local/`): SharedPref (mock oficial `setMockInitialValues`) y SecureStorage (mock del MethodChannel en memoria).
  - BLoCs faltantes (`test/unit/blocs/`): Factura, CambiarContrasena, Register, Splash.
  - Widget HTML: `notificacion_detalle_widget_test.dart` (blinda `flutter_widget_from_html_core`/`xml` + despacho de MarcarLeidaEvent con MockBloc).
  - Pago/WebView: `pago_response_handler_test.dart` (lógica pura de éxito/fallo de pago).
  - Helper: `test/helpers/mocks.dart` extendido con `MockGetFacturasUseCase` + `createMockFacturaUseCases`.

  **Límites documentados (NO cubribles por unit test):** parte nativa de `flutter_local_notifications` (`initialize`/`show`/canales), keychain/keystore de `flutter_secure_storage`, y platform view de `webview_flutter` (`WebViewController` no monta en `flutter test`). Su cobertura real es el build + smoke en dispositivo; la API de webview la cubre `flutter analyze` en compilación.

- **Actualización de SDK y dependencias seguras (2026-07-08):**

  **Cambios:**
  - Flutter SDK: `3.44.0` → `3.44.5` (stable, `flutter upgrade`). Dart 3.12.0.
  - `flutter pub upgrade` — 24 dependencias actualizadas dentro de constraints (minor/patch): `equatable`, `firebase_core`, `firebase_messaging`, `package_info_plus`, `path_provider`, `share_plus`, `webview_flutter`, `build_runner`, `timezone`, `sqflite_common`, entre otras.
  - DI regenerado con `build_runner`.

  **Verificación:** `flutter analyze` → sin issues · `flutter test` → 412 tests pasan.

  **Evaluados y aplicados los saltos MAYORES (mismo día, tras verificación en worktree aislado):**
  - `flutter_local_notifications` 21 → **22.0.1** (constraint en `pubspec.yaml`: `^21.0.0` → `^22.0.1`). Verificado: `flutter analyze` limpio, 412 tests pasan, **build APK debug nativo Android exitoso**. El código de `FcmService` ya usaba la API de parámetros nombrados compatible con v22 (comentario actualizado a v22). Sin cambios de código necesarios.
  - `xml` 6 → **7.0.1** (transitivo, sin uso directo). `image` 4.8 → 4.9.1 (transitivo).
  - **Pendiente de verificar en Mac antes del próximo release iOS:** Archive de FLN 22 en iOS (no verificable en Linux; API Dart idéntica, riesgo bajo).

  **NO subibles (bloqueados por constraints de otros paquetes/SDK, requieren forzar):** `flutter_secure_storage_darwin`→0.4.0, `injectable_generator`→3.1.0, `package_config`→3.0.0, `analyzer`→14. Se dejan como están.

- **Fix: referencia con cero final para pago único — v1.0.19+26 (2026-05-08):**

  **Cambio:**
  - Cuando solo hay un ID en la referencia, se añade `sep + "0"` al final: `3399I0` (iOS) / `3399A0` (Android).
  - Aplica únicamente para un solo item; múltiples IDs siguen usando el separador entre ellos sin cambio.
  - Implementado en `AppConstants.generarReferencia`.

  **Verificación completa:**
  - `flutter analyze` → **No issues found**
  - `flutter test` → **412/412 tests pasan**
  - Nuevos tests en `test/unit/core/app_constants_test.dart` (6 casos: Android e iOS, item único e ID largo, múltiples IDs).
  - Comentarios obsoletos actualizados en `carrito_referencia_test.dart` y `edo_cta_referencia_test.dart`.

  **Archivos modificados:**
  - `lib/src/core/constants/app_constants.dart`
  - `test/unit/core/app_constants_test.dart` _(nuevo)_
  - `test/unit/blocs/carrito_referencia_test.dart`
  - `test/unit/blocs/edo_cta_referencia_test.dart`
  - `pubspec.yaml` → `1.0.19+26`

- **Refactor: separador de referencia de pago por plataforma — v1.0.18+25 (2026-05-07):**

  **Cambio:**
  - El separador entre IDs de estados de cuenta era `'D'` fijo. Ahora es `'I'` en iOS y `'A'` en Android.
  - Fuente única: `AppConstants.generarReferencia(List<int> ids)` — único lugar donde vive el separador.
  - `PagoRequest.generarReferencia`, `CarritoState.referenciaPago` y `EdoCtaListBloc` delegan a `AppConstants`.

  **Verificación completa:**
  - `flutter analyze` → **No issues found**
  - `flutter test` → **406/406 tests pasan**
  - Test `carrito_bloc_test.dart` actualizado: usa `AppConstants.generarReferencia` como valor esperado (compatible con cualquier plataforma).

  **Archivos modificados:**
  - `lib/src/core/constants/app_constants.dart` — fuente única + constantes `_sepIOS`/`_sepAndroid`
  - `lib/src/domain/models/PagoRequest.dart` — delega a `AppConstants`
  - `lib/src/presentation/pages/carrito/bloc/CarritoState.dart` — delega a `AppConstants`
  - `lib/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart` — delega a `AppConstants`
  - `test/unit/blocs/carrito_bloc_test.dart` — aserción actualizada

- **Mantenimiento y actualización de dependencias — v1.0.15+22 (2026-04-28):**

  **Verificación completa:**
  - `flutter analyze` → **No issues found**
  - `flutter test` → **385/385 tests pasan**

  **Dependencias actualizadas (minor/patch, sin major-version bumps):**
  - `build` 4.0.5 → 4.0.6
  - `build_runner` 2.14.0 → 2.14.1
  - `vm_service` 15.1.0 → 15.2.0
  - Código generado (injectable) regenerado con `build_runner build`

  **Builds release generados:**
  - APK: `build/app/outputs/flutter-apk/app-release.apk` (92.5 MB) ✓
  - AAB: `build/app/outputs/bundle/release/app-release.aab` (80.5 MB) ✓

  **Flutter SDK:** 3.41.6 • Dart 3.11.4 (estable, sin actualizaciones pendientes de SDK)

  **Nota:** 37 paquetes tienen versiones major disponibles (firebase, flutter_local_notifications, injectable, etc.) — pendientes de evaluación de breaking changes antes de actualizar.

- **Íconos y sonido en notificaciones push — v1.0.11+17 (2026-04-17):**

  **Android:**
  - `drawable/ic_notification.xml` — ícono monocromático (campana blanca) para la barra de estado. Android 5+ requiere que sea blanco/transparente.
  - `AndroidManifest.xml` — `meta-data` `default_notification_icon` apunta a `@drawable/ic_notification` y `default_notification_color` a `#1565C0`.
  - `values/colors.xml` — color `notification_color` (#1565C0, azul corporativo Arji).
  - `FcmService.dart` — canal `arjipagos_notif` y `AndroidNotificationDetails` actualizados: ícono `@drawable/ic_notification` + sonido `notif_sound` desde `res/raw/`.
  - `res/raw/notif_sound.wav` — archivo de sonido personalizado para notificaciones.

  **iOS:**
  - `ios/Runner/notif_sound.wav` — archivo de sonido personalizado en el bundle de la app.

  **Backend (ArjiApp Laravel):**
  - `PushNotificationService.php` — `CloudMessage` enriquecido con `AndroidConfig::new()->withSound('notif_sound')` y `ApnsConfig::new()->withSound('notif_sound.wav')`.
  - Imports añadidos: `AndroidConfig`, `ApnsConfig` del SDK Kreait.

  **Debug:**
  - `EdoCtaListBloc.dart` — `AppLogger.warning` cuando se alcanza el tope máximo de referencia; muestra cadena exacta, longitud y límite.
  - `CarritoBloc.dart` — `debugPrint` en los dos puntos donde se valida `referenciaValida`.

  **Verificación:**
  - `flutter analyze` → **No issues found**
  - `flutter test` → **385/385 tests pasan**
  - APK release: `build/app/outputs/flutter-apk/app-release.apk` (92.4 MB) ✓
  - AAB release: `build/app/outputs/bundle/release/app-release.aab` (80.5 MB) ✓

- **Verificación completa del proyecto (2026-04-16):**
  - `flutter analyze` → **No issues found**
  - `flutter test` → **385/385 tests pasan**
  - Revisión exhaustiva de todos los archivos modificados: FcmService, NotificacionService, NotificacionBloc, NotificacionItemWidget, CarritoBloc, CarritoState, EdoCtaListBloc, UserDrawer, DrawerFooter, AndroidManifest, AppDelegate.swift, Info.plist, main.dart, endpoints.dart, app_strings.dart
  - Archivos nuevos verificados: `app_constants.dart`, `app_urls.dart`, `html_utils.dart`, `AvisoDePrivacidadPage`
  - Tests de widgets e unitarios (html_utils, carrito_referencia, edo_cta_referencia) todos pasan

- **Fix notificaciones push + Aviso de Privacidad (2026-04-16):**

  **Aviso de Privacidad:**
  - `AvisoDePrivacidadPage.dart` — nueva página WebView con botón refresh, indicador de carga y manejo de error.
  - `app_urls.dart` (nuevo en `core/constants/`) — URL del aviso de privacidad. Arquitectura limpia: presentación usa `core`, no `data/api`.
  - `Endpoints.avisodePrivacidad` eliminado de `endpoints.dart` (era violación CA).
  - `user_drawer.dart` — ListTile "Aviso de Privacidad" entre Cambiar Contraseña y Cerrar Sesión; cierra el Drawer antes de navegar.
  - `drawer_footer.dart` — eliminado el link y dependencia `url_launcher`; queda solo versión y texto de copia.
  - `main.dart` — ruta `'aviso_de_privacidad'` registrada.

  **Notificaciones Push — correcciones:**
  - `FcmService.dart`:
    - Canal Android creado con `Importance.high` para mostrar banners (heads-up).
    - `_handleBackgroundMessage` ahora prioriza `data.title`/`data.message` sobre `notification`.
    - Solo muestra notificación local si `message.notification == null` (evita duplicados en Android).
    - `Accept: application/json` añadido a todos los headers HTTP.
  - `NotificacionBloc.dart` — foreground handler prioriza campos `data`, ignora título genérico `'ArjiPagos'`.
  - `html_utils.dart` (nuevo en `core/utils/`) — función `stripHtml()` centralizada con soporte completo de entidades HTML incluyendo español (`&iacute;`, `&aacute;`, etc.), entidades numéricas hex/decimal.
  - `notificacion_item_widget.dart` — eliminada `_stripHtml` duplicada; usa la centralizada de `html_utils.dart`.
  - `NotificacionService.dart` — `Accept: application/json` añadido a `_buildHeaders`.
  - `AndroidManifest.xml` — `meta-data` con canal FCM por defecto (`arjipagos_notif`).
  - `Info.plist` — removido `FirebaseAppDelegateProxyEnabled` (re-habilita swizzling FCM en iOS).
  - `AppDelegate.swift` — simplificado, sin overrides manuales de APNs.
  - `AppStrings` — strings para canal FCM y página Aviso de Privacidad.

  **Backend Laravel (ArjiApp) — correcciones:**
  - `PushNotificationService.php`:
    - Título `'ArjiPagos'` cambiado a `'Estado de Cuenta Vencido'` en `notificarVencido()`.
    - `data` payload ahora incluye `title` y `message` (texto plano) para que Flutter los lea directamente.
    - `strip_tags` reemplazado por `html_entity_decode(strip_tags(...))` — evita `&iacute;` literal en el banner.
  - `migrations/2026_04_16_000001_fix_mobile_type_default_usermobile.php` — elimina `DEFAULT 'android'` del campo `mobile_type`.

- **Release 1.0.10+16 (2026-04-15):**
  - Actualización de dependencias: `badges 3.1.2 → 3.2.0`, `mocktail 1.0.4 → 1.0.5`, `vm_service 15.0.2 → 15.1.0`.
  - `injection.config.dart` regenerado tras upgrade.

- **Fix: evitar regreso al Login al presionar back desde Menu Principal (2026-04-15):**
  - `LoginResponse.dart` — cambia `pushNamed` por `pushNamedAndRemoveUntil` al navegar a `menu_principal`, limpiando el stack de navegación completo.

- **Refactor: DrawerFooter extraído a su propio archivo (2026-04-15):**
  - Nuevo widget `drawer_footer.dart` con el pie del Drawer.
  - `user_drawer.dart` reducido drásticamente (sin el footer inline).
  - `widgets.dart` actualizado con el export.

- **Release 1.0.9+15 — Aviso de Privacidad y versión en Drawer (2026-04-15):**
  - Nuevo endpoint `Endpoints.avisoDePrivacidad` con URL del aviso.
  - Dependencias añadidas: `url_launcher` y `package_info_plus`.
  - `DrawerFooter`: enlace al Aviso de Privacidad, versión real de la app con etiqueta de plataforma (Android/iOS) y hint de copia.
  - `AndroidManifest.xml`: query `https` para `url_launcher` en Android 11+.
  - `AppStrings`: nuevos strings para el pie del drawer.

- **Release 1.0.8+14 (2026-04-14):**
  - Página de Facturas completa con compartir ZIP por URL.
  - `device_type` enviado en login (`'ios'` / `'android'`).
  - Renombrado `EstatodosDeCuentaResponse` → `EstadosDeCuentaResponse` (typo corregido en 7 archivos lib + 3 tests).
  - `FacturaResponse` corregido: eliminado `dart:ffi`, `Bool` → `bool`, comillas simples.
  - **313/313 tests pasan, 0 errores de análisis estático.**

- **Página de Facturas (2026-04-14):**
  - Endpoint: `POST /facturas/list` con `user_id` en body.
  - Arquitectura completa Clean Architecture + BLoC:
    - Dominio: `FacturaRepository`, `GetFacturasUseCase`, `FacturaUseCases`
    - Datos: `FacturaService`, `FacturaRepositoryImpl`
    - Presentación: `FacturaBloc` (Event/State), `FacturasPage`, 4 widgets (`FacturaItemWidget`, loading, empty, error)
  - Compartir ZIP: decodificación base64 **lazy** (solo al presionar compartir), guardado en directorio temporal, compartido con `SharePlus.instance.share()`.
  - Nuevas dependencias: `share_plus ^12.0.2`, `path_provider ^2.1.5`.
  - Nuevos strings en `AppStrings` (sección FACTURAS).
  - Ruta `'facturas'` registrada en `main.dart`; menú principal navega directamente sin diálogo "próximamente".
  - DI (`AppModule.dart`) y `blocProvider.dart` actualizados; `injection.config.dart` regenerado.
  - **0 errores de análisis estático en todos los archivos nuevos.**



- **Centralización de strings en AppStrings (2026-04-12):**
  - Migrados todos los strings hardcodeados de la UI a `AppStrings` (18 archivos actualizados).
  - Nuevas constantes agregadas: validaciones de cambio de contraseña, textos del drawer, splash, pago, menú principal, errores, tooltips y chips.
  - `resumenAlumnos` en `MenuPrincipalState` usa `AppStrings.alumnoSingular/Plural` (minúscula para oraciones vs. mayúscula para etiquetas `homeStudent/homeStudents`).
  - **313/313 tests pasan, 0 errores de análisis estático.**

- **Release 1.0.6+12 (2026-04-09):**
  - **Verificación completa** — 313/313 tests pasan, 0 errores de análisis estático (`flutter analyze`).
  - **APK y AAB firmados** — builds generados con `--no-tree-shake-icons` (fix error ConstFinder en icon tree shaking).
  - **Instalado en dispositivo físico** — verificado el flujo completo en Android.

- **Release 1.0.5+11 (2026-04-09):**
  - **Bug splash → login resuelto** — `SplashBloc` llamaba `configureDependencies()` duplicado; GetIt lanzaba excepción → splash iba a login en vez de `menu_principal`. Eliminada la llamada redundante.
  - **Sistema de Notificaciones (FCM)** — `NotificacionResponse` creado siguiendo arquitectura del proyecto. `fromJson` corregido para mapear campos reales del backend (`title`→`titulo`, `message`→`mensaje`, `is_read` como bool, `user_id` opcional). Conteo no leídas lee `no_leidas` en vez de `count`.
  - **Botón Refresh en NotificacionesPage** — ícono en AppBar, siempre visible, muestra spinner durante carga.
  - **`mobile_type` FCM** — simplificado a `'android'` / `'ios'` según lo que valida el backend Laravel (`in:android,ios`).
  - **Bug fecha carrito** — `CarritoPagoItem` ahora muestra chip `EstadoPagoChip` igual que `EdoCtaPage` (badge "Vencido"/"Pendiente" homogéneo).
  - **Glow splash** — porcentaje con tres capas de sombra (blurRadius 4/12/20) para efecto matrix más visible.
  - **Warning import** — eliminado import `flutter/widgets.dart` no usado en `FcmService`.

- **Sesión de revisión completa y correcciones de logout (2026-04-08):**
  - **Flujo de logout corregido** — se realizaba antes de que se limpiara la sesión; ahora el drawer llama directamente `authUseCases.logout.run()` con `await` antes de navegar
  - **Diálogo de carga animado** — `_LogoutLoadingDialog` con ícono pulsante + spinner + texto "Cerrando sesión..."; funciona en tema claro y oscuro
  - **Bug del diálogo ciclado** — corregido con `rootNavigator: true` en `Navigator.of(context)` para que `pushAndRemoveUntil` elimine el diálogo del navigator raíz
  - **`mobile_type` corregido** — `FcmService.obtenerTipoDispositivo()` retorna `'Android'`, `'iPhone'` o `'iPad'` (detecta iPad por pantalla ≥ 600 dp, sin paquetes extra)
  - **"Cerrar Sesión" movido al Drawer** — quitado del AppBar, agregado en `UserDrawer` debajo de "Cambiar Contraseña" con color de error
  - **`configureDependencies()` descomentado** — era crítico para que el DI funcione
  - **0 errores de análisis — 313/313 tests pasan**

- **Registro/desregistro de dispositivo FCM corregido (2026-04-08):**
  - Endpoint POST corregido: `/api/v1/dispositivo/registrar` (antes era incorrecto)
  - Nuevo endpoint DELETE: `/api/v1/dispositivo/eliminar` al hacer logout
  - `FcmService`: nuevo método `eliminarToken(authToken, fcmToken)` con DELETE
  - `MenuPrincipalBloc._onLogout()`: ahora llama `_eliminarTokenFcm()` antes de limpiar sesión local
  - `main.dart`: se descomentó `await configureDependencies()` (DI ahora funciona correctamente)
  - `MenuPrincipalBloc` requiere 3 parámetros; `MockFcmService` agregado a los helpers de test
  - 313/313 tests pasan, 0 errores de análisis

- **UX Menú Principal — Cerrar Sesión movido al Drawer (2026-04-08):**
  - Botón logout removido del AppBar de `MenuPrincipalPage`
  - "Cerrar Sesión" agregado en `UserDrawer` debajo de "Cambiar Contraseña", con ícono y texto en color error
  - Lógica del diálogo de confirmación movida a `UserDrawer._handleLogout()`

- **Sistema de Notificaciones Push — Parte B Flutter (2026-04-08):**
  - **Dependencias agregadas:** `firebase_core ^3.13.0`, `firebase_messaging ^15.2.4`, `flutter_local_notifications ^18.0.0`, `flutter_widget_from_html_core`, `badges ^3.1.2`
  - **Capa de dominio:** Entidad `Notificacion` (con Equatable, fromJson/toJson/copyWith), `NotificacionRepository` (interfaz), 4 use cases (`GetNotificaciones`, `GetCountNoLeidas`, `MarcarLeida`, `MarcarTodasLeidas`), `NotificacionUseCases` (agregado)
  - **Capa de datos:** `NotificacionService` (HTTP con paginación, auth Bearer, manejo de errores igual a EdoCtaService), `FcmService` (obtenerToken, registrarToken, eliminarToken, configurarHandlers con background handler), `NotificacionRepositoryImpl`
  - **Endpoints en `endpoints.dart`:** `notificaciones`, `notificacionesNoLeidas`, `notificacionMarcarLeida`, `notificacionesMarcarTodas`, `dispositivoRegistrar`, `dispositivoEliminar`
  - **BLoC:** `NotificacionEvent` (6 eventos), `NotificacionState` (estado único con copyWith), `NotificacionBloc` (carga paralela con Future.wait, paginación, optimistic update, foreground push)
  - **UI:** `NotificacionesPage` (RefreshIndicator + paginación por scroll + pull-to-refresh), `NotificacionItemWidget` (badge no leída, fecha relativa, strip HTML), `NotificacionVaciaWidget` (estado vacío elegante), `NotificacionDetalleWidget` (bottom sheet con HtmlWidget), `NotificacionBadgeButton` (badge animado en AppBar)
  - **Integración:** campana + badge en AppBar de `MenuPrincipalPage`, ruta `notificaciones` en `main.dart`, `NotificacionBloc` en `blocProvider.dart`, DI completo en `AppModule.dart`
  - **Plataforma Android:** Permisos `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` en AndroidManifest, plugin `google-services 4.4.2` en `settings.gradle.kts` y `app/build.gradle.kts`
  - **Plataforma iOS:** `NSUserNotificationUsageDescription` + `UIBackgroundModes` en `Info.plist`, `FirebaseApp.configure()` en `AppDelegate.swift`
  - **injection.config.dart regenerado** con los 4 nuevos registros
  - **Firebase listo:** `google-services.json` y `GoogleService-Info.plist` ya están en el repo

- **Módulo CambiarContrasena — revisado y pulido (2026-03-26):**
  - `DefaultTextField` ahora soporta `useThemeColors: true` para fondos de Scaffold (claro/oscuro), sin romper Login/Register que usan fondo oscuro con imagen
  - Body del POST incluye `user_id`, `password_actual`, `password`, `password_confirmation`
  - Respuestas manejadas con `AlertDialog` (no SnackBar): éxito → logout + navega a MyApp, error → queda en la misma pantalla
  - `AuthService` detecta respuestas HTML (500/404) y `status:0` como errores lógicos
  - `CambiarContrasenaBloc` llama `authUseCases.logout.run()` antes de emitir éxito
  - `CambiarContrasenaUseCase.repository` marcado `final`
  - Token vacío verificado con `token.isEmpty` en `AuthRepositoryImpl`
  - `theme` movido dentro del `BlocBuilder` para reactividad correcta
  - 21/21 tests pasan

- **Módulo CambiarContrasenaPage** — Ecosistema completo: endpoint `/api/v1/user/change/password/mobile`, `CambiarContrasenaService` (POST con JWT), `CambiarContrasenaUseCase`, `CambiarContrasenaBloc` (validación en tiempo real), `CambiarContrasenaPage` + includes (Content + Response). Drawer simplificado: se quitó sección Versiones y datos redundantes, se agregó entrada a Cambiar Contraseña. Ruta `cambiar_contrasena` registrada en `main.dart`. Todos los tests pasan.
- **Build de release configurado** - Nuevo keystore, build.gradle.kts corregido (Kotlin), APK y App Bundle generados y firmados
- **Filtrado y selección condicional en EdoCtaPage** - Solo muestra pagos con `estaDisponibleEnInternet`, regla de orden solo si `aceptaPagosDiversos`
- **Limpieza completa de storage al logout** - Al cerrar sesión se eliminan todos los datos (SecureStorage + SharedPreferences)
- **Limpieza de código no utilizado** - Eliminados archivos huérfanos y carpeta vacía
- **Modelos robustos** - Todos los modelos con null safety (`?.toString() ?? ''`, `?? 0`, `?? false`)
- **ApiConfig mejorado** - Configuración flexible para emulador/dispositivo físico/producción
- **PagoResponse integrado** - Modelo, servicio, repositorio, caso de uso completos
- **Corrección de 58 warnings de estilo** - Comillas simples, constantes lowerCamelCase, deprecated fixes

- **Carrito de Compras completo** - Módulo completo con Clean Architecture, WebView para pagos con Adquira México, sincronización con EdoCtaPage
- **Endpoints centralizados** - Clase `Endpoints` en `lib/src/data/api/endpoints.dart` con todos los endpoints de la API
- **AppTheme con fuentes del sistema** - Respeta tamaño de fuente configurado por el usuario en Android/iOS
- **Material Theme Builder integrado** - Nuevo sistema de temas con 6 variantes (light, lightMediumContrast, lightHighContrast, dark, darkMediumContrast, darkHighContrast)
- **Fix navegación MenuPrincipal** - Corregido bug donde no se podía navegar dos veces al mismo item
- **Persistencia de pagos seleccionados** - Los pagos seleccionados en EdoCtaPage se guardan en SharedPreferences y persisten al cerrar/abrir la app
- **EdoCtaPage (Estados de Cuenta)** - Página completa para ver y seleccionar pagos pendientes
- **Navegación funcional desde MenuPrincipal** - Click en "Pagos" navega a EdoCtaPage
- **Compatibilidad tema claro/oscuro** - Todos los widgets corregidos para funcionar en ambos temas
- **AppColors extendido** - Nuevos colores para tema oscuro con métodos helper
- **MenuPrincipalBloc** - Menú principal post-login con BLoC completo
- Widget `CloseSession` - Diálogo de confirmación reutilizable
- **AppTheme centralizado** - Material Design 3 con colores de marca
- **Widgets reutilizables** - BackgroundImage y GlassContainer
- **RegisterBloc** - Lógica completa de registro con validación
- **SplashBloc** - Lógica de splash movida a BLoC
- **SecureStorage** - Almacenamiento seguro para tokens y sesión

---

## Errores iOS conocidos y sus soluciones

### Firebase swizzling log `[I-FCM001000]`

**Síntoma:** `FIRMessaging Remote Notifications proxy enabled, will swizzle remote notification receiver handlers.`

**Fix:**
1. `ios/Runner/Info.plist` → `FirebaseAppDelegateProxyEnabled = false`
2. `ios/Runner/AppDelegate.swift` → agregar `import FirebaseMessaging` + reenvío manual:
   - `didRegisterForRemoteNotificationsWithDeviceToken` → asignar `Messaging.messaging().apnsToken = deviceToken`
   - `didReceiveRemoteNotification` → llamar `super`

> `FirebaseAppDelegateProxyEnabled = YES` **no** suprime el log. Solo `NO` + reenvío manual lo elimina.

### `url_launcher` — sandbox extension error en iOS

**Síntoma:** `unable to make sandbox extension: [1: Operation not permitted]`

**Fix:** `ios/Runner/Info.plist` → agregar `LSApplicationQueriesSchemes` con `https` y `http`.

> Equivalente al `<queries>` de `AndroidManifest.xml`. Ambos deben mantenerse sincronizados al agregar `url_launcher`.

### Logs de sistema iOS — NO son errores de la app

Estos mensajes aparecen solo en builds de desarrollo y **no son corregibles desde el código**:

- `FlutterView implements focusItemsInRect:` → warning del motor Flutter (C++), cosmético
- `unable to make sandbox extension` (post-fix url_launcher) → WebKit creando proceso sandboxed para WKWebView

En builds de release / App Store no aparecen.

---

## Notas de sesiones

### 2026-02-01

- Sesión inicial con Claude Code
- Configurado CLAUDE.md para memoria de proyecto
- **Creado AppTheme centralizado** (`lib/src/core/theme/app_theme.dart`)
  - Tema claro y oscuro completo
  - Usa colores de AppColors
  - Incluye: ColorScheme, AppBar, Botones, Inputs, Cards, Dialogs, TextTheme, etc.
  - main.dart actualizado para usar AppTheme.light/dark con ThemeMode.system
- **Creados widgets reutilizables:**
  - `BackgroundImage` - Imagen de fondo con overlay configurable
  - `GlassContainer` - Contenedor con efecto glass para formularios
  - Actualizado LoginPage, LoginContent y RegisterPage para usar los nuevos widgets
  - Eliminado LoginBackground.dart (reemplazado por BackgroundImage)
- **Implementado RegisterBloc completo:**
  - RegisterEvent.dart - Eventos para cada campo del formulario
  - RegisterState.dart - Estado con validación de campos
  - RegisterBloc.dart - Lógica de validación en tiempo real
  - RegisterUseCase.dart - Caso de uso para registro
  - RegisterContent.dart y RegisterResponse.dart - UI del registro
  - Actualizado AuthRepository, AuthService, AuthUseCases
  - Validaciones: nombre, apellidos, celular (10 dígitos), email, contraseñas coincidentes
- **Implementado SplashBloc:**
  - SplashEvent.dart - Eventos de inicio, progreso y navegación
  - SplashState.dart - Estado con progreso, texto y destino de navegación
  - SplashBloc.dart - Lógica de inicialización y verificación de sesión
  - SplashPage refactorizado: StatelessWidget con widgets separados
  - Eliminados: Timer manual, flags \_hasNavigated, lógica en initState
  - Usa colores de AppColors para el gradiente
- **Implementado SecureStorage:**
  - Nuevo servicio `SecureStorage` usando flutter_secure_storage
  - Encriptación automática: Android (EncryptedSharedPreferences), iOS (Keychain)
  - AuthRepositoryImpl actualizado para usar SecureStorage
  - Tokens y sesión de usuario ahora se almacenan de forma segura
  - SharedPref se mantiene para preferencias no sensibles

### 2026-03-04

- **Implementado MenuPrincipalBloc completo:**
  - `MenuPrincipalEvent.dart` - Eventos: Initial, ItemSelected, Logout
  - `MenuPrincipalState.dart` - Estado con usuario, menuItems y modelo MenuItem
  - `MenuPrincipalBloc.dart` - Lógica con AuthUseCases para datos de sesión
  - `MenuPrincipalPage.dart` - UI con header de usuario y ListView de opciones
  - Estructura: `lib/src/presentation/pages/menu_principal/`
- **Integración con arquitectura existente:**
  - `blocProvider.dart` - Registrado MenuPrincipalBloc con inyección de AuthUseCases
  - `main.dart` - Añadida ruta 'menu_principal'
  - `LoginResponse.dart` - Navegación post-login cambiada de 'Homes' a 'menu_principal'
- **Características del MenuPrincipal:**
  - Header con gradiente mostrando nombre y email del usuario (desde AuthResponse)
  - Avatar circular con inicial del nombre
  - ListView con items: Pagos y Facturas (expandible)
  - Botón de cerrar sesión en AppBar con diálogo de confirmación
  - Preparado para navegación a páginas futuras
- **Fix en DefaultTextField:**
  - Agregado `filled: false` para evitar conflicto con InputDecorationTheme global
  - Las cajas de texto en LoginPage ahora se muestran correctamente sin fondo blanco

### 2026-03-05

- **Auditoría y corrección de compatibilidad tema claro/oscuro:**
  - Revisión completa de todos los widgets y componentes
  - Todos los componentes ahora son compatibles con Android e iOS en ambos temas

- **AppColors actualizado** (`lib/src/core/constants/app_colors.dart`):
  - Nuevos colores para tema oscuro: alumnoActivoBackgroundDark, alumnoActivoTextDark, alumnoBajaBackgroundDark, alumnoBajaTextDark
  - Nuevos colores para header oscuro: homeHeaderBackgroundDark, homeHeaderIconDark, homeHeaderTextDark
  - Métodos helper: getAlumnoActivoBackground(isDark), getAlumnoBajaBackground(isDark), getHomeHeaderBackground(isDark), etc.

- **Widgets corregidos para tema oscuro:**
  - `HomeHeaderWidget.dart` - Usa AppColors con métodos helper según tema
  - `AlumnoItem.dart` - Colores de chip baja adaptables, textos con theme.colorScheme
  - `NoTienesCuentaAun.dart` - Diálogo usa theme.dialogTheme.backgroundColor
  - `MenuPrincipalPage.dart` - \_MenuItemTile usa colorScheme.primaryContainer para tema oscuro
  - `HomeDrawer.dart` - Usa colorScheme para colores de header, texto y botones
  - `HomeErrorWidget.dart` - Icono y texto de error usan theme.colorScheme.error
  - `HomeEmptyWidget.dart` - Icono y texto usan theme.colorScheme.onSurfaceVariant
  - `UserAvatar.dart` - Usa AppColors helper methods para colores de fondo y texto

- **Verificación:**
  - `flutter analyze` sin errores ni warnings
  - Todos los widgets usan colores del tema o AppColors adaptables

### 2026-03-05 (continuación)

- **Implementado módulo completo de Estados de Cuenta (EdoCta):**
  - Arquitectura limpia siguiendo patrones existentes del proyecto

- **Capa de datos:**
  - `EdoCtaService.dart` - Servicio HTTP que consume `/api/v1/alumno/estado-de-cuenta-sin-pagar/`
    - POST con Bearer Token y user_id en body
    - Manejo de errores, timeout y conexión
  - `EdoCtaRepositoryImpl.dart` - Implementación del repositorio

- **Capa de dominio:**
  - `EdoCtaRepository.dart` - Interfaz del repositorio
  - `GetEstadosDeCuentaUseCase.dart` - Caso de uso para obtener estados de cuenta
  - `EdoCtaUseCases.dart` - Agrupador de casos de uso

- **Capa de presentación:**
  - `EdoCtaListEvent.dart` - Eventos: Initial, Refresh, TogglePago, LimpiarSeleccion
  - `EdoCtaListState.dart` - Estado con alumnos, pagos seleccionados, helpers de cálculo
  - `EdoCtaListBloc.dart` - Lógica de selección de pagos en orden ascendente por ID
  - `EdoCtaPage.dart` - Página completa con:
    - AppBar con botón regresar y limpiar selección
    - Lista de alumnos expandibles con sus pagos
    - Checkboxes para seleccionar pagos (respeta orden de ID)
    - Chips de estado (Pendiente/Vencido) con colores
    - Barra inferior con total seleccionado y botón "Continuar"
    - Compatible con tema claro y oscuro
    - Soporte para RefreshIndicator

- **Integración:**
  - `AppModule.dart` - Registrado EdoCtaService, Repository y UseCases
  - `blocProvider.dart` - Registrado EdoCtaListBloc
  - `main.dart` - Ruta 'edo_cta' agregada
  - `MenuPrincipalState.dart` - Item "Pagos" ahora navega a 'edo_cta'
  - `MenuPrincipalPage.dart` - Navegación funcional implementada

- **Regla de selección de pagos:**
  - Solo se pueden seleccionar múltiples pagos en orden de ID ascendente
  - Al seleccionar un pago, los anteriores (de menor ID) deben estar seleccionados
  - Al deseleccionar un pago, también se deseleccionan los de ID mayor

- **Tests actualizados:**
  - `test_data.dart` - Agregado TestEstadoDeCuenta con datos de prueba
  - TestAlumno ahora incluye estadoDeCuenta
  - `alumno_test.dart` - Corregido para incluir estado_de_cuenta en JSON

- **Correcciones durante pruebas:**
  - `EstatodosDeCuentaResponse.dart` - Campos `cicloPredeterminadoId` y `familiaId` convertidos con `.toString()` (el servidor envía int)
  - `EdoCtaPage.dart` - Ajustes de colores para tema oscuro:
    - Barra inferior usa `surfaceContainerHigh` para mejor visibilidad
    - Chips de estado con colores más brillantes (errorLight, warningLight)
    - Fondos de items seleccionados/vencidos más visibles
    - Montos seleccionados usan successLight en tema oscuro

### 2026-03-06

- **Persistencia de pagos seleccionados en EdoCtaPage:**
  - `EdoCtaListBloc.dart` modificado para recibir `SharedPref` como dependencia
  - Nuevos métodos: `_guardarPagosSeleccionados()` y `_cargarPagosSeleccionados()`
  - Al iniciar el BLoC, se cargan los pagos seleccionados guardados
  - Al cambiar selección (toggle/limpiar/refresh), se persiste en SharedPreferences
  - Clave de storage: `edo_cta_pagos_seleccionados`
  - Conversión de `Map<int, List<int>>` a JSON y viceversa
  - `blocProvider.dart` actualizado para inyectar `SharedPref` al BLoC

- **Fix modelo Alumno:**
  - `Alumno.dart` - Maneja `estado_de_cuenta: null` del servidor (devuelve lista vacía)

- **Fix navegación SplashPage:**
  - Cuando hay sesión guardada, navega a `menu_principal` en lugar de `Homes`

- **Integración Material Theme Builder:**
  - Nuevo archivo `lib/src/core/theme/material_theme.dart` (copiado de `/home/carlos/Descargas/material-theme/`)
  - 6 variantes de tema: light, lightMediumContrast, lightHighContrast, dark, darkMediumContrast, darkHighContrast
  - Colores primarios terracota/marrón rojizo (#8f4c38 claro, #ffb5a0 oscuro)
  - `app_theme.dart` reescrito para usar MaterialTheme como base
  - Todos los componentes (AppBar, Buttons, Inputs, Cards, etc.) usan ColorScheme dinámico
  - Superficie oscura: #1a110f (marrón oscuro, no negro)

- **Fix navegación MenuPrincipal:**
  - `MenuPrincipalBloc.dart` - Resetea `selectedItemId` a null después de emitirlo
  - `MenuPrincipalPage.dart` - Agregado `listenWhen` para detectar cambios en selectedItemId
  - Permite navegar múltiples veces al mismo item del menú

### 2026-03-07

- **Carrito de Compras implementado completo:**
  - Estructura: `lib/src/presentation/pages/carrito/`
  - `CarritoPage.dart` - UI con lista de pagos por alumno, total, botón pagar
  - `CarritoBloc.dart` - Lógica de carrito con eventos de pago
  - `CarritoEvent.dart` - Initial, QuitarPago, Limpiar, Pagar, PagoExitoso, PagoFallido, CancelarPago
  - `CarritoState.dart` - Estado con helpers: totalAPagar, cantidadPagos, itemsCarrito, referenciaPago

- **Endpoints centralizados:**
  - Nuevo archivo `lib/src/data/api/endpoints.dart`
  - Clase abstracta `Endpoints` con todos los endpoints como constantes estáticas
  - Elimina duplicación de URLs en el código

- **AppTheme actualizado:**
  - `app_theme.dart` reescrito para usar `MaterialTheme.lightScheme()` y `MaterialTheme.darkScheme()`
  - Removido textTheme hardcodeado para respetar tamaño de fuente del sistema
  - `main.dart` usa `MediaQuery.copyWith(textScaler)` para preservar configuración de accesibilidad

- **PagoRequest modelo:**
  - Nuevo modelo `lib/src/domain/models/PagoRequest.dart`
  - Campos: token, userId, importe, urlRetorno, idExpress, financiamiento, moneda, tipo, tipoPago, plazos, mediosPago, referencia
  - Método `toMap()` para POST request

- **WebView de pago:**
  - `lib/src/presentation/pages/pago_webview/PagoWebViewPage.dart`
  - POST request con Bearer token en header
  - Body form-urlencoded con parámetros de PagoRequest
  - Detecta URL de retorno para éxito/fallo
  - `PagoWebViewArgs` para pasar datos entre páginas

- **Sincronización EdoCtaPage ↔ Carrito:**
  - Nuevo evento `EdoCtaRecargarSeleccionEvent` en EdoCtaListBloc
  - Al regresar del carrito, EdoCtaPage recarga selecciones desde storage
  - Fix para evitar desincronización cuando se vacía el carrito

- **Regla de eliminación en carrito (inversa a selección):**
  - Solo se puede eliminar el pago con ID más alto por alumno
  - Método `puedeQuitarPago()` en CarritoState
  - Getter `maxPagoId` en CarritoItem
  - Botón de eliminar deshabilitado para pagos que no pueden quitarse
  - Pagos ordenados de mayor a menor ID en la UI

- **Referencia de pago:**
  - IDs concatenados con 'D': ejemplo "5358D5359D5360"
  - Debug logging agregado para verificar datos de pago

- **Separadores de miles:**
  - Total en EdoCtaPage y CarritoPage formateados con separadores de miles

- **Rutas agregadas en main.dart:**
  - 'carrito' → CarritoPage
  - 'pago_webview' → PagoWebViewPage

- **Integración:**
  - `blocProvider.dart` - CarritoBloc registrado con SharedPref, AuthUseCases, EdoCtaUseCases
  - Compatible con tema claro/oscuro
  - Optimizado para Android e iOS

### 2026-03-07 (sesión 2)

- **Limpieza de código no utilizado:**
  - Eliminado `lib/src/core/core.dart` - Barrel file no importado
  - Eliminado `lib/src/core/routes/app_routes.dart` - AppRoutes nunca usado
  - Eliminado `lib/src/core/utils/http_client.dart` - AppHttpClient nunca usado
  - Eliminado `lib/src/core/theme/material_theme.dart` - Duplicado (se usa theme.dart con colores azules)
  - Eliminada carpeta vacía `lib/src/core/routes/`

- **Corrección de 58 warnings de estilo:**
  - `theme.dart` - Comillas simples + `background` → `surface` (deprecated fix)
  - `Alumno.dart` - Comillas simples en todas las keys JSON
  - `EstadoDeCuenta.dart` - Comillas simples + enum `PENDIENTE/VENCIDO` → `pendiente/vencido`
  - `EstatodosDeCuentaResponse.dart` - Comillas simples
  - `EdoCtaPage.dart` - Añadido `const` en SnackBar + referencias al enum actualizadas
  - `ApiConfig.dart` - Corregido string corrupto
  - `test_data.dart` - Referencias al enum actualizadas

- **Modelos robustos con null safety:**
  - `User.dart` - Todos los campos String usan `?.toString() ?? ''`, int usan `?? 0`
  - `Alumno.dart` - Campos robustos para manejar null del servidor
  - `EstadoDeCuenta.dart` - Campos robustos + enum con fallback a `pendiente`

- **ApiConfig mejorado:**
  - Nueva variable `isPhysicalDevice` para cambiar entre emulador y dispositivo WiFi
  - `emulatorUrl` = '10.0.2.2:8000' (para emulador Android)
  - `physicalDeviceUrl` = '192.168.1.73:8000' (IP de la PC en red local)
  - `remoteUrl` = 'arjipagos.moriah.mx' (producción)
  - Getter `localUrl` selecciona automáticamente según `isPhysicalDevice`
  - Getter `useHttps` activo solo en producción

- **PagoResponse integrado en arquitectura:**
  - `PagoResponse.dart` - Modelo robusto con `success` y `message`
  - `PagoService.dart` - Añadido método `verificarPago(referencia, token)`
  - `PagoRepository.dart` - Añadida interfaz `verificarPago()`
  - `PagoRepositoryImpl.dart` - Implementación de `verificarPago()`
  - `VerificarPagoUseCase.dart` - **Nuevo** caso de uso
  - `PagoUseCases.dart` - Añadido `verificarPago`
  - `AppModule.dart` - Inyección de `VerificarPagoUseCase`

- **Debug logging mejorado:**
  - `EdoCtaService.dart` - Log de respuesta raw (primeros 500 chars) para diagnosticar errores del servidor

- **Diagnóstico de token expirado:**
  - Identificado que el error `FormatException: <!DOCTYPE html>` ocurre cuando el token está expirado
  - Solución: cerrar sesión e iniciar de nuevo para obtener token válido

- **Optimización iOS (SafeArea):**
  - `LoginPage.dart` - Añadido SafeArea + SingleChildScrollView para notch y scroll
  - `RegisterPage.dart` - Añadido SafeArea + botón de regreso adaptativo + scroll
  - Eliminado uso de `DefaultIconBack` con coordenadas fijas (no adaptable a notch)

- **Dependencias actualizadas:**
  - `get_it` 9.2.0 → 9.2.1
  - `build_runner` 2.10.5 → 2.12.2

- **Archivo pendiente de eliminar:**
  - `DefaultIconBack.dart` - Ya no se usa (preguntar antes de eliminar)

- **Verificación final:**
  - `flutter analyze` → No issues found
  - Todos los modelos compatibles con Android e iOS
  - Todos los widgets funcionan en tema claro y oscuro
  - SafeArea en páginas de auth para compatibilidad con notch iOS

### 2026-03-09

- **WebView de pagos - Detección automática de respuesta JSON:**
  - `PagoWebViewPage.dart` - Inyecta JavaScript para detectar JSON con `success` y `message`
  - JavaScriptChannel `PagoResultado` para comunicación JS → Flutter
  - Detecta respuesta en cualquier página (Adquira o URL de retorno)
  - Flag `_pagoProcessed` evita procesar múltiples veces

- **Navegación post-pago mejorada:**
  - Pago exitoso → Diálogo de éxito → `popUntil('edo_cta')` → Recarga datos
  - Pago fallido → Diálogo de error con opciones "Volver" o "Reintentar"
  - `EdoCtaPage` convertido a StatefulWidget para detectar argumento `reload`
  - Dispara `EdoCtaListRefreshEvent` automáticamente al regresar de pago exitoso

- **SnackBars reemplazados por Diálogos en todas las páginas:**
  - `LoginResponse.dart` - Error de login
  - `LoginContent.dart` - Campos incompletos
  - `RegisterResponse.dart` - Error y éxito de registro
  - `RegisterContent.dart` - Campos incompletos
  - `MenuPrincipalPage.dart` - Error de navegación
  - `EdoCtaPage.dart` - Error de carga e información de selección
  - `CarritoPage.dart` - Error de pago

- **Login y Register - Mejoras de UI:**
  - `LogoRedondoUno.dart` - Nuevo parámetro `size` (default 150)
  - Logo reducido 25% en Login (de 150 a 112px)
  - Icono reducido 25% en Register (de 80 a 60px)
  - `GlassContainer` con `heightFactor: null` para ajustar al contenido
  - Botones usan `width: double.infinity` en lugar de `MediaQuery.of(context).size.width`
  - Teclado no tapa el botón "Iniciar Sesión" ni "Registrarse"
  - `resizeToAvoidBottomInset: true` + `SingleChildScrollView` con padding dinámico
  - Centrado correcto con `Center` y `crossAxisAlignment: CrossAxisAlignment.center`

- **WebView de pagos - Legibilidad mejorada:**
  - `enableZoom(true)` - Permite zoom con gestos
  - Inyección de CSS con fuente base de 20px
  - Inputs con fuente de 18px

- **Verificación:**
  - `flutter analyze` → No issues found
  - Responsivo en diferentes tamaños de pantalla
  - Compatible con Android e iOS

### 2026-03-09 (sesión 2)

- **Revisión exhaustiva de compatibilidad Android/iOS:**
  - Verificación de SafeArea, manejo de teclado, temas claro/oscuro
  - Todos los archivos modificados revisados y aprobados

- **Fix de seguridad en PagoWebViewPage.dart:**
  - Agregada verificación `if (!mounted) return;` en `_procesarJsonRespuesta()`
  - Agregada verificación `if (!mounted) return;` en `_procesarResultadoPagoLegacy()`
  - Previene uso de `context` después de que el widget sea disposed
  - Evita errores si el usuario cierra el WebView mientras se procesa respuesta del servidor

- **Fix ruta "facturas" faltante:**
  - Error: `Could not find a generator for route RouteSettings("facturas", null)`
  - `MenuPrincipalPage.dart` - Agregado diálogo "Próximamente" cuando el usuario intenta acceder a Facturas
  - La ruta estaba definida en `MenuPrincipalState.dart` pero no existía en `main.dart`

- **Verificación de rutas completa:**
  - Todas las rutas usadas están definidas en `main.dart`
  - Rutas verificadas: login, register, Homes, menu_principal, splash, edo_cta, carrito, pago_webview
  - Ruta `facturas` manejada con diálogo "Próximamente" hasta que se implemente

- **Verificación final:**
  - `flutter analyze` → No issues found
  - Todas las páginas usan colores del tema (`Theme.of(context).colorScheme`)
  - SafeArea en páginas de auth para notch iOS
  - Manejo de teclado con `resizeToAvoidBottomInset` y `SingleChildScrollView`

### 2026-03-10

- **Limpieza completa de storage al cerrar sesión:**
  - `AuthRepositoryImpl.dart` - Agregada dependencia `SharedPref`
  - Método `logout()` ahora limpia **ambos** storages:
    - `SecureStorage.clearUserSession()` - Tokens y sesión (datos sensibles)
    - `SharedPref.clear()` - Pagos seleccionados, carrito, preferencias (datos no sensibles)
  - `AppModule.dart` - Actualizado para pasar `SharedPref` al constructor de `AuthRepositoryImpl`
  - Al cerrar sesión se eliminan:
    - `user_session`, `access_token`, `refresh_token` (SecureStorage)
    - `edo_cta_pagos_seleccionados` y cualquier otra preferencia (SharedPreferences)

- **Filtrado de pagos por disponibilidad en internet:**
  - `EdoCtaPage.dart` - `_PagosList` ahora filtra solo pagos donde `estaDisponibleEnInternet == true`
  - Muestra mensaje "Sin pagos disponibles para pago en línea" si no hay pagos disponibles
  - `EdoCtaListState.dart` - `totalSeleccionado` solo considera pagos con `estaDisponibleEnInternet == true`

- **Regla de selección condicional por `aceptaPagosDiversos`:**
  - Si `aceptaPagosDiversos == true`: Aplica regla de orden (seleccionar de menor a mayor ID, deseleccionar también los mayores)
  - Si `aceptaPagosDiversos == false`: Se puede marcar/desmarcar libremente sin restricción de orden
  - `EdoCtaListBloc.dart` - Lógica de `_onTogglePago` actualizada para verificar `aceptaPagosDiversos` por cada pago
  - `EdoCtaPage.dart` - `_PagoItem` verifica `aceptaPagosDiversos` para habilitar checkbox

- **Regla de eliminación condicional en Carrito por `aceptaPagosDiversos`:**
  - Si `aceptaPagosDiversos == true`: Solo puede eliminarse el pago con ID más alto (regla inversa a selección)
  - Si `aceptaPagosDiversos == false`: Se puede eliminar libremente sin restricción de orden
  - `CarritoState.dart` - Nuevo método `CarritoItem.puedeEliminarPago(pagoId)` que verifica `aceptaPagosDiversos`
  - `CarritoState.dart` - Nuevo getter `maxPagoIdConPagosDiversos` (solo considera pagos con pagos diversos)
  - `CarritoState.dart` - Eliminado método obsoleto `puedeQuitarPago` (ya no se usaba)
  - `CarritoPage.dart` - `_AlumnoCard` ahora usa `item.puedeEliminarPago(pago.id)` para determinar si se puede eliminar

- **Tests actualizados:**
  - `test_data.dart` - Agregados campos `aceptaPagosDiversos` y `estaDisponibleEnInternet` a `TestEstadoDeCuenta`

- **Verificación:**
  - `flutter analyze` → No issues found

### 2026-03-10 (sesión 2)

- **Drawer de usuario en MenuPrincipal:**
  - Header con avatar, nombre y email
  - Secciones: Datos personales, Familia, Versiones
  - Todos los campos son copiables al portapapeles (tap para copiar)
  - Datos mostrados:
    - ID, usuario, nombre, apellido paterno, apellido materno
    - Email, otros emails, celulares, teléfonos
    - Familia (del servidor)
    - Resumen de alumnos (ej: "2 alumnos: Juan, María")
    - Versión de App y API
  - Ícono de hamburguesa en AppBar para abrir el drawer
  - Compatible con tema claro y oscuro

- **Refactorización completa de MenuPrincipal (Clean Architecture):**
  - **Nueva carpeta `widgets/`** con widgets modulares:
    - `menu_item_model.dart` - Modelo MenuItem separado (26 líneas)
    - `menu_item_tile.dart` - Tile de item de menú (65 líneas)
    - `menu_items_list.dart` - Lista de items (26 líneas)
    - `user_header.dart` - Header del body principal (80 líneas)
    - `user_drawer.dart` - Drawer completo del usuario (142 líneas)
    - `drawer_header.dart` - Header del drawer con SafeArea (87 líneas)
    - `section_header.dart` - Encabezado de sección (30 líneas)
    - `copyable_list_tile.dart` - ListTile copiable (69 líneas)
    - `widgets.dart` - Barrel file para exports
  - **MenuPrincipalPage.dart** reducido de 590 a 184 líneas
  - Todos los archivos cumplen regla de **<200 líneas**

- **Mejoras de tema claro/oscuro:**
  - Headers usan `colorScheme.primary` y `colorScheme.onPrimary` del tema
  - No más colores hardcodeados (`AppColors.primary`, `Colors.white`)
  - SafeArea correctamente posicionado en drawer (header llega hasta el notch)
  - Gradientes adaptativos según el tema

- **Cambios en arquitectura:**
  - `MenuPrincipalState.dart` - Nuevos campos: `user`, `apiVersion`, `appVersion`, `familia`, `alumnos`
  - `MenuPrincipalState.dart` - Re-export de `MenuItem` desde `menu_item_model.dart`
  - `MenuPrincipalBloc.dart` - Dependencia `EdoCtaUseCases` para obtener familia y alumnos
  - `blocProvider.dart` - Inyección de `EdoCtaUseCases` al `MenuPrincipalBloc`

- **Verificación:**
  - `flutter analyze` → No issues found
  - Compatible con Android e iOS
  - Tema claro y oscuro funcionando correctamente

### 2026-03-12

- **Corrección build.gradle.kts (sintaxis Groovy → Kotlin):**
  - `def` → `val`
  - `new Properties()` → `Properties()`
  - Imports agregados: `java.util.Properties`, `java.io.FileInputStream`
  - `signingConfigs { release { } }` → `signingConfigs { create("release") { } }`
  - `buildTypes { release { } }` → `buildTypes { getByName("release") { } }`
  - `minifyEnabled` → `isMinifyEnabled`
  - `shrinkResources` → `isShrinkResources`
  - Asignaciones con `=` en lugar de espacios (sintaxis Kotlin)

- **Nuevo keystore para firma de release:**
  - Archivo: `android/app/firma/arjipagos_key.jks`
  - Alias: `arjipagos`
  - Validez: 10,000 días
  - Algoritmo: RSA 2048 bits
  - DN: CN=Arjipagos, OU=Mobile, O=Arjipagos, L=CDMX, ST=CDMX, C=MX
  - Respaldo de credenciales: `android/app/firma/keystore_info.txt`

- **key.properties corregido:**
  - Eliminada línea inválida `properties`
  - Apunta al nuevo keystore de arjipagos

- **.gitignore actualizado:**
  - `/android/key.properties`
  - `/android/app/firma/`
  - `*.jks`
  - `*.keystore`

- **Builds generados:**
  - App Bundle: `build/app/outputs/bundle/release/app-release.aab` (76 MB)
  - APK: `build/app/outputs/flutter-apk/app-release.apk` (86 MB)
  - Ambos firmados correctamente con el nuevo keystore

- **Fix permiso INTERNET en release:**
  - Agregado `<uses-permission android:name="android.permission.INTERNET"/>` al `AndroidManifest.xml` principal
  - El permiso solo estaba en `src/debug/AndroidManifest.xml` (Flutter lo agrega automáticamente para debug)
  - En release, el permiso debe estar explícito en `src/main/AndroidManifest.xml`
  - Sin este permiso, la app mostraba "Sin conexión" al intentar login

- **Script de release automatizado:**
  - Creado `scripts/release.sh` para automatizar builds
  - Soporta: versión, --install, --bundle
  - Nota: El script tiene problemas con Flutter instalado vía snap
  - **Solución:** Ejecutar comandos directamente en lugar del script

- **Instrucciones de release para agente:**
  - Documentada sección "Instrucciones para Release (Agente)" en CLAUDE.md
  - Comandos: `flutter build apk --release` + `flutter build appbundle --release` + `adb install -r`
  - Triggers: "nueva versión", "release", "sube versión", "build release", "genera APK"
  - El agente ejecuta automáticamente build e instalación cuando el usuario lo solicita

### 2026-03-12 (sesión 2) - Verificación y corrección de reglas CLAUDE.md

- **Refactorización de páginas > 200 líneas:**
  - `EdoCtaPage.dart`: 663 → 80 líneas
  - `CarritoPage.dart`: 448 → 81 líneas
  - `PagoWebViewPage.dart`: 502 → 230 líneas

- **Nuevos widgets extraídos (EdoCta):**
  - `lib/src/presentation/pages/edo_cta/widgets/`
  - `loading_widget.dart`, `error_widget.dart`, `empty_widget.dart`
  - `estado_pago_chip.dart`, `pago_item.dart`, `pagos_list.dart`
  - `alumno_card.dart`, `alumnos_list.dart`, `total_seleccionado_bar.dart`
  - `edo_cta_body.dart`, `widgets.dart` (barrel file)

- **Nuevos widgets extraídos (Carrito):**
  - `lib/src/presentation/pages/carrito/widgets/`
  - `carrito_loading_widget.dart`, `carrito_empty_widget.dart`
  - `carrito_pago_item.dart`, `carrito_alumno_card.dart`
  - `carrito_total_bar.dart`, `carrito_body.dart`, `widgets.dart`

- **Nuevos widgets extraídos (PagoWebView):**
  - `lib/src/presentation/pages/pago_webview/widgets/`
  - `pago_error_widget.dart`, `pago_loading_widget.dart`, `pago_dialogs.dart`
  - `pago_webview_args.dart`, `webview_scripts.dart`

- **Permiso ACCESS_NETWORK_STATE agregado:**
  - `android/app/src/main/AndroidManifest.xml`
  - Permite verificar conectividad antes de operaciones de red

- **Tests creados para BLoCs principales:**
  - `test/unit/blocs/edo_cta_list_bloc_test.dart` (nuevo)
  - `test/unit/blocs/carrito_bloc_test.dart` (nuevo)
  - Mocks actualizados: `MockEdoCtaRepository`, `MockSharedPref`, `MockGetEstadosDeCuentaUseCase`
  - Factory: `createMockEdoCtaUseCases()`
  - 143 tests pasando, 2 pendientes de ajuste

- **Datos de prueba actualizados:**
  - `test_data.dart` - Agregados `acepta_pagos_diversos` y `esta_disponible_en_internet` en JSON

- **Verificación:**
  - `flutter analyze` → No issues found
  - Todos los archivos de página < 200 líneas (excepto PagoWebViewPage ~230, aceptable para WebView)
  - BLoCs entre 212-240 líneas (aceptable para lógica de negocio)

### 2026-03-12 (sesión 3) - Reorganización y cumplimiento de reglas

- **Creado ARJIPAGOS_PROGRESS.md:**
  - Movido todo el historial de progreso desde CLAUDE.md
  - CLAUDE.md ahora solo contiene instrucciones base del proyecto
  - Cumple con la regla: "Guardar todo en ARJIPAGOS_PROGRESS.md"

- **Refactorización final de PagoWebViewPage:**
  - Reducido de 233 a 200 líneas (cumple regla < 200)
  - Creado `pago_response_handler.dart` - Utilidad para procesar respuestas de pago
  - Clase `PagoResult` - Modelo de resultado con success, message, processed
  - Clase `PagoResponseHandler` - Métodos estáticos `procesarJson()` y `procesarLegacy()`
  - Actualizado barrel file `widgets.dart`

- **Fix test EdoCtaListBloc:**
  - Corregido constructor de positional a named parameters
  - `flutter analyze` → No issues found

- **Fix indicador de estado de alumno en EdoCtaPage:**
  - Eliminado texto tachado del nombre del alumno
  - Agregado punto de color concatenado al final del nombre:
    - 🔴 Rojo si `esBaja = true`
    - 🟢 Verde si `esBaja = false`
  - Usa `Text.rich` con `WidgetSpan` para posicionar el punto junto al texto

- **Verificación de reglas CLAUDE.md:**
  - ✅ Todos los widgets de página < 200 líneas
  - ✅ Progreso en ARJIPAGOS_PROGRESS.md
  - ✅ CLAUDE.md solo con instrucciones

### 2026-03-13

- **Preparación para Google Play Store:**
  - Cambio de paquete de `com.example.arjipagos` a `mx.moriah.arjipagos`
  - Actualizado `android/app/build.gradle.kts` (namespace y applicationId)
  - Movido `MainActivity.kt` a nueva estructura de carpetas `mx/moriah/arjipagos/`

- **Activación de R8 (ofuscación y optimización):**
  - `isMinifyEnabled = true` - Ofuscación de código
  - `isShrinkResources = true` - Eliminación de recursos no usados
  - Creado `android/app/proguard-rules.pro` con reglas para:
    - Flutter y plugins
    - WebView
    - Google Play Core (dontwarn para clases no usadas)
  - Reducción de tamaño: AAB 78.8 MB → 75.4 MB (-4.3%), APK 89.4 MB → 84.7 MB (-5.3%)
  - Archivo de mapping generado para crash reports en Play Console

- **Versión actualizada:**
  - `1.0.0+1` → `1.0.0+3`

- **Builds generados y firmados:**
  - AAB: `build/app/outputs/bundle/release/app-release.aab` (75.4 MB)
  - APK: `build/app/outputs/flutter-apk/app-release.apk` (84.7 MB)
  - Mapping: `build/app/outputs/mapping/release/mapping.txt`

---

### 2026-03-13 (sesión 2) - Corrección de warnings de build iOS (Mac)

> **Contexto:** Esta Mac se usa solo para builds iOS y subida a App Store. El proyecto real está en Linux.
> Replicar estos cambios en Linux.

#### Fix 1: Warning "All interface orientations must be supported"

- **Causa:** La app solo soporta portrait pero no declara `UIRequiresFullScreen`.
- **Fix:** Agregar `UIRequiresFullScreen = true` en `ios/Runner/Info.plist` antes de `UIStatusBarHidden`.
- **Archivo:** `ios/Runner/Info.plist`

```xml
<key>UIRequiresFullScreen</key>
<true/>
```

- **Estado:** ✅ Resuelto

#### Fix 2: iOS Deployment Target 9.0 en Pods

- **Pods afectados:** `fluttertoast_privacy`, `flutter_native_splash_privacy`, `flutter_secure_storage`
- **Causa:** Esos pods declaran `IPHONEOS_DEPLOYMENT_TARGET = 9.0`, mínimo soportado es 12.0.
- **Fix:** Agregar en `ios/Podfile` dentro del bloque `post_install`:

```ruby
target.build_configurations.each do |config|
  if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
  end
end
```

- **Estado:** ✅ Resuelto

#### Fix 3: Eliminar dependencia `fluttertoast` (deprecated en iOS 13)

- **Causa:** `UIActivityIndicatorViewStyleWhiteLarge` deprecated, y la regla del proyecto dice usar SnackBar.
- **Fix aplicado:**
  - `pubspec.yaml` — Eliminada línea `fluttertoast: ^9.0.0`
  - `lib/main.dart` — Eliminado `import 'package:fluttertoast/fluttertoast.dart'`
  - `lib/main.dart` — Reemplazado `FToastBuilder()(context, child)` por `child!`
- **Estado:** ✅ Resuelto

#### Fix 4: Lint removido `avoid_returning_null_for_future`

- **Causa:** La regla fue removida en Dart 3.3.0 y generaba warning en `flutter analyze`.
- **Fix:** Eliminar `avoid_returning_null_for_future: true` de `analysis_options.yaml`
- **Estado:** ✅ Resuelto

**Verificación:** `flutter analyze` → No issues found

#### Fix 5: Podfile - Agregar platform y suprimir warning de master specs repo

- **Causa:** CocoaPods asignaba automáticamente `iOS 13.0` y generaba warning de master specs.
- **Fix en `ios/Podfile`:**
  - Descomentar `platform :ios, '13.0'`
  - Agregar `install! 'cocoapods', :warn_for_unused_master_specs_repo => false`
- **Estado:** ✅ Resuelto

#### Fix 6: Crear `ios/Flutter/Profile.xcconfig`

- **Causa:** CocoaPods advertía que no podía establecer base configuration para el target `Profile`.
- **Fix:** Crear `ios/Flutter/Profile.xcconfig` con contenido:
  ```
  #include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
  #include "Generated.xcconfig"
  ```
- **Nota:** El warning de `base configuration` en `pod install` persiste — es un issue conocido de Flutter + CocoaPods que **no afecta el build ni la subida a App Store**.
- **Estado:** ✅ Resuelto (parcialmente — warning cosmético restante no bloquea nada)

### 2026-03-13 (sesión 3) - Primera subida a Apple App Store

- **App subida exitosamente a Apple App Store Connect**
  - Build: `1.0.0+6`
  - Certificado: `Apple Distribution: Carlos Hidalgo (CF6C8Z3W44)`
  - Estado: **Uploaded to Apple** ✅

- **Problemas resueltos durante el proceso:**
  - Bundle version debe ser mayor al último subido (era 5, subido a 6)
  - Warning dSYM de `objective_c.framework` — cosmético, no bloquea el upload
  - Certificado `Apple Distribution` instalado en Mac (antes solo había Development)

- **Flujo para futuros uploads a App Store:**
  1. Incrementar build number en `pubspec.yaml` (siempre mayor al último subido)
  2. `flutter build ios --release`
  3. Xcode → `Product → Clean Build Folder` → `Product → Archive`
  4. Xcode Organizer → `Distribute App` → `App Store Connect` → `Upload`
  5. En App Store Connect: seleccionar build → completar info → Submit for Review

- **Próximos pasos en App Store Connect:**
  - Seleccionar build `1.0.0 (6)`
  - Completar descripción, capturas de pantalla, categoría
  - Agregar URL de política de privacidad (obligatoria)
  - Calificación de edad
  - Submit for Review (Apple tarda 1-3 días)

- **Nota sobre el dSYM warning:**
  - `objective_c.framework` es un binario pre-compilado de Dart FFI sin debug symbols
  - Apple siempre mostrará el warning pero nunca bloqueará el upload
  - Workaround documentado: `xcrun dsymutil` para generar dSYM con UUID correcto y copiarlo al archive

---

### 2026-03-16

- **Assets de imágenes para iPad e iPhone:**
  - Añadidas 6 imágenes redimensionadas para iPad (`assets/arji/iloveimg-resized-ipad/`)
  - Añadidas 6 imágenes redimensionadas para iPhone (`assets/arji/iloveimg-resized-iphone/`)
  - Actualizado `pubspec.lock`

- **Actualización de .gitignore:**
  - Añadida regla `assets/arji/*.zip` para ignorar archivos zip temporales
  - Añadida regla `assets/arji/WhatsApp*/` para ignorar carpetas de WhatsApp temporales

- **Commit:** `df2b895` - Assets: añadir imágenes redimensionadas para iPad e iPhone
- **Push:** Subido a `origin/main`

- **Tests de widgets creados (52 tests nuevos):**
  - **Estructura de carpetas:** `test/widgets/common/`, `test/widgets/edo_cta/`, `test/widgets/carrito/`
  - **Widgets comunes:**
    - `primary_elevated_button_test.dart` (6 tests) - Renderizado, onPressed, colores, estilos
    - `glass_container_test.dart` (11 tests) - Dimensiones, scroll, estilos, maxWidth/maxHeight
    - `default_text_field_test.dart` (17 tests) - Label, ícono, onChanged, errores, contraseña, keyboardType, validador
  - **Widgets EdoCta:**
    - `estado_pago_chip_test.dart` (7 tests) - Estados pendiente/vencido, tema claro/oscuro
    - `loading_widget_test.dart` (4 tests) - CircularProgressIndicator, mensaje, estructura
  - **Widgets Carrito:**
    - `carrito_empty_widget_test.dart` (7 tests) - Ícono, título, mensaje, botón volver, navegación
  - **Actualizado `widget_test.dart`** para importar todos los tests de widgets
  - **Total tests del proyecto:** 251 pasando

### Sesión 2026-07-30 — Avisos de Play Store: edge-to-edge y optimización de R8

**Aviso 1 — "Es posible que la vista de extremo a extremo no funcione para todos los usuarios"**

- **Causa raíz:** el `LaunchTheme` declaraba `android:windowDrawsSystemBarBackgrounds`,
  atributo obsoleto desde Android 15 (SDK 35) que Play Console marca como incompatible
  con edge-to-edge. Además varios cuerpos scrollables no reservaban el inset inferior.
- **Nativo:** eliminado `windowDrawsSystemBarBackgrounds` de
  `android/app/src/main/res/values/styles.xml` y `values-night/styles.xml`.
  Se conservó `windowLayoutInDisplayCutoutMode=shortEdges` (no está obsoleto).
  **NO volver a agregar el atributo eliminado.**
- **NO se agregó `enableEdgeToEdge()` nativo:** `FlutterActivity` extiende
  `android.app.Activity`, no `ComponentActivity`, así que la extensión de
  `androidx.activity` no aplica. El equivalente ya existe en Dart:
  `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` en `main.dart`.
- **Dart — insets inferiores añadidos** con `MediaQuery.viewPaddingOf(context).bottom`:
  - `home/widget/HomeAlumnosList.dart` (ListView de alumnos)
  - `menu_principal/widgets/menu_items_list.dart` (ListView del menú)
  - `facturas/FacturasPage.dart` (ListView de facturas)
  - `notificaciones/NotificacionesPage.dart` (ListView de notificaciones)
- **Dart — WebViews envueltos en `SafeArea(top: false)`** (el WebView no conoce los
  insets del sistema; el AppBar ya cubre el inset superior):
  - `aviso_de_privacidad/AvisoDePrivacidadPage.dart`
  - `pago_webview/PagoWebViewPage.dart`
- **Sin cambios** en `edo_cta` y `carrito`: sus barras inferiores
  (`TotalSeleccionadoBar`, `CarritoTotalBar`) ya usan `SafeArea`.

**Aviso 2 — "Mejora la memoria y el rendimiento con la optimización de R8"**

- `android/gradle.properties`: añadido `android.r8.optimizedResourceShrinking=true`
  (requiere `isShrinkResources = true` en el buildType release, ya presente).
- **Toolchain de Android actualizado** (Play pedía AGP 9.0+):
  | Componente | Antes    | Ahora   |
  | ---------- | -------- | ------- |
  | AGP        | 8.11.1   | 9.0.1   |
  | Gradle     | 8.14     | 9.3.1   |
  | Kotlin KGP | 2.2.20   | 2.3.20  |
- **Ruptura resuelta:** AGP 9 elimina el bloque `kotlinOptions { }` dentro de
  `android { }` (error de compilación del script Kotlin). Se reemplazó por el bloque
  de nivel superior `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }`,
  igual que la plantilla oficial de Flutter 3.44.8. **NO revertir a `kotlinOptions`.**
- Se conservan `android.newDsl=false` y `android.builtInKotlin=false` en
  `gradle.properties`: la plantilla oficial de Flutter 3.44.8 los mantiene así con
  AGP 9. Gradle emite un warning de deprecación por ellos — es esperado, no un error.

**Verificación realizada**

- `flutter analyze` → sin issues
- `flutter test` → 569 tests pasando
- `flutter build apk --release` → OK (93.0 MB)
- `flutter build appbundle --release` → OK (91.5 MB)
- APK instalado en dispositivo Android físico; `targetSdkVersion=36` confirmado en el
  manifiesto del APK y el atributo obsoleto ya no aparece en los recursos compilados.
- **Pendiente:** verificar el Archive de iOS en la Mac (no verificable desde Linux) y
  validar visualmente edge-to-edge en un dispositivo con Android 15+.

**Nota:** `./gradlew` invocado directamente falla con
"Toolchain ... does not provide the required capabilities: [JAVA_COMPILER]" porque el
JDK del sistema es un JRE; Flutter pasa su propio JDK. Usar siempre `flutter build`.

### Sesión 2026-07-30 (b) — Verificación integral post-AGP 9 y revisión de actualizaciones

Auditoría completa tras el cambio de toolchain, sin modificar código de la app.

**Resultado de la verificación**

| Comprobación                    | Resultado                                  |
| ------------------------------- | ------------------------------------------ |
| `flutter analyze`               | Sin issues                                 |
| `flutter test`                  | 569 tests pasando                          |
| `flutter build apk --release`   | OK (93.0 MB)                               |
| `flutter build appbundle --release` | OK (91.5 MB)                           |
| `ApiConfig.isProduction`        | `true`                                     |

**Estado de actualizaciones — nada por subir**

- `flutter upgrade --verify-only` → **ya en la última estable (3.44.8 / Dart 3.12.2)**.
- `flutter pub upgrade` → `pubspec.lock` **sin cambios**; `pub outdated` reporta
  *direct dependencies: all up-to-date* y "already using the newest resolvable versions".
- Lo que aparece en la columna *Latest* está bloqueado por el SDK de Flutter, no por el
  proyecto: `injectable_generator` 3.1.1 (ver sección propia — el SDK fija `test_api`
  0.7.11), más `analyzer`, `_fe_analyzer_shared`, `meta`, `matcher` y `vector_math`,
  que los fija la propia versión de Flutter. **No forzar con `dependency_overrides`.**

**Permisos y configuración por plataforma (revisados, correctos)**

- **Android** — `AndroidManifest.xml`: `INTERNET`, `ACCESS_NETWORK_STATE`,
  `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
- **iOS** — `Info.plist`: `NSUserNotificationUsageDescription` y `UIBackgroundModes`;
  `IPHONEOS_DEPLOYMENT_TARGET = 15.0` uniforme en todas las configuraciones.
- **iOS — anclas críticas intactas:** `LastUpgradeCheck = 2630` en `project.pbxproj`,
  `LastUpgradeVersion = "2630"` en `Runner.xcscheme`, y los bloques del `Podfile`
  (`objective_c` con `dwarf` y el forzado de plataforma `.iOS("15.0")`).

**Límite conocido:** iOS no se compila desde este entorno Linux; el Archive y la prueba
en dispositivo iOS siguen requiriendo la Mac. La verificación de iOS aquí es estática
(configuración, permisos y anclas de proyecto), y el código Dart es compartido y ya está
cubierto por el `analyze` y los 569 tests.

---

## Próximas tareas

- Página de Facturas
- Manejo automático de token expirado (refresh token o logout automático)
- Completar información en App Store Connect y enviar a revisión
