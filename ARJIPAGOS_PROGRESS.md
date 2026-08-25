# Arjipagos - Progreso del Proyecto

<!--
  Este archivo contiene todo el historial de desarrollo.
  Actualizar al final de cada sesión de trabajo.
-->

## Estado actual del proyecto

### En progreso

_(ninguno)_

### Pendiente

- **PUBLICAR LA 1.0.26+35** (arreglo del crash de cierre de sesión, commit `7db8f6e`):
  - **Play Store:** subir `build/app/outputs/bundle/release/app-release.aab` (63.2 MB con
    `versionCode 35` / `versionName 1.0.26`). **Hay que regenerarlo:** el `flutter clean` del
    2026-08-24 —parte de la limpieza obligatoria de iOS— borró `build/` entero y con él el AAB
    que estaba listo. Basta `flutter build appbundle --release`
  - **App Store: HECHO el 2026-08-24.** Limpieza obligatoria ejecutada en la Mac
    (`flutter clean && flutter pub get && cd ios && pod install && ./scripts/build_ios.sh`),
    `Runner.app` de 26.4 MB, todos los blindajes verificados después
    (`LastUpgradeCheck`/`LastUpgradeVersion` en 2630, `Package.swift` en `.iOS("15.0")`,
    AppIcon con 0 huérfanos). **Archive limpio y build 35 subido a App Store Connect**, sin
    chocar con el 34 que ya estaba. Queda esperar el procesado y enviar a revisión
  - **Backend:** subir `version_recomendada` de `1.0.25` a `1.0.26` una vez publicada. Hoy
    queda por detrás del binario
- Mejorar manejo de errores en WebView (timeout, sin conexión)
- Manejo automático de token expirado (refresh token o logout automático)
- **Vigilar `pdfx`:** aplica el Kotlin Gradle Plugin y Flutter avisa que versiones futuras
  fallarán al compilar con plugins que lo hagan. Hoy compila bien; seguir su changelog.
- **Verificación de número celular vía SMS (OTP):** el usuario escribe su número → backend envía SMS con código (Twilio/AWS SNS) → usuario ingresa OTP → backend confirma. Requiere endpoint en Laravel y pantalla de verificación en Flutter.

### Completado recientemente

- **La 1.0.26+35 verificada en iPhone (2026-08-24):**

  Primera vez que el arreglo del cierre de sesión y el visor de ticket propio se ejercitan en
  iOS. Hasta hoy ambos solo se habían probado en Android (Oppo CPH2639).

  **Limpieza completa antes de probar**, tal como manda `CLAUDE.md`: `flutter clean` →
  `flutter pub get` → `pod install` → `./scripts/build_ios.sh`. El `post_install` del Podfile
  hizo su trabajo solo, y lo dejó por escrito en la consola: `✔ Run Script 'Generate dSYM for
  objective_c native asset' configurado` y `✔ LastUpgradeCheck fijado en 2630`. Resultado:
  `build/ios/iphoneos/Runner.app`, 26.4 MB, en 161 s.

  **Blindajes comprobados después del build** —el momento en que Flutter los degrada—:

  | Invariante | Estado |
  | --- | --- |
  | `LastUpgradeCheck` / `LastUpgradeVersion` | 2630 en ambos |
  | `Package.swift` (SPM efímero) | `.iOS("15.0")`, forzado por el `post_install` |
  | `LaunchAction` / `ArchiveAction` | ambas en `Release` |
  | `objective_c` → `dwarf` en el Podfile | intacto |
  | AppIcon | 25 entradas / 21 PNG, 0 huérfanos y 0 fantasmas |
  | `ApiConfig.isProduction` | `true` |
  | Binario | `1.0.26` build 35, `com.example.arjipagos` |
  | Tests | 844 pasando tras la limpieza |

  **Verificado en el dispositivo** (iPhone 17 Pro Max, corriendo desde Xcode con el botón Run,
  que usa `LaunchAction = Release`):

  - **Cerrar sesión funciona.** Es lo que arreglaba el commit `7db8f6e`; en iOS tampoco
    revienta ya con el `Stack Overflow` de `redepthChildren`.
  - **El ticket abre DENTRO de la app.** No cae al `TicketListoWidget` de respaldo, que era el
    riesgo si los plugins nativos no entraban. Quedó explicado por qué entran: `open_filex`
    sigue por CocoaPods —`open_filex.framework` está dentro del `.app`— y **`pdfx 2.11.0` entra
    por Swift Package Manager**, enlazado estático, así que no aparece como framework aparte.
    De ahí el aviso `The following plugins do not support Swift Package Manager: open_filex`,
    que es informativo: por eso `pod install` sigue siendo parte del flujo.
  - **Navegación por todos los módulos** sin un solo error de la app en consola.

  **Cuatro mensajes nuevos de consola catalogados como ruido** en la tabla de `CLAUDE.md`:
  `Reading from public effective user settings`, `Gesture: System gesture gate timed out`,
  `RTIInputSystemClient ... dismissAutoFillPanel`, y `Snapshotting a view (UIKeyboardImpl)`.
  Los dos últimos van siempre en pareja al abrir y cerrar campos de texto: iOS quiere cerrar
  su panel de autorrelleno y fotografiar su teclado, pero el engine de Flutter gestiona su
  propio `TextInput` y UIKit no se entera. Todas son clases de UIKit; **ninguna del proyecto**,
  y silenciarlas exigiría tocar el manejo de teclado del engine.

  **Aviso de CocoaPods que tampoco es un fallo:** `CocoaPods did not set the base configuration
  of your project`. Los tres `ios/Flutter/*.xcconfig` ya incluyen los de Pods con `#include?`;
  comprobado archivo por archivo.

  **Desenlace:** con todo lo anterior en verde se hizo el **Archive, que salió sin problemas**,
  y el **build 35 quedó subido a App Store Connect** el mismo día. Ni un aviso de dSYM que
  atender: el Run Script del Podfile hizo su trabajo.

- **El ticket se ve DENTRO de la app + restauración de estado (2026-08-21):**

  Cierra de verdad el reporte "tras abrir un ticket, el atrás cierra o minimiza la app", que
  la sesión anterior daba por corregido sin estarlo.

  **Primero: la corrección del 2026-08-20 nunca se escribió.** `MainActivity.kt` seguía
  pelada (`class MainActivity : FlutterActivity()`), sin la guarda `isTaskRoot` que el propio
  ARJIPAGOS_PROGRESS.md describía como aplicada y verificada con 678 tests y APK instalado.
  Lección: verificar el archivo, no el registro. Hoy la guarda **sí** está escrita y comentada.

  **Qué se reprodujo en el dispositivo** (OPPO CPH2639, Android 16, navegación por gestos,
  conducido por `adb` con `dumpsys activity activities` en cada paso):

  | Camino probado | Resultado |
  | --- | --- |
  | Abrir ticket → *Abrir con* → cancelar → volver por icono / recientes → atrás | correcto |
  | Abrir con 3 visores distintos (All Reader, Internet Visor de PDF, Lector de PDF) | los tres abren **tarea propia**, no se apilan en la nuestra |
  | Diálogo *Abrir con* dejado vivo + relanzar con `MAIN/LAUNCHER + RESET_TASK_IF_NEEDED` | Android trae la tarea al frente, no crea segunda instancia |
  | Proceso reciclado en segundo plano (`am kill`) + volver | **FALLO**: la app arrancaba en Menú Principal y el siguiente atrás salía de la app |

  El precondicionante del *launcher relaunch bug* **sí es real y quedó probado**: el diálogo
  *Abrir con* (`ResolverActivity`) se apila DENTRO de nuestra tarea (`sz=1` → `sz=2`), porque
  `open_filex` y `share_plus` lanzan el intent sin `FLAG_ACTIVITY_NEW_TASK`. Por eso la guarda
  se deja puesta, aunque en Android 16 no se logró que llegara a crear la segunda instancia.

  **La causa del síntoma es el reciclado de proceso**, y la raíz de fondo era el diseño del
  flujo: el ticket se entregaba a una app ajena —visores con anuncios, que además presionan la
  memoria— así que cada regreso quedaba a merced de cómo Android tratara nuestra tarea.

  **Solución 1 — visor de PDF propio (`pdfx` 2.11.0, autorizado por el usuario).** El ticket
  se pinta dentro de la app en las dos plataformas (Android usa el renderizador nativo, iOS
  CoreGraphics/PDFKit). Pantalla nueva: AppBar con el folio, zoom con pinza, indicador
  "Página N de M" cuando hay varias, y las acciones apiladas abajo —*Compartir* como principal
  y *Abrir en otra app* como salida secundaria—. Salir de la app pasó a ser una elección del
  usuario, no el camino por defecto.

  - **La hoja del PDF se deja en blanco también en tema oscuro**: es un documento fiscal y
    alterarle los colores lo desfigura. Lo que se adapta al tema es el fondo sobre el que
    descansa, así se lee como una hoja de papel sobre un escritorio en ambos modos.
  - **Respaldo probado en vivo:** si el motor nativo no puede abrir el documento,
    `onDocumentError` muestra `TicketListoWidget` con las dos acciones. Se vio funcionar sin
    querer —con el APK viejo, el hot reload no puede añadir plugins nativos y el canal
    respondía `PlatformException(channel-error)`—, que es exactamente para lo que existe.
  - **Verificado con aapt2:** `pdfx` **no añade ni un permiso**. El APK release conserva los
    mismos siete de siempre. Tamaño: 93.6 → 95.4 MB.
  - Se retiró el traspaso automático al terminar la descarga y con él `yaCompartido` /
    `TicketCompartidoEvent`, que quedaban sin uso.

  **Solución 2 — restauración de estado.** `MaterialApp(restorationScopeId: 'arjipagos')` y
  rutas restaurables en splash, login, menú, drawer, notificaciones y ticket. Si Android
  recicla el proceso, la app vuelve **a la pantalla donde estaba** y el atrás funciona.
  Comprobado en dispositivo: con el ticket abierto, `am kill` + volver por el icono → reaparece
  el ticket (el PDF se vuelve a descargar) y el gesto atrás lleva a Pagos Realizados.

  Los argumentos de la ruta del ticket viajan como **mapa de strings** (`TicketArgs.aMapa()` /
  `desdeRuta`): el sistema operativo solo sabe guardar tipos primitivos, una instancia de clase
  no sobreviviría al reciclado. Hay test que blinda la ida y vuelta.

  **Tres rutas se dejaron NO restaurables a propósito**, cada una comentada en el código:

  | Ruta | Motivo |
  | --- | --- |
  | `pago_webview` | reabrir sola una sesión de pago con URL, parámetros y token viejos es peligroso; el usuario vuelve al carrito y decide |
  | `carrito` | espera el regreso para recargar la selección, y `restorablePushNamed` no devuelve `Future`. La selección vive en `SeleccionPagosStorage`, no en la pila |
  | `notificaciones` (desde el badge) | igual: espera el regreso para refrescar el contador |

  ⚠️ **Efecto secundario a tener presente:** al restaurar, el splash no vuelve a correr, así que
  la verificación de sesión se salta. Con un token vencido las pantallas restauradas mostrarán
  error de red en vez de mandar al login. Refuerza la tarea pendiente de "manejo automático de
  token expirado".

  ⚠️ **`pdfx` aplica el Kotlin Gradle Plugin** y Flutter ya avisa que versiones futuras fallarán
  al compilar con plugins que lo hagan. Hoy compila sin problema; hay que seguir el changelog
  del paquete.

  **Pendiente en la Mac:** `pod install` para que entren los pods de `pdfx` y `open_filex`.

- **Pagos Pendientes y Carrito: renglón legible y tipografía congruente (2026-08-21):**

  Reporte del usuario: en Pagos Pendientes el concepto se cortaba y la fecha no se veía
  completa. Se rediseñó el renglón de pago **con el usuario mirando el dispositivo**, y cada
  intento intermedio dejó una lección que quedó fijada en tests:

  1. **Encoger el texto por item no sirve.** El primer intento usaba `FittedBox` en el
     concepto: cada renglón se encogía por separado, así que el pago con el texto más largo
     salía con letra más chica y la lista se veía despareja —el usuario lo detectó de
     inmediato—. Ahora el concepto **conserva siempre el tamaño del tema** y, si no cabe, pasa
     a dos líneas.
  2. **El importe usaba `titleMedium`**, un escalón más grande que el concepto, y hacía que
     este pareciera secundario. A propuesta del usuario ahora usa el mismo `bodyLarge` **en
     negrita**: destaca por peso y color, no por tamaño.
  3. **El concepto necesita el renglón entero.** Con el importe al lado se partía en dos
     líneas. La estructura final es de tres renglones iguales para todos los items:
     concepto completo · fecha + importe · chip de estado + número de pago.
  4. **El chip se estiraba a todo el ancho** dentro del `Expanded` (el usuario: "se ve
     horrible"). Va anclado con `Align` y conserva su tamaño natural.

  **`FilaAdaptable`** (`lib/src/presentation/widgets/FilaAdaptable.dart`) es la pieza nueva que
  comparten las dos pantallas: mide el texto de la derecha con su estilo **y con la escala de
  fuente del sistema**; si necesita más de la mitad del ancho, lo baja a su propia línea. Sin
  ninguna medida escrita a mano —el ancho lo da `LayoutBuilder`, el tamaño el tema y la escala
  el `MediaQuery`—. Surgió de un desborde real que encontró el test nuevo: 25 px a fuente x2.

  **La fecha ya no se recorta**: se encoge solo si hace falta, y ahí el ajuste sí es uniforme
  porque todas las fechas del backend miden lo mismo.

  El mismo tratamiento se aplicó al **carrito** (`CarritoPagoItem`), donde el botón de quitar
  ocupa el lugar del número de pago. Las dos pantallas se leen igual.

  **Verificación:** `flutter analyze` sin issues · `flutter test` **713 en verde** (antes 678)
  · APK debug instalado y revisado en el dispositivo en tema claro y oscuro. Tests nuevos:
  `pago_item_test.dart` (11), `ticket_acciones_bar_test.dart` (5), `ticket_listo_widget_test.dart`
  (5), `ticket_loading_widget_test.dart` (3), `ticket_args_test.dart` (6) y 3 casos añadidos a
  `carrito_pago_item_test.dart`. Cubren anchos de 320/360/375 px, fuente del sistema al doble y
  los dos temas.

  **Nota sobre la barra de overflow que vio el usuario:** era real, de la primera versión de
  `TicketAccionesBar` con los dos botones en fila (2 px en 360 dp). Corregida apilándolos, con
  test que fija el caso.

- **El botón atrás cerraba la app tras abrir un ticket (2026-08-20):**

  ⚠️ **Esta entrada quedó desmentida el 2026-08-21:** la guarda que describe **nunca se
  escribió** en `MainActivity.kt`, así que ni el arreglo ni su verificación ocurrieron como
  aquí se cuenta. La causa real del síntoma y la corrección de verdad están en la entrada del
  2026-08-21. Se conserva el diagnóstico porque el mecanismo que describe sí es correcto.

  Reporte del usuario: en Pagos Realizados, tras abrir un ticket y volver a la app, la flecha
  atrás **cerraba o minimizaba** la aplicación en vez de regresar a la lista.

  **Diagnóstico en el dispositivo real** (OPPO CPH2639, Android 16), con `dumpsys activity
  activities`: al abrir el ticket, la tarea de la app pasa de **`sz=1` a `sz=2`**. Es decir,
  la actividad ajena —el diálogo *Abrir con*, o el visor de PDF, según la app que elija el
  usuario— **se apila DENTRO de nuestra tarea**, porque `open_filex` lanza el intent solo con
  `FLAG_ACTIVITY_SINGLE_TOP`, sin `FLAG_ACTIVITY_NEW_TASK`.

  A partir de ahí, el mecanismo es el *launcher relaunch bug* clásico de Android:

  1. La actividad ajena queda encima de `MainActivity` en la misma tarea.
  2. El usuario vuelve por el icono del launcher → Android entrega `MAIN/LAUNCHER` con
     `FLAG_ACTIVITY_RESET_TASK_IF_NEEDED`.
  3. Como `MainActivity` ya **no está arriba**, el `launchMode="singleTop"` del manifest **no
     aplica** y el sistema crea una **segunda instancia** de la actividad.
  4. Instancia nueva = **motor de Flutter nuevo** = pila de navegación con una sola ruta. El
     atrás no tiene a dónde volver y termina la actividad.

  **Corrección** en `MainActivity.kt`, que estaba pelada (solo `class MainActivity :
  FlutterActivity()`): la guarda estándar de Android — si no somos la raíz de la tarea y nos
  lanzan desde el launcher, la instancia nueva se aparta con `finish()` y deja viva la que ya
  tiene el estado del usuario. `super.onCreate` se llama siempre primero, porque omitirlo
  lanza `SuperNotCalledException`.

  **Protege toda la app, no solo el ticket:** cualquier salida a otra aplicación queda cubierta
  —el compartir de Facturas y el WebView de pago tienen la misma exposición—.

  **NO se tocó `android:taskAffinity=""`** del manifest: es el valor por defecto de la
  plantilla de Flutter y mitiga el ataque de secuestro de tareas *StrandHogg*.

  **Verificación:** `flutter analyze` sin issues, **678 tests en verde**, APK compilado e
  instalado en el dispositivo, navegación normal comprobada (Menú → Pagos Realizados → ticket
  → atrás → atrás → Menú).

  ⚠️ **El fallo exacto NO se logró reproducir.** En las dos pruebas el visor elegido
  (*Internet Visor de PDF*, WPS) abrió **tarea propia (#41)**, escenario en el que el atrás
  siempre funcionó bien. La condición que dispara el bug —actividad ajena apilada en nuestra
  tarea— sí quedó **probada** con el diálogo *Abrir con*. Falta confirmar con la app de visor
  concreta que usó el usuario.

- **Carrusel de Avisos en el Menú Principal (2026-08-20):**

  Contenido informativo tipo nota periodística bajo la lista de pagos y facturas. Cada tarjeta
  abre una hoja inferior con la nota completa.

  **Arquitectura.** Vertical slice aislado: `BannerService` → `BannerRepository`(+`Impl`) →
  `GetBannersUseCase` → `BannerUseCases` → `BannerBloc`. Consume `POST /api/v1/banners` con
  `user_id` en el body y Bearer token, la misma convención que los estados de cuenta. El
  `BannerBloc` se registra en `blocProviders` **sin evento inicial**: lo dispara la propia
  tirilla al montarse, ya dentro del menú, para que los avisos se pidan siempre con la sesión
  iniciada y con el usuario correcto tras un cambio de cuenta.

  **Markdown sin un segundo renderizador.** El cuerpo llega en Markdown y `cuerpo_formato`
  anticipa que puede cambiar. En vez de instalar un renderizador de Markdown aparte, se
  instaló **`markdown` 7.3.1** (Dart puro, sin código nativo, no toca los builds) para
  convertir a HTML y pintar con el `flutter_widget_from_html_core` que la app **ya usaba** en
  Notificaciones: un solo renderizador, un solo estilo, y `cuerpo_formato: "html"` funciona
  sin tocar nada. La conversión vive en `lib/src/core/utils/contenido_a_html.dart`.

  **Trampa cubierta — los `\r\n`.** El backend manda los saltos como `\r\n` y el parser de
  Markdown espera `\n`; con el `\r` de sobra **deja de reconocer listas y encabezados** y la
  nota se vería como un párrafo con guiones y almohadillas sueltas. Se normaliza antes de
  convertir y hay test que lo blinda con el cuerpo real del endpoint.

  **Rediseño con la skill `mobile-design`.** La primera versión (tarjetas en `ListView` libre
  + `Dialog` centrado) se rehízo siguiendo HIG y Material 3:

  | Punto | Antes | Ahora | Motivo |
  | --- | --- | --- | --- |
  | Modal | `Dialog` centrado | **Hoja inferior** con asa de arrastre | Convención en ambas plataformas para contenido largo; ya es lo que hace Notificaciones |
  | Carrusel | scroll libre | **`PageView` con enganche y asomo** | Nunca queda a medio camino; el asomo señala que hay más |
  | Encuadre | alto fijo en píxeles | **relación de aspecto 2:1** (16:9 en la hoja) | El recorte es idéntico en todo dispositivo, no depende del alto de pantalla |
  | Memoria | imagen completa en RAM | **`memCacheWidth`** al ancho real × DPR | Un JPEG de 1200 px pintado a 322 se decodificaba entero |
  | Carga | nada | **esqueleto** que reserva el espacio | Evita el salto de layout y el "se rompió" |
  | Contexto | tirilla suelta | **encabezado "Avisos" + puntos** | Un carrusel sin título en un menú de pagos desconcierta |
  | A11y | ninguna | `Semantics` con etiqueta + `HapticFeedback` | TalkBack/VoiceOver solo anunciaban "imagen" |

  **Dos riesgos de plataforma que motivaron el rediseño** (los levantó el usuario al verlo en
  el dispositivo):

  1. **`SafeArea` no bastaba.** Devuelve **cero** si un widget padre ya consumió el padding, y
     el carrusel habría quedado bajo el *home indicator* de iOS o la barra de gestos de
     Android. Se usa `MediaQuery.viewPaddingOf`, el inset físico real — la misma lección que
     ya estaba aprendida en el sheet de Notificaciones.
  2. **Choque con el gesto *atrás* de Android.** Un carrusel horizontal a sangre, pegado a los
     bordes, se arrastra hacia atrás en vez de pasar de tarjeta en navegación por gestos. Las
     tarjetas llevan 16 dp de margen lateral para librar esa banda.

  **La X del modal se quitó por decisión del usuario:** con el asa de arrastre presente, un
  botón de cerrar encima compite con un gesto que la gente ya conoce. La hoja se cierra
  arrastrando, con el botón atrás o tocando fuera.

  **Verificación:** `flutter analyze` sin issues, **678 tests en verde** (antes 639) y APK
  compilado. Se añadieron `banner_test.dart` (12), `banner_service_test.dart` (9),
  `banner_bloc_test.dart` (8) y `contenido_a_html_test.dart` (10). El auditor de la skill
  `mobile-design` no reporta **ni un hallazgo** sobre los archivos del carrusel.

  **Pendiente de validar en dispositivo:** render en Android e iOS, temas claro y oscuro, y
  que el endpoint responda con la forma acordada (POST con `user_id` en el body).

- **Pagos Realizados: el concepto se partía en dos líneas y la fecha se recortaba (2026-08-20):**

  Reporte del usuario al ver la pantalla en el dispositivo. Eran **tres causas sumadas**, no
  una:

  1. **El layout partía el item en dos columnas.** El botón *Ver ticket* competía por el
     ancho horizontal y dejaba a la columna izquierda tan poco espacio que el concepto se
     iba a dos líneas y la fecha se cortaba con puntos suspensivos. Ahora el contenido se
     apila en **filas de ancho completo**: concepto + monto arriba, fecha + `Pago #N`,
     folio, y por último el chip con el botón del ticket. El concepto se lleva todo el ancho
     sobrante, que es lo que le permite caber en una línea.
  2. **La fecha traía la hora.** El backend manda `fecha_de_pago` como `'17-08-2026
     10:01:01'`; ese texto no cabía nunca. Nuevo getter `fechaDePagoCorta` que se queda con
     la fecha. El dato completo sigue en `fechaDePago` y en el ticket.
  3. **La descripción llegaba con espacios dobles y sobrantes:**
     `'REINSCRIPCION SECUNDARIA  26 / 27  '`. Esos espacios se comían ancho real.
     `descripcionAbreviada` ahora los colapsa. Como el getter lo comparten **las tres
     pantallas** (pendientes, carrito y realizados), la limpieza las mejora a todas; ningún
     test existente cambió de expectativa porque todos usaban entradas de un solo espacio.

  Se dejó `maxLines: 2` en el concepto como red de seguridad para pantallas muy angostas o
  con el tamaño de fuente del sistema aumentado.

  **Verificación:** `flutter analyze` sin issues y **639 tests en verde** (antes 635). Se
  añadieron 3 casos de `fechaDePagoCorta` y uno de `descripcionAbreviada` con la cadena real
  del backend. **Falta confirmarlo a ojo en el dispositivo.**

- **`open_filex`: el ticket ahora sí se abre en Android (2026-08-20):**

  Con solo `share_plus` el ticket quedaba a medias en Android. Su hoja es un `ACTION_SEND`:
  lista apps que **reciben** el archivo (Drive, Gmail, WhatsApp), no necesariamente una que
  lo **abra**. Un usuario sin lector de PDF registrado para recibir tocaba *Ver ticket* y no
  podía verlo. En iOS no se notaba porque la hoja trae previsualización, *Marcar* y *Copiar
  a Libros*.

  Se instaló **`open_filex` 4.7.0** (autorizado por el usuario): lanza un `ACTION_VIEW` en
  Android y el preview de `UIDocumentInteractionController` en iOS. El botón principal pasó
  a ser *Abrir ticket* y *Compartir* quedó como acción secundaria; **si no hay ninguna app
  capaz de abrir el PDF, se cae solo a la hoja de compartir**, así que nunca se llega a un
  callejón sin salida.

  **Trampa evitada — permisos de galería en una app de pagos.** El manifest de `open_filex`
  declara `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` y
  `READ_MEDIA_AUDIO`, y el merger de Android **los suma a los de la app**: Arjipagos habría
  aparecido en Play Store pidiendo acceso a fotos y video. No hacen ninguna falta: el ticket
  se abre desde la caché interna (`getTemporaryDirectory()`), ruta para la que el plugin ni
  siquiera evalúa permisos (`pathRequiresPermission()` devuelve false dentro de `dataDir`).
  Se neutralizaron con `tools:node="remove"` en `AndroidManifest.xml`.

  **Verificado con aapt2** sobre el APK compilado: los permisos son exactamente los mismos
  que antes de instalar el plugin —INTERNET, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS,
  RECEIVE_BOOT_COMPLETED, WAKE_LOCK, VIBRATE, C2DM— sin una sola entrada de media. Los dos
  `FileProvider` (el de `open_filex` y el de `share_plus`) conviven con authorities
  distintas, sin colisión.

  **Pendiente en la Mac:** correr `pod install` para que el pod de `open_filex` entre al
  proyecto iOS. Los blindajes del Podfile se reaplican solos, no hay que tocar nada.

- **Dos fallos de plataforma corregidos: `localhost` y el crash de iPad (2026-08-20):**

  **1. `ticket_url` con `localhost` era inalcanzable en casi todo el parque.** El backend de
  desarrollo firma sus URLs absolutas con `http://localhost:8000`, un host que solo resuelve
  dentro de la PC que corre el servidor. Desde el emulador de Android hay que pegarle a
  `10.0.2.2` y desde un teléfono físico —Android o iPhone— a la IP de la red local. **Solo
  el simulador de iOS comparte la red del host**, así que el fallo pasaba inadvertido justo
  en la plataforma donde se probaba en la Mac.

  Se añadió `ApiConfig.repararUrlDelBackend(url)`: conserva ruta y query, y cambia el host
  por el que corresponde a la plataforma. **Una URL con host real se devuelve intacta**, de
  modo que en producción es un no-op y nunca puede redirigir una petición a otro servidor
  (hay test que lo blinda con la URL de Adquira). `TicketService` la aplica antes de pedir
  el PDF.

  **2. `share_plus` tronaba la app en iPad.** La hoja de compartir es un popover y iOS exige
  `sharePositionOrigin`, el rectángulo del que sale; sin él la app crashea al abrirla. La
  app es de iPhone, pero un iPad puede correrla. Se corrigió en la pantalla del ticket y
  también en `factura_item_widget.dart`, que arrastraba el mismo bug. En facturas el
  rectángulo se calcula **antes de la descarga**, no después: hacerlo tras el `await` usaba
  el `BuildContext` cruzando un async gap y el analyzer lo marcaba.

  **Verificación:** `flutter analyze` sin issues y **635 tests en verde** (antes 625). Se
  añadió `api_config_test.dart` (8) y dos casos a `ticket_service_test.dart`.

- **Ticket de pago: se descarga con token en vez de abrirse en WebView (2026-08-20):**

  Cierra el flujo que quedó a medias en la sesión anterior. `TicketWebViewPage` **se
  retiró**: el WebView de Android **no renderiza PDFs**, así que el ticket habría salido
  en blanco en la mitad del parque de dispositivos (en iOS, WKWebView sí lo muestra). El
  archivo se respaldó, no se borró.

  **Flujo nuevo.** `TicketPage` (ruta `ticket`, antes `ticket_webview`) descarga el PDF con
  el Bearer token, lo escribe en la carpeta temporal y lo entrega al sistema con
  `share_plus`, que ofrece el visor de PDF del dispositivo además de guardar y compartir.
  Se entrega solo una vez y `yaCompartido` impide que la hoja se reabra sola al volver de
  ella; el botón *Compartir o abrir* la vuelve a lanzar **sin descargar de nuevo**.

  **Arquitectura.** Vertical slice completo: `TicketService` → `TicketRepository`(+`Impl`,
  que encadena servicio y `TicketArchivoStorage`) → `DescargarTicketUseCase` →
  `TicketUseCases` → `TicketBloc`. Registrado en `AppModule` y regenerado con
  `build_runner`. El `TicketBloc` se provee **local a la pantalla**, no en `blocProviders`:
  depende de los argumentos de ruta y debe morir con ella, para que el siguiente ticket no
  herede el archivo del anterior.

  **Trampa cubierta — el 200 que no es un ticket.** `http` sigue los redirects por su
  cuenta, así que un `302` hacia el login de Laravel llega como un `200` lleno de HTML. Sin
  verificar el `content-type` se habría guardado esa página como si fuera el comprobante.
  El servicio lo rechaza con `ticketSesionExpirada` y hay un test que lo blinda.

  **iPad:** la hoja de compartir es un popover y iOS exige `sharePositionOrigin`; sin eso
  la app truena al abrirla. Se calcula del `RenderBox` del cuerpo de la pantalla.

  **Verificación:** `flutter analyze` sin issues y **625 tests en verde** (antes 604). Se
  añadieron `ticket_service_test.dart` (14) y `ticket_bloc_test.dart` (7), más los mocks
  `MockTicketRepository`, `MockDescargarTicketUseCase` y `createMockTicketUseCases`.

  **Pendiente de validar en dispositivo:** que `ticket_url` efectivamente devuelva un PDF
  (la ruta es `/api/v1/tickets/{uuid}/print`, no verificada contra el backend real). Si
  devolviera HTML, el servicio responderá "sesión expirada" y habría que ajustar el
  content-type esperado. Falta también probar el render en Android e iOS, temas claro y
  oscuro.

  **Nota (sin cambios aplicados):** `factura_item_widget.dart:185` comparte sin
  `sharePositionOrigin` y hace el HTTP dentro del widget. Es el mismo riesgo de iPad, pero
  queda fuera de este alcance.

- **Pagos divididos en Pendientes y Realizados (2026-08-20):**

  El menú principal pasa de un item `Pagos` a dos: **Pagos Pendientes** (ruta `edo_cta`, sin un solo cambio en su flujo hasta el carrito y Adquira) y **Pagos Realizados** (ruta nueva `edo_cta_pagados`). Se eligió dividir en el menú en lugar de meter pestañas en la pantalla actual precisamente para no tocar `EdoCtaPage`, su `TotalSeleccionadoBar` ni el paso al carrito.

  **Pantalla nueva (solo lectura).** Consume `POST /api/v1/alumno/estado-de-cuenta-pagados/` con `user_id` en el body y Bearer token, igual que el de pendientes. Agrupa los pagos por alumno y muestra descripción, **fecha de pago**, **folio del ticket**, monto y número de pago, con el chip en verde. No hay checkbox, ni barra de total, ni carrito: los pagos ya están liquidados. Cada pago con ticket abre `TicketWebViewPage` (ruta `ticket_webview`), un WebView interno que manda el Bearer token en los headers — la URL vive bajo `/api/v1`, que en esta app siempre va autenticada; si el endpoint fuese público, el header sobrante es inofensivo.

  **Arquitectura.** Vertical slice completo y aislado: `EdoCtaPagadosService` → `EdoCtaPagadosRepository`(+`Impl`) → `GetEstadosDeCuentaPagadosUseCase` → `EdoCtaPagadosUseCases` → `EdoCtaPagadosBloc`. El agrupador de casos de uso se dejó **separado** de `EdoCtaUseCases` a propósito, para que el contrato del flujo de pago no cambiara y no hubiera que tocar `CarritoBloc`, `EdoCtaListBloc` ni sus tests. Registrado en `AppModule` con `@injectable` y regenerado con `build_runner`.

  **Trampa evitada — el enum de estado.** La respuesta trae `estadoPago: "Pagado"`, valor que `estadoPagoValues` no conocía. Como `EstadoDeCuenta.fromJson` resuelve con `?? EstadoPago.pendiente`, **todos los pagos realizados se habrían pintado como "Pendiente" sin lanzar ningún error**. Se añadió `EstadoPago.pagado` y `EstadoPagoChip` se reescribió con `switch` para cubrir los tres estados (pendiente/vencido sin cambios de comportamiento).

  **Campos nuevos en `EstadoDeCuenta`:** `fechaDePago`, `ticketFolio`, `ticketUrl` y el getter `tieneTicket`, todos **opcionales con default `''`** porque el endpoint de pendientes no los envía. Clave: `toJson()` solo emite esas tres claves cuando tienen valor, de lo contrario los tests de ida y vuelta (`fromJson`/`toJson` inversas) del flujo de pendientes habrían roto. Por decisión del usuario NO se parsean `ticket_uuid`, `deuda_anterior`, `pagados_desde` ni `pagados_hasta`: nada de campos muertos.

  **Detalles reales de la respuesta que se contemplaron:** `fecha_vencimiento` puede llegar en `null`; `factura_pdf` / `factura_xml` no vienen; `grupo` llega vacío (por eso `AlumnoPagadoCard` cae a mostrar la cantidad de pagos como subtítulo). En dev el backend devuelve `ticket_url` con `http://localhost:8000`, inservible desde el teléfono; en producción llega bien formada con `https://arjipagos.moriah.mx`, que es la que se usa tal cual.

  **Verificación:** `flutter analyze` sin issues y **604 tests en verde** (antes 582). Se añadieron `estado_de_cuenta_pagado_test.dart`, `edo_cta_pagados_service_test.dart` y `edo_cta_pagados_bloc_test.dart`, más los helpers `TestPagoRealizado` y `createMockEdoCtaPagadosUseCases`. Se actualizó el test del menú, que ahora exige tres items y valida que cada uno apunte a su ruta. El test guardián de fugas de excepciones cubre los archivos nuevos automáticamente (escanea las carpetas de forma recursiva).

  **Pendiente de validar en dispositivo:** el render de la pantalla y del ticket en Android e iOS, temas claro y oscuro.

- **`Alumno`: campos `familia_id` y `familia` (2026-08-20):**

  Se agregaron al modelo `lib/src/domain/models/Alumno.dart` los campos `familiaId` (`int`, JSON `familia_id`) y `familia` (`String`, JSON `familia`), siguiendo el estilo del resto de la clase: parámetros `required` en el constructor y valores por defecto tolerantes en `fromJson` (`?? 0` y `?.toString() ?? ''`), de modo que un JSON sin esas claves no rompe el parseo. Ambos se serializan en `toJson()`.

  **Tests actualizados** (los constructores usan parámetros `required`, así que todos los sitios de construcción se ajustaron): `test/helpers/test_data.dart` (objetos `activo`/`baja` y sus fixtures `activoJson`/`bajaJson` — estos últimos son obligatorios porque `alumno_test.dart` valida que `fromJson`/`toJson` sean inversas), `carrito_referencia_test.dart`, `carrito_bloc_test.dart`, `edo_cta_list_bloc_test.dart` y `edo_cta_referencia_test.dart`. En `alumno_test.dart` se añadieron aserciones para los dos campos nuevos en `fromJson` y `toJson`, más un test de valores por defecto cuando el JSON no trae la familia.

  **Verificación:** `flutter analyze` sin issues y **582 tests en verde** (antes 579).

  **Nota de diagnóstico (sin cambios aplicados, por decisión del usuario):** en la misma revisión se detectó que `apPaterno`, `apMaterno` y `grupoId` no se leen en ningún punto de `lib/` fuera del propio modelo, y que `AlumnoResponseToJson()` (`lib/src/domain/models/AlumnoResponse.dart:8`) no se invoca en ninguna parte. Se decidió **no eliminarlos**.

- **Verificación iOS del edge-to-edge + Flutter 3.44.8 en la Mac (2026-07-30):**

  Cierra la verificación que quedó pendiente en `f38540e`, cuyo mensaje solo acreditaba Android (`analyze`, 569 tests, APK/AAB en dispositivo físico). Los cambios de padding de ese commit **sí afectan a iOS**, porque `MediaQuery.viewPaddingOf` y `SafeArea` son multiplataforma.

  **Flutter SDK en la Mac:** `3.44.6` → **`3.44.8`** (Dart 3.12.2, sin cambio). Existía una divergencia real: las dependencias y Android se validaron bajo 3.44.8 en la máquina Linux (`/home/carlos/snap/flutter/common/flutter`), pero el `Runner.app` de producción se compilaba aquí con 3.44.6. El `flutter upgrade` falló primero por el mismo motivo documentado en Linux — el `pubspec.lock` **del propio SDK** con una línea autogenerada (`objective_c`). Se respaldó y se resolvió con `--force`. `pubspec.yaml` y `pubspec.lock` del proyecto **intactos**: el árbol quedó limpio.

  **Verificación:** `flutter clean` → `pub get` → `pod install` → `build_ios.sh` con **exit 0**, `Runner.app` de 55.4 MB. Validado visualmente en **iPhone 17 Pro Max** (iOS 26.5.2): Home, Menú principal, Facturas, Notificaciones y los dos WebViews (Aviso de privacidad y pasarela de pago) se ven correctos.

  **Cobertura en otros tamaños de iPhone — analizada, no requiere más pruebas:** el inset no es un valor fijo sino el que reporta el sistema, así que solo hay dos clases de dispositivo. (1) Con *home indicator* (X → 17, cualquier tamaño): el inset inferior en vertical es **34pt constante**, no depende del tamaño de pantalla; validar el 17 Pro Max cubre a todos. (2) Con botón home (SE 2ª/3ª, 8, 7, 6s — dentro del target `IPHONEOS_DEPLOYMENT_TARGET = 15.0`): el inset es **0** y cada expresión degrada exactamente al valor anterior (`16+0`=`all(16)`, `8+0`=`symmetric(vertical:8)`, `24+0`=`bottom:24`, y el de Notificaciones queda en no-op), por lo que los cambios son **inertes** ahí y no pueden causar regresión. El caso donde el inset variaría (landscape, 21pt) está descartado: la app es solo vertical, forzado en `Info.plist` (`UISupportedInterfaceOrientations`) y en `lib/main.dart:28` (`SystemChrome.setPreferredOrientations`).

- **`/Volumes/T7` es exFAT — crash intermitente de `flutter build ios` (2026-07-30):**

  **Síntoma:** `flutter build ios` aborta con `PathNotFoundException: Deletion failed, path = 'build/ios/Release-iphoneos'` en `flutter_tools/src/ios/mac.dart:327` (`buildXcodeProject`). El tool intenta borrar un directorio que no existe. De 3 builds ejecutados, 1 crasheó.

  **Causa:** el volumen de trabajo es **exFAT** (`diskutil info` → `File System Personality: ExFAT`; el *link count* de los directorios es 1, cuando APFS/HFS+ dan ≥2). exFAT no maneja igual ciertas operaciones de borrado POSIX. El mismo síntoma benigno aparece en `flutter clean` (`Failed to remove build`).

  **Mitigación comprobada:** pre-crear el directorio antes del build, para que el `deleteSync` encuentre algo que borrar. Con esto el crash no reapareció:

  ```bash
  mkdir -p build/ios/Release-iphoneos && ./scripts/build_ios.sh
  ```

  **REGLA IMPORTANTE — `pod install` antes de abrir Xcode si un build por CLI falla a medias:** el crash ocurre **después** de que Flutter regenere `Package.swift` en `.iOS("13.0")` y **antes** de que `build_ios.sh` restaure los valores críticos. Tras el crash el proyecto quedó con `Package.swift` en **13.0** y `LastUpgradeCheck`/`LastUpgradeVersion` en **1510**. En ese estado, un **Archive habría fallado** con el error de Firebase *"requires minimum platform version 15.0"*. Se reparó con `git checkout` de los dos archivos de Xcode y un `pod install` (cuyo `post_install` devolvió `Package.swift` a 15.0). El Archive desde Xcode **no** pasa por ese código de `mac.dart`, así que el bug solo se manifiesta usando el CLI.

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

### Sesión 2026-08-13 — Incidente: `HandshakeException` en login (cadena TLS incompleta)

Fallo reportado con la captura `assets/errores/error_de_ingreso.jpeg`. **Causa en el
servidor, no en la app.** No se modificó código del proyecto.

**Error mostrado al usuario**

```
HandshakeException: Handshake error in client (OS Error:
CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate(handshake.cc:298))
```

**Diagnóstico**

`arjipagos.moriah.mx:443` servía **solo el certificado hoja**, sin el intermedio
`ZeroSSL RSA DV SSL CA 2`. El vhost apuntaba a `cert.pem` en vez de `fullchain.pem`.
Se originó en la renovación del **31 de julio de 2026** (fecha `notBefore` del
certificado), así que estuvo roto ~2 semanas.

| Comprobación                          | Antes                          | Después          |
| ------------------------------------- | ------------------------------ | ---------------- |
| Certificados en la cadena             | 1 (solo hoja)                  | 2 (hoja + inter) |
| `Verify return code`                  | 20 / 21                        | **0 (ok)**       |
| Consistencia (8 handshakes)           | 8/8 fallando                   | 8/8 ok           |
| TLS 1.2 y TLS 1.3                     | Ambos fallando                 | Ambos ok         |
| `GET https://` validación estricta    | Fallaba                        | HTTP 200         |

**Por qué "no le salía a todos" — no era intermitente**

El fallo era determinista; lo que variaba era **quién veía el diálogo**:

- **Sin sesión guardada** (instalación nueva, cerró sesión) → cae en Login → primera
  llamada de red → diálogo rojo. Bloqueados.
- **Con sesión guardada** → el splash lee la sesión de `secureStorage`
  (`AuthRepositoryImpl.dart:47`, **sin red**) → entra directo a Home y ninguna
  pantalla carga datos. Reportaban "a mí sí me abre", pero también estaban rotos.

**Por qué falla en iOS igual que en Android**

Flutter **no** usa el stack TLS de Apple: `package:http` → `dart:io` → **BoringSSL** en
ambas plataformas. BoringSSL no hace *AIA fetching* (no descarga el intermedio
faltante), a diferencia de Chrome/Safari. Por eso **el navegador mostraba el sitio
bien mientras la app fallaba** — probar desde el navegador NO sirve para validar esto.

**Solución aplicada (servidor)**

```nginx
ssl_certificate  /etc/letsencrypt/live/arjipagos.moriah.mx/fullchain.pem;  # NO cert.pem
```

Sin release ni actualización de la app: ambos grupos de usuarios se recuperaron solos.

**Comando de verificación — única prueba válida**

```bash
echo | openssl s_client -connect arjipagos.moriah.mx:443 \
  -servername arjipagos.moriah.mx 2>/dev/null | grep "Verify return code"
# 0 (ok) = correcto   |   20 o 21 = la app está caída
```

**⚠️ Riesgo de reaparición: el certificado expira el 29 de octubre de 2026.** Si la
renovación vuelve a copiar `cert.pem`, la app se rompe igual. Revisar el
`--deploy-hook` (certbot) o `--reloadcmd` (acme.sh) antes de esa fecha.

**Debilidades de la app que dejó a la vista** (no corregidas, ver Próximas tareas)

1. `AuthService.dart:76` — `Error(e.toString())` vuelca la excepción cruda al
   `AlertDialog`. Aplica también a los demás Services.
2. El splash no valida contra el servidor, así que con el backend caído deja entrar a
   pantallas huecas en lugar de avisar.

---

### Sesión 2026-08-13 (b) — Mensajes de error legibles en los Services

Corrección derivada del incidente TLS de la sesión anterior: los Services volcaban la
excepción cruda al usuario vía `Error(e.toString())`.

**Problema**

15 `return Error(e.toString())` repartidos en los 7 Services. Cualquier excepción no
prevista llegaba literal al `AlertDialog` (`HandshakeException: ... handshake.cc:298`).

**Solución — mapeador centralizado**

Nuevo `lib/src/core/utils/network_error_mapper.dart` con `mensajeErrorRed(Object)`,
que traduce la excepción a un mensaje de `AppStrings`:

| Excepción                          | Mensaje al usuario           |
| ---------------------------------- | ---------------------------- |
| `TlsException` (y sus subclases `HandshakeException`, `CertificateException`) | `errorConexionSegura` |
| `SocketException`                  | `errorConnection`            |
| `TimeoutException`                 | `errorTimeout`               |
| `http.ClientException`             | `errorConnection`            |
| `FormatException`                  | `errorRespuestaInvalida`     |
| Cualquier otra                     | `errorUnexpected`            |

El detalle técnico sigue registrándose con `AppLogger`, que es donde corresponde.

**Nuevos strings en `AppStrings`:** `errorConexionSegura`, `errorRespuestaInvalida`,
`errorServidorHttp(int)`, `errorTokenFcmInvalido`, `errorDatosEliminarToken`
(estos dos últimos estaban hardcodeados en `FcmService`).

**Archivos tocados:** los 7 Services (`Auth`, `Pago`, `Home`, `EdoCta`, `Factura`,
`Notificacion`, `Fcm`), `app_strings.dart`, más el util y su test nuevos.

**Decisión de alcance:** los bloques `on TimeoutException` / `on SocketException` ya
existentes NO se tocaron — eran correctos y están cubiertos por tests. El cambio se
limitó al `catch (e)` genérico, que era el único que filtraba.

**Test guardián contra regresiones**

`test/unit/services/services_no_filtran_excepciones_test.dart` escanea el fuente de los
Services y falla si reaparece `Error(<algo>.toString())`. Incluye una autocomprobación
del propio regex, para que no se degrade en silencio y deje de detectar. La regla quedó
también escrita en `CLAUDE.md`.

**Lo que encontró el guardián al primer intento**

`PagoService` construía el mensaje con `errorMsg.toString()` sobre el cuerpo de la
respuesta (líneas 58 y 106). No era una fuga de excepción, pero sí una inconsistencia
real: los demás Services envuelven eso en `ListToString` porque el backend puede
devolver una lista, y `.toString()` la pintaría con corchetes al usuario. Se alineó al
patrón del resto y los textos por defecto pasaron a `AppStrings`
(`errorProcesarPago`, `errorVerificarPago`).

**Verificación:** `flutter analyze` sin issues · `flutter test` **580 tests pasando**
(569 previos + 9 del mapeador + 2 del guardián, ninguno roto).

---

### Sesión 2026-08-13 (c) — Errores legibles en repositorios y BLoCs

Continuación de la sesión (b), que solo había cubierto los Services.

**Corrección de un diagnóstico previo (quedó anotado mal en la sesión del incidente)**

Se había dicho que splash y Home mostraban "pantallas huecas". **No era exacto:**

- `HomePage` **ya** maneja el error correctamente: pinta `HomeErrorWidget` con botón de
  reintentar, y lo evalúa *antes* del estado vacío.
- `SplashBloc._onError` navega a **login** (no deja la app colgada). El valor
  `SplashNavigationState.error` del enum **no lo emite nadie** — es código muerto.

**El problema real era otro:** el error que Home sí mostraba era el texto crudo de la
excepción, porque el mensaje se construía interpolándola.

**Alcance corregido — 18 sitios en 11 archivos**

| Capa | Archivos | Sitios |
| ---- | -------- | ------ |
| Repositorios | `Home`, `Notificacion`, `Factura`, `EdoCta` | 7 |
| BLoCs | `Home`, `Splash`, `Notificacion`, `Factura`, `EdoCtaList`, `MenuPrincipal` | 11 |

Todos pasaron de `'texto: $e'` / `e.toString()` a `mensajeErrorRed(e)`, añadiendo
`AppLogger.error(...)` donde no había log, para no perder el detalle técnico.

**Guardián ampliado**

El test ahora escanea también `lib/src/data/repository` y `lib/src/presentation/pages`,
y detecta un segundo patrón: la **interpolación** `'…: $e'`, que fue justo la que se le
escapó en su primera versión. Sabe seguir llamadas `AppLogger` multilínea para no marcar
como fuga la continuación de un log.

**Test actualizado:** `menu_principal_bloc_test` asertaba
`startsWith('Error al cargar datos:')`; ahora asierta `AppStrings.errorUnexpected`, que
además documenta que no se filtra detalle técnico.

**Verificación:** `flutter analyze` sin issues · `flutter test` **580 tests pasando**.

**Pendiente de decisión:** `SplashNavigationState.error` sigue sin usarse. No se borró
(regla de no eliminar sin preguntar).

---

### Sesión 2026-08-13 (d) — Upgrade a Flutter 3.47.0 y release 1.0.23+32

**Upgrade del SDK: 3.44.8 → 3.47.0** (salto de 3 versiones menores, no un parche)

`flutter upgrade` abortó por cambios locales en el checkout del SDK. Se inspeccionó
antes de forzar: era **solo `pubspec.lock` del propio SDK** (generado por el tooling,
no un parche deliberado), así que `--force` fue seguro.

**Cambio automático aceptado:** Flutter 3.47 añadió a `analysis_options.yaml` la
exclusión de `android/ios/web/windows/macos/linux` del análisis. Es el comportamiento
estándar de esta versión.

**Dependencias:** `flutter pub upgrade` movió 25 paquetes dentro de sus constraints.
Destacan `webview_flutter_android` 4.13.0 → 4.14.0, `win32` 6.3.0 → 6.4.0 y
**`build_daemon` 4.1.3 → 4.1.5**, que resuelve el aviso de *versión retractada*.
`injectable_generator` sigue bloqueado en 3.0.2 (ver sección propia — no forzar).

**Verificación tras cada paso (analyze + 580 tests, dos veces: post-SDK y post-deps)**

| Comprobación | Resultado |
| ------------ | --------- |
| `flutter analyze` | Sin issues |
| `flutter test` | **580 pasando** |
| `flutter build apk --release` | OK — 90 MB |
| `flutter build appbundle --release` | OK — 88 MB |
| APK: `versionCode` / `versionName` | **32 / 1.0.23** ✅ |
| APK es AOT real | 3 × `libapp.so`, 0 × `kernel_blob.bin` ✅ |
| `ApiConfig.isProduction` | `true` ✅ |

**iOS — anclas verificadas intactas tras el upgrade** (comprobación estática):
`LastUpgradeCheck = 2630`, `LastUpgradeVersion = "2630"`, `LaunchAction` y
`ArchiveAction` ambas en `Release`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0` en las 3
configuraciones, y los bloques del `Podfile` presentes.

⚠️ **iOS no se compiló** — no es posible desde este entorno Linux. Tras un salto de SDK
de esta magnitud, en la Mac hay que correr obligatoriamente
`flutter clean && flutter pub get && cd ios && pod install` **antes** del Archive, para
regenerar el `Package.swift` efímero y reaplicar el forzado de plataforma 15.0.

**Nota sobre `dart format`:** el proyecto no sigue su estilo (152 de 235 archivos
diferirían). Es preexistente y transversal, no se reformateó: sería un diff enorme sin
relación con este trabajo. El gate real del proyecto es `flutter analyze`, que pasa
limpio.

---

### Sesión 2026-08-13 (e) — Edge-to-edge: el arreglo de julio estaba incompleto

Play Console volvió a marcar *"Es posible que la vista de extremo a extremo no funcione
para todos los usuarios"* en el build **31 (1.0.22)**.

**Causa: hay CUATRO `styles.xml`, no dos.** El arreglo del 2026-07-30 solo limpió las
dos primeras variantes:

| Archivo | `windowDrawsSystemBarBackgrounds` |
| ------- | --------------------------------- |
| `values/styles.xml` | eliminado 2026-07-30 |
| `values-night/styles.xml` | eliminado 2026-07-30 |
| `values-v31/styles.xml` | **seguía presente** → eliminado hoy |
| `values-night-v31/styles.xml` | **seguía presente** → eliminado hoy |

Las variantes `-v31` **tienen prioridad en Android 12+**, así que en cualquier
dispositivo moderno mandaban ellas: limpiar solo `values/` no servía de nada. Las
genera `flutter_native_splash:create` (splash de Android 12), que es la razón por la
que se pasaron por alto. Se añadió un comentario en ambas advirtiendo que ese comando
las regenera y vuelve a insertar el atributo.

`android:windowFullscreen` se mantiene: es intencional, viene de `fullscreen: true` en
la config de `flutter_native_splash` del `pubspec.yaml`.

**Verificación en el binario** (leer el fuente no basta, y grepear `resources.pb` da
falsos positivos porque lista atributos de librerías):

```bash
aapt2 dump resources build/app/outputs/flutter-apk/app-release.apk \
  | sed -n '/style\/LaunchTheme/,/style\/NormalTheme/p'
```

Las variantes v31 pasaron de **6 a 5 atributos**: desapareció `0x01010450`
(`windowDrawsSystemBarBackgrounds`) y se conservó `0x0101020d` (`windowFullscreen`).
El AAB comprobado por separado: **0 ocurrencias** en sus styles v31.

**Verificación:** `flutter analyze` sin issues · `flutter test` **580 pasando** ·
APK y AAB recompilados con la corrección.

⚠️ **El aviso solo se confirmará como resuelto al subir el build 32.** El que Play
señala es el 31, que se generó antes de cualquiera de los dos arreglos.

✅ **Actualización 2026-08-13:** el AAB del build 32 ya se subió a Play Console sin
errores. Falta confirmar en la consola que el aviso de edge-to-edge desaparece: Play
lo reevalúa cuando termina de procesar el bundle, no en el momento de la subida.

---

### Sesión 2026-08-13 (f) — Archive iOS 1.0.23+32 subido sin incidencias

Primer Archive/Distribute a App Store Connect que sale **limpio a la primera**, sin
ninguno de los tres errores que históricamente costaban horas. Se deja registrado
porque confirma que los blindajes del `Podfile` están APROBADOS y FUNCIONANDO.

**Limpieza previa ejecutada** (la secuencia obligatoria de `CLAUDE.md`):

```bash
flutter clean && flutter pub get && cd ios && pod install && ./scripts/build_ios.sh
```

**Los tres blindajes se aplicaron solos**, sin un solo paso manual. Salida literal
del `pod install`:

```
✔ Run Script 'Generate dSYM for objective_c native asset' configurado en Runner
✔ LastUpgradeCheck fijado en 2630 (project.pbxproj)
```

| Config verificada tras el build | Valor | Error que evita |
| ------------------------------- | ----- | --------------- |
| `LastUpgradeCheck` (project.pbxproj) | `2630` | Flutter lo degrada a 1510 en cada build |
| `LastUpgradeVersion` (Runner.xcscheme) | `"2630"` | Mismo motivo |
| `Package.swift` (SPM efímero) | `.iOS("15.0")` | Firebase exige 15.0; Flutter regenera con 13.0 |
| Run Script dSYM `objective_c` | presente | "Missing dSYM" al subir a App Store Connect |
| `LaunchAction` / `ArchiveAction` | `Release` | El Archive usa la ArchiveAction, no la Launch |
| `ApiConfig.isProduction` | `true` | Apuntar a backend local en producción |

**Versiones nuevas que entraron con la limpieza:**

- **Firebase iOS SDK 12.15.0 → 12.17.0** (`firebase-ios-sdk` y `GoogleAppMeasurement`,
  vía SPM). Quedó reflejado en los dos `Package.resolved` versionados.
- Checksum del pod `Flutter` actualizado a Flutter 3.47.0 en `ios/Podfile.lock`.

**Datos del Archive:** bundle `com.example.arjipagos` (el publicado en App Store — NO
cambiar, ver regla en memoria), versión `1.0.23+32`, firma automática con el team
`CF6C8Z3W44`, `Runner.app` de 55.7 MB compilado en 186 s.

**Verificación:** `flutter analyze` sin issues · `flutter test` **580 pasando** ·
Archive subido a App Store Connect sin errores ni warnings de validación.

**El build 32 quedó subido a las DOS tiendas el mismo día**, ambas sin incidencias:
App Store Connect (Archive desde Xcode) y Google Play Console (AAB desde
`build/app/outputs/bundle/release/app-release.aab`). Es el primer release del
proyecto que sale limpio a la primera en ambas plataformas.

**Nota sobre dependencias Dart:** 11 paquetes tienen versiones nuevas bloqueadas por
constraints (`analyzer` 13.3.0→14.1.0, `flutter_secure_storage` 10.3.1→11.0.0,
`package_config` 2.2.0→3.0.0, entre otros). NO se subieron: es un bump de
dependencias, no parte de una limpieza. Queda pendiente evaluarlo aparte.

---

## Sesión 2026-08-21 — Rediseño del renglón de pago + Avisos en el lienzo

**Artefacto de diseño:** el lienzo `Renglón de pago Arjipagos` ganó dos artboards
del módulo de Avisos (`Banners.dc.html` — la tirilla dentro del Menú Principal — y
`BannersEstados.dc.html` — con portada, título de dos líneas, cargando, imagen no
disponible, un solo aviso y sin avisos). Misma URL de siempre.

**Código.** Se aplicó el rediseño a Estados de Cuenta y Carrito:

- **`ConceptoEscalonado`** (nuevo, `lib/src/presentation/widgets/`): el concepto se
  queda con la línea entera y baja por la rampa del tema (`bodyLarge` 16 →
  `bodyMedium` 14 → `bodySmall` 12) hasta caber en UNA línea. Se mide con
  `TextPainter` —el mismo motor que luego lo pinta— respetando la escala de fuente
  del sistema. Si ni el escalón chico alcanza, pasa a dos líneas: nunca se recorta.
- **`pago_item.dart`** reescrito: barra de color en el canto izquierdo + tinte de
  fondo + píldora, para que el estado se lea sin buscar la casilla. El pago
  bloqueado por orden muestra **candado** en vez de casilla apagada, y se atenúa al
  55 %. Importe con cifras tabulares. El tinte va en el `Material` y no en un
  `Container` encima, así la onda del toque se pinta sobre el color.
- **`estado_pago_chip.dart`**: píldora con **punto de color** además del texto
  (refuerzo, no sustituto: el estado se sigue leyendo escrito). Radio 8, padding
  `fromLTRB(8,3,10,3)`. Nuevo parámetro `sobreTinte`: sobre un renglón teñido usa
  `surface` para despegarse; sobre uno normal, `surfaceContainerHighest`.
- **`carrito_pago_item.dart`**: mismo concepto escalonado, cifras tabulares y
  candado cuando el pago no se puede quitar.

**Todo sale del `ColorScheme`**, sin un solo hex escrito a mano: `secondaryContainer`
para el tinte de selección, `errorContainer` para el vencido y los tokens
`on…Container` para el importe encima de cada uno. Claro y oscuro se resuelven solos.

**Cambio de criterio que conviene tener presente:** el rediseño **revierte** la regla
anterior de "nunca encoger el concepto por item". Antes todos los conceptos se
pintaban al mismo tamaño y podían ocupar dos líneas; ahora cada renglón elige su
escalón. Los dos tests que fijaban la regla vieja se reescribieron para fijar la
nueva —incluyendo que ningún tamaño se invente fuera de la rampa 16/14/12—.

### Regresión introducida y corregida el mismo día — la lista no se pintaba

El primer intento puso la barra de estado como hermano dentro de un
`Row(crossAxisAlignment: stretch)`. En el Oppo **Pagos Pendientes salía vacío**:
`PagosList` mete los renglones en un `Column` dentro de un scroll, así que el alto
les llega sin acotar, y `stretch` lo convierte en `BoxConstraints(h=Infinity)` — el
renglón no se pinta.

**Corrección:** la barra pasó a ser un **borde izquierdo** (`Border(left: …)`) del
propio renglón. No hay nada que estirar ni que medir, y funciona con cualquier alto.

**Por qué no lo atrapó la suite:** el test montaba `PagoItem` suelto bajo el
`Scaffold`, que le da el alto de la pantalla —acotado— y esconde justo esta clase de
fallo. Se agregó el test `dentro de un Column con alto sin acotar, como en la lista
real`, que reproduce el contexto de verdad y comprueba además que el renglón tenga
alto mayor que cero. **Lección: si el widget vive dentro de un scroll, el test tiene
que montarlo dentro de un scroll.**

**Verificación:** `flutter analyze` sin issues · `flutter test` **726 pasando**
(baseline antes de tocar nada: 713) · **comprobado en pantalla** en el Oppo CPH2639:
capturas de Menú Principal y de Pagos Pendientes con los cinco renglones pintados,
barra y tinte en los seleccionados, candado en los bloqueados y cifras alineadas.

### Rediseño de Avisos (Banners) — el texto sale de encima de la foto

El defecto no era de gusto: en el dispositivo el título se cortaba a media frase
("…descuento especial por anual…") y la fecha, en blanco sobre una foto clara, no se
leía. Un degradado más fuerte no lo arregla sin ensuciar media portada.

**La tarjeta se partió en dos:** portada arriba, texto abajo sobre
`surfaceContainerLow`. El contraste deja de depender de la foto y se resuelve solo en
claro y oscuro porque sale del `ColorScheme`. De paso el título se lee aunque la
imagen no cargue, que era justo cuando peor se veía.

- `BannerInfo.fechaPublicacion` y `.esReciente` (nuevos): parsean el `dd-MM-yyyy` del
  backend a mano —`DateTime.parse` reventaría, espera `yyyy-MM-dd`— y marcan el aviso
  como reciente durante 7 días. Sin campo nuevo en el backend. Fecha ilegible o
  futura ⇒ no reciente: mejor no señalar que señalar de más.
- `banner_card.dart`: píldora **"Nuevo"** con punto de color —el mismo lenguaje que el
  chip de estado de los pagos, no un componente inventado— y fecha con cifras
  tabulares.
- `banners_strip.dart`: el alto de la tarjeta ahora es portada **más** bloque de
  texto, y ese bloque se mide con los tamaños del tema y la escala de fuente del
  sistema, no con un número fijo: con la letra grande el título necesita más alto.
- `banners_skeleton.dart`: la silueta repite la anatomía partida, para que el hueco
  prometa lo que después aparece.

**Costo:** la tarjeta pasa de 161 px a ~240 px de alto. Está anotado en el lienzo por
si conviene recortar la portada a 16:9.

### Revisión completa en el Oppo CPH2639

Recorrido pantalla por pantalla, con captura de cada una: Menú Principal, Pagos
Pendientes (claro y oscuro), Carrito, Pagos Realizados, scroll hasta el final de la
lista, diálogo del renglón bloqueado, selección en cascada y fuente del sistema
al 1.6×.

**Dos hallazgos de esa revisión, ajenos al rediseño pero corregidos:**

1. **El total se partía a media cifra.** Con la fuente en grande, la barra inferior
   mostraba `$23,136.0` y en el renglón siguiente un `0` suelto — la peor forma
   posible de enseñar dinero. Pasa a `FittedBox(scaleDown)` con `maxLines: 1`, igual
   que las fechas. Estaba en **las dos** barras: `total_seleccionado_bar.dart` y
   `carrito_total_bar.dart`.
2. **La píldora de Pagos Realizados caía sobre el tinte verde** de su renglón sin
   despegarse. Se le pasó `sobreTinte: true`. Esa pantalla usa el mismo chip y no
   estaba en el alcance inicial: la encontró el rastreo de usos, no la vista.

**Contraste medido** (no a ojo): el importe del renglón seleccionado da **4.6:1** en
oscuro (`#cbb37b` sobre `#564517`) y **4.65:1** en claro (`#756232` sobre `#fae0a4`).
Los dos pasan AA; el oscuro va justo y es el punto más débil del rediseño.

**Verificación final:** `flutter analyze` sin issues · `flutter test` **733 pasando**
(baseline antes de tocar nada: 713).

### Cabecera de usuario compacta — el verdadero comilón de espacio

La cabecera iba en vertical —avatar de radio 36, nombre y email uno bajo otro, con
24 de padding— y se llevaba **~440 px de 1604**, casi un tercio de la pantalla. Con
la tarjeta de aviso ya más alta, al menú no le quedaba sitio y "Facturas" salía
cortado por abajo.

Ahora es horizontal: **avatar a la izquierda, nombre y debajo el email**. Baja a
~165 px, y los tres renglones del menú caben con holgura.

**El nombre nunca pasa de una línea.** Va en `FittedBox(scaleDown)` y no con
`ellipsis`: un nombre largo se encoge hasta caber, pero se lee **entero**. Además la
cabecera conserva siempre el mismo alto, así que el menú no baila según de quién sea
la sesión. El email sí se recorta con puntos suspensivos: es dato de apoyo y
encogerlo más lo dejaría ilegible.

**Nota de recorrido:** antes de esto se probó una tarjeta de aviso compacta y
horizontal para recuperar el alto. Se descartó —el título volvía a cortarse— al
verse que el espacio sobraba en la cabecera, no en los avisos. La tarjeta de aviso se
quedó en la vertical: portada arriba, texto debajo, título completo.

### Release 1.0.24+33

`1.0.23+32` ya estaba publicada en ambas tiendas, así que sube a **1.0.24+33** (regla
1 de versionado). Verificado antes de compilar: `ApiConfig.isProduction = true`,
permisos `INTERNET` y `POST_NOTIFICATIONS` en el manifiesto.

**iOS — no verificable desde aquí.** Este equipo es Linux; el build y el Archive
exigen la Mac. Lo que sí se revisó, que es donde suelen estar los fallos de iOS:
`IPHONEOS_DEPLOYMENT_TARGET = 15.0` en las tres configuraciones y `platform :ios,
'15.0'` en el Podfile · `LastUpgradeCheck = 2630` y `LastUpgradeVersion = "2630"` ·
`LaunchAction` y `ArchiveAction` en `Release` · las guardas de `objective_c`/dSYM
intactas en el Podfile · los plugins nuevos (`pdfx`, `share_plus`, `open_filex`,
`path_provider`) no necesitan `UsageDescription` · `share_plus` ya pasa
`sharePositionOrigin`, sin el cual la hoja de compartir revienta en iPad.

**Dependencias: NO se actualizaron.** El único salto de dependencia directa es
`flutter_secure_storage` 10.3.1 → 11.0.0, un **major**, y ahí viven los tokens de
sesión: romperlo dejaría a los usuarios sin login. La regla del proyecto exige
autorización explícita antes de instalar o actualizar nada. Queda pendiente evaluarlo
fuera de un release.

**`dart format` NO se pasó**: reformatearía 186 de 302 archivos y taparía el trabajo
real bajo un diff ilegible. El proyecto no usa el formateador por defecto como
criterio; `flutter analyze` es el que manda y está limpio.

---

## Sesión 2026-08-21 (b) — Refresco de la tirilla de Avisos por push

El backend avisa de altas, cambios y bajas de banners con un push. Hasta ahora la
app lo ignoraba: `BannerBloc` tenía **un solo evento** y se disparaba **una vez**, en
el `initState` de la tirilla. El push llegaba y la tirilla se quedaba con lo que
cargó al montarse.

**Contrato acordado con el backend** (`data` del mensaje FCM):

| Clave       | Valor                 | Siempre                        |
| ----------- | --------------------- | ------------------------------ |
| `campania`  | `"banner"`            | sí                             |
| `accion`    | `"refrescar_banners"` | sí                             |
| `banner_id` | id en texto           | no (ausente si se eliminó)     |

Se exigen **las dos** claves para actuar: un mensaje de otra campaña que por
casualidad llevara `accion` no debe mover los banners. Hay test que lo cubre.

**Implementado:**

- `BannerRefrescarEvent`: recarga **sin** pasar por el esqueleto. El usuario está
  mirando y no ha pedido nada; verla parpadear a siluetas grises sería un salto
  injustificado. `isLoading` queda solo para la carga inicial.
- `BannerBloc` escucha `onMessage` y `onMessageOpenedApp` con **streams
  inyectables**, igual que `NotificacionBloc`, para poder probarlo sin Firebase real.
  `getInitialMessage` se usa solo para el id, no para recargar.
- `banner_id` → `BannerAbrirDetalleEvent` deja anotada la nota; la tirilla la abre
  con un `BlocListener` y avisa con `BannerDetalleAtendidoEvent` para soltarla. Sin
  ese acuse, cualquier reconstrucción reabriría el modal.
- **Recarga al volver del segundo plano** (`didChangeAppLifecycleState`).

**Discrepancia con la recomendación del backend, y por qué.** Pedían atender también
`onBackgroundMessage`. **No se hizo, y no debe hacerse:** ese handler corre en un
**isolate separado**, sin acceso a este BLoC ni al árbol de widgets, y mientras la app
está en segundo plano no hay tirilla que repintar. Tampoco hay caché local que
invalidar —se verificó: los banners viven solo en memoria, en `BannerState`—, así que
volver a pedir la lista *es* la invalidación.

El caso que les preocupaba —el push llega con el teléfono guardado— lo cubre la
**recarga al reanudar**, que además salva lo que ellos mismos admiten: que iOS
posponga o descarte el push silencioso por bajo consumo. Al volver a la app, la lista
se corrige sola sin depender de que el push llegara.

**Se recarga la lista entera, nunca se parchea la local.** En esto sí de acuerdo con
el backend: el servidor manda el catálogo ya vigente y ya ordenado; aplicar cambios
sueltos por encima es la forma segura de acabar con dos verdades distintas.

**Nota para tests:** `BannerBloc` ya no se puede construir pelado en un test — pediría
`FirebaseMessaging.instance` y moriría con "No Firebase App". Hay que inyectarle los
tres parámetros de FCM, como ya se hacía con `NotificacionBloc`.

**Verificación:** `flutter analyze` sin issues · `flutter test` **740 pasando** (antes
733) · en el Oppo CPH2639 con APK de release: ciclo de segundo plano y vuelta, la
tirilla reaparece intacta, sin parpadeo de esqueleto y sin errores en logcat.

**Pendiente:** probar el push real de banners de punta a punta cuando el backend lo
emita, en Android y en iOS.

---

## Sesión 2026-08-21 (c) — Barrido completo, Flutter 3.47.1 y formateo de importes

Revisión pantalla por pantalla en el Oppo CPH2639 con APK de **release**, cubriendo
lo que faltaba de las sesiones anteriores: Facturas, Notificaciones, el modal de
Aviso y el Ticket. Dos defectos encontrados, los dos ajenos al rediseño y los dos
corregidos.

### 1. Las facturas enseñaban el dinero en crudo

En pantalla salía `Total: 9770.0000` —cuatro decimales, sin símbolo ni separador de
miles— mientras el resto de la app mostraba `$9,770.00`. `Factura.total` llega del
backend como **cadena** con los cuatro decimales del timbrado y se pintaba tal cual.

Al ir a arreglarlo apareció lo de fondo: **tres copias idénticas** de un
`_formatearMonto` privado, en `total_seleccionado_bar`, `carrito_total_bar` y
`carrito_alumno_card`. Con tres copias, corregir el formato en una dejaba las otras
dos mostrando el dinero de otra manera.

Se creó `lib/src/core/utils/formato_monto.dart` con `formatearMonto(double)` y
`formatearMontoTexto(String)` —esta última para el caso de las facturas—, y las tres
copias se sustituyeron por la función compartida. Un texto que no sea número se
devuelve tal cual: mejor enseñar el dato crudo que un `$0.00` que parece una cantidad
real y no lo es. Nueve tests nuevos en `test/unit/utils/formato_monto_test.dart`.

### 2. El título de Notificaciones salía recortado a "Not..."

El botón de texto "Marcar todas leídas" junto al de actualizar no dejaba sitio al
título. Pasa a **icono con tooltip** (`Icons.done_all`): el título se lee completo y
la etiqueta sigue disponible para quien la necesite, lectores de pantalla incluidos.

### Estado "Vencido" verificado por fin en dispositivo

Con otra cuenta —EFREN RAYMUNDO, con pagos vencidos— se pudo ver el camino que hasta
ahora solo estaba verificado por código: barra roja en el canto, tinte
`errorContainer`, píldora "Vencido" con punto, importe en `onErrorContainer` y
candados en los siguientes del mismo ciclo. Responde tal como especifica el lienzo.

**Observación, no bug:** "REINS PRIM 26 / 27" muestra `Vence:` sin fecha porque el
backend la manda vacía.

### Flutter 3.47.0 → 3.47.1

Parche dentro del canal `stable`, autorizado explícitamente. El `flutter upgrade`
pedía `--force` porque el checkout del SDK tenía modificado su propio
`pubspec.lock` —archivo que Flutter regenera solo—; se respaldó antes de forzar.

Tras el cambio de SDK se hizo la limpieza obligatoria (`flutter clean` +
`flutter pub get`). En `pubspec.lock` **solo se movieron transitivas** dentro de las
restricciones existentes (`archive`, `dbus`, `image`, `objective_c` 9.5.0→9.6.0,
`vm_service`, entre otras). **Ninguna dependencia directa cambió.**

**`flutter_secure_storage` sigue en 10.3.1.** El salto a 11.0.0 es un *major* y ahí
viven los tokens de sesión: romperlo dejaría a los usuarios sin login. Se consultó y
la decisión fue no tocarlo. Sigue pendiente de evaluar fuera de una ventana de
release.

**iOS intacto tras el upgrade:** `git status ios/` vacío, `LastUpgradeCheck = 2630`,
`LastUpgradeVersion = "2630"` y las guardas del Podfile en su sitio. Como siempre,
**iOS no se compiló**: este equipo es Linux y el Archive exige la Mac. Conviene
correr `pod install` en la Mac antes del próximo Archive, porque `objective_c` subió
de versión y es justo el pod con la guarda de dSYM.

**Verificación:** `flutter analyze` sin issues · `flutter test` **749 pasando**
(antes 740) · APK de release recompilado con 3.47.1, instalado y recorrido en el
Oppo sin errores en logcat.

---

## Sesión 2026-08-21 (d) — Puesta al día de la Mac y Archive de 1.0.24+33

Sesión hecha ya en la Mac, que venía tres commits atrás. Es la continuación directa
del cierre de la sesión (c): allí se anotó que el Archive exigía pasar por la Mac y
correr `pod install`, porque `objective_c` había subido de versión y es justo el pod
con la guarda de dSYM. Eso es lo que se hizo aquí, y terminó en Archive.

### Sincronización y subida del SDK

`git pull` en fast-forward, tres commits, sin conflictos: llegaron el rediseño del
renglón de pago, el refresco de Avisos por push y el formateo de importes, junto con
la versión **1.0.24+33** en `pubspec.yaml`. Como esa versión aún no está publicada,
la regla de versionado del CLAUDE.md manda usarla tal cual, sin crear una nueva.

La Mac tenía Flutter 3.47.0 mientras el proyecto ya iba en 3.47.1, así que se subió
el SDK también aquí. Volvió a aparecer el tropiezo de la sesión (c): `flutter upgrade`
se niega si el checkout del SDK tiene su propio `pubspec.lock` modificado. **Esta vez
no se usó `--force`**, que borra cualquier cambio local a ciegas; se comprobó que el
diff eran solo transitivas del propio SDK (`jni`, `objective_c`, `google_cloud`) —un
archivo que pub regenera solo— y se descartó con `git checkout -- pubspec.lock`
dentro del SDK. Es la vía a repetir si reaparece.

### Limpieza obligatoria y build iOS

Se corrió la secuencia completa del CLAUDE.md: `flutter clean`, `flutter pub get`,
`pod install` y `./scripts/build_ios.sh`. Build en **exit 0**, `Runner.app` de 56.7 MB.

Las cuatro guardas se verificaron **después** del build, no solo tras el `pod install`:
`flutter build ios` corre su propio `pod install` y degrada los valores antes de que
el script los restaure, así que comprobar en medio no dice nada. Quedaron
`LastUpgradeCheck = 2630`, `LastUpgradeVersion = "2630"`, `Package.swift` en
`.iOS("15.0")` y el Run Script del dSYM de `objective_c` en su sitio.

**`open_filex` no soporta Swift Package Manager**, así que se instaló como pod. De ahí
salieron los dos cambios regenerados de esta sesión: su registro en `Podfile.lock` y
la fase `[CP] Embed Pods Frameworks` en `project.pbxproj`. Son necesarios para que el
plugin funcione en la app firmada.

### Warnings de open_filex silenciados

En el iPhone 17 salieron dos warnings de `OpenFilePlugin.m`: `keyWindow` deprecado
(iOS 13) y una función sin prototipo. Se revisó el código del plugin y el `keyWindow`
vive en la rama `else` de un `@available(iOS 13, *)`, o sea que **nunca se ejecuta**
con el mínimo de iOS 15 del proyecto; el compilador avisa igual porque compila ambas
ramas. `open_filex` 4.7.0 es la última publicada en pub.dev, sin fix upstream.

Se añadió un bloque en el `post_install` siguiendo el patrón que ya usaban otros seis
pods —el de `share_plus` es literalmente por el mismo `keyWindow`—: supresión **por
target**, nunca `inhibit_all_warnings!` global, para no tapar warnings del código
propio ni de pods futuros. Se comprobó que las settings cayeran en las **tres**
configuraciones (Debug, Profile y Release) y en ningún otro target: si solo hubieran
caído en Debug, los warnings habrían reaparecido justo en el Archive.

Queda pendiente revisar si el paquete publica un 4.8.x. Silenciar no arregla: si
Apple llega a retirar `keyWindow`, el aviso ya no estaría para advertirlo.

### Ruido de consola descartado

En el iPhone 17 apareció un volcado largo en la consola de Xcode. Nada venía del
código Dart: LaunchServices (`process may not map database`, -54), WKWebView
(entitlements `web-browser-engine.*`, `RBSServiceErrorDomain`), `sandbox extension`,
`personaAttributesForPersonaType`, y varios `NSLayoutConstraint` de
`_UIButtonBarButton` / `_UIModernBarButton`. Estos últimos son clases **privadas de
UIKit** para botones de barra: una app Flutter no tiene ninguna, pinta todo en una
sola `FlutterView`. Salen del toolbar de la hoja de compartir nativa y del preview de
PDF, un bug viejo de Apple que UIKit resuelve solo rompiendo una constraint. Ninguna
de estas líneas pasa por la validación de App Store Connect, que revisa firma,
entitlements, dSYMs e Info.plist.

**Sin resolver:** el `-10814` (`kLSApplicationNotFoundErr`) sobre
`Library/Caches/ticket_T7729.pdf`. Normalmente es ruido del prefetch de metadatos de
la hoja de compartir, y `ticket_body.dart` ya cae a `_compartir` si `OpenFilex` no
devuelve `done`. Pero el log no distingue "el visor abrió bien" de "se fue por el
respaldo": las dos rutas lo emiten. Falta confirmarlo en pantalla; si aparece el
warning "El visor externo no abrió el ticket" en `AppLogger`, se fue por el respaldo.

### Verificación

`flutter test` **749 pasando**, cero fallos y cero saltados, incluido el test guardián
`services_no_filtran_excepciones_test.dart`. Checklist previo al Archive comprobado
uno por uno: `isProduction = true`, `aps-environment = production`, bundle
`com.example.arjipagos` en las tres configs y coincidiendo con `GoogleService-Info.plist`,
y 1.0.24+33 por encima de la 1.0.23+32 publicada.

**Archive generado sin errores** en Xcode 26.3. Falta el Distribute a App Store Connect.

---

## Sesión 2026-08-21 (e) — Actualización forzada desde el backend

### Qué se resolvió

No había forma de obligar a un usuario a actualizar. Un release que corrige un fallo de
pagos, o que depende de un cambio de contrato del backend, convivía indefinidamente con
versiones viejas que le pegaban al servidor nuevo.

Ahora la app consulta una política de versión al arrancar y al volver del segundo plano.
Si el build instalado quedó por debajo del mínimo publicado, sale un diálogo **no
descartable** que solo deja ir a la tienda. El mismo endpoint sirve de interruptor de
mantenimiento.

Se descartó `in_app_update` (solo Android) y `upgrader` (lee la ficha de tienda, frágil y
sin control sobre el bloqueo).

### Reglas que gobiernan la feature

1. **Si el endpoint falla, no se bloquea.** Sin red, timeout, 404, 500 o JSON inválido, la
   app sigue normal. Dejar a un usuario fuera por un problema de red sería peor que
   permitirle usar una versión vieja un rato más.
2. **La URL de tienda la manda el backend**, para poder corregirla sin publicar un release.
   El respaldo compilado solo cubre Android; el de iOS está vacío hasta tener el ID
   numérico de App Store, y sin URL no se pinta el botón.
3. **Publicar el mínimo en el backend SOLO cuando el build ya esté vivo en ambas tiendas.**
   Subirlo antes deja a todos bloqueados sin poder actualizar. Es el único error de
   operación que puede romper esto.
4. Se compara por **build number** (`+33`), entero monotónico. Un build ilegible (0) se
   trata como desconocido y cae a comparar el nombre de versión, para no bloquear a quien
   sí tiene la versión buena.

### Contrato del backend

`GET /api/v1/app/version?plataforma=android|ios` — **público, sin Bearer**: la revisión
ocurre antes del login. Todos los campos son opcionales.

```json
{
  "build_minimo": 34,
  "build_recomendado": 35,
  "version_minima": "1.0.25",
  "version_recomendada": "1.0.26",
  "url_tienda": "https://play.google.com/store/apps/details?id=mx.moriah.arjipagos",
  "mensaje": "Actualiza para seguir usando ArjiPagos",
  "mantenimiento": false,
  "mensaje_mantenimiento": ""
}
```

Los enteros se aceptan también como texto (`"34"`), y un `build_minimo` en 0 se descarta.

### Archivos nuevos

| Archivo | Papel |
| --- | --- |
| `lib/src/domain/models/version/VersionApp.dart` | Modelo con `fromJson` tolerante |
| `lib/src/domain/models/version/EstadoActualizacion.dart` | Enum + `ResultadoActualizacion` ya resuelto para pintar |
| `lib/src/core/utils/version_comparador.dart` | `compararSemver` y `requiereActualizacion`, funciones puras |
| `lib/src/data/dataSource/local/VersionInstalada.dart` | Lee `PackageInfo`; se inyecta como función para poder testear |
| `lib/src/data/dataSource/remote/services/VersionService.dart` | GET público con `plataforma` |
| `lib/src/domain/repository/VersionRepository.dart` + `data/repository/VersionRepositoryImpl.dart` | Interfaz e implementación |
| `lib/src/domain/useCases/version/VerificarActualizacionUseCase.dart` | La regla de negocio completa |
| `lib/src/domain/useCases/version/VersionUseCases.dart` | Agrupador |
| `lib/src/presentation/pages/actualizacion/bloc/` | `ActualizacionBloc` + Event + State |
| `lib/src/presentation/widgets/ActualizacionObserver.dart` | Dispara la revisión y abre el diálogo |
| `lib/src/presentation/widgets/ActualizacionRequeridaDialog.dart` | `AlertDialog` con `PopScope` |
| `lib/src/presentation/utils/AppNavigatorKey.dart` | Llave del Navigator raíz |

### Decisiones de diseño que conviene recordar

- **No se tocó `SplashBloc`.** La revisión se dispara desde el `builder` de `MaterialApp`,
  tras el primer frame, así el bloqueo aplica haya o no sesión y sin meter mano en la
  navegación existente.
- **Hizo falta `appNavigatorKey`** porque el `builder` de `MaterialApp` se inserta *por
  encima* del `Navigator`: desde ese contexto `showDialog` no encuentra navegador.
- **El candado está por partida doble:** `barrierDismissible: false` al abrir y
  `PopScope(canPop: false)` dentro. Uno cubre el toque fuera, el otro el botón atrás de
  Android y el gesto de retroceso de iOS.
- **Intervalo de 15 min** (`AppDurations.intervaloRevisionVersion`) entre consultas, con la
  marca en `SharedPref`. Se guarda aunque la consulta falle, para no machacar un servidor
  caído en cada regreso del segundo plano. El arranque siempre fuerza la revisión.
- **El error de "no abrió la tienda" se pinta dentro del propio diálogo**, no en un
  SnackBar (regla del proyecto) ni en otro diálogo encima de uno que bloquea.
- `url_launcher` ya estaba en `pubspec.yaml` sin usarse en `lib/`: esta feature lo estrena.
  No se instaló ninguna dependencia nueva.

### Verificación

`flutter analyze` sin incidencias y `flutter test` con **799 pasando**, cero fallos, de los
cuales 50 son nuevos: comparador, servicio (con `runWithClient`), caso de uso, BLoC y el
diálogo. El test guardián `services_no_filtran_excepciones_test.dart` cubre el servicio
nuevo sin tocarlo, porque escanea carpetas completas.

**Falta la prueba en dispositivo**: el endpoint todavía no existe en el backend, así que de
momento solo se puede comprobar el camino "la consulta falla y la app arranca normal".

---

## Sesión 2026-08-21 (f) — El bloqueo probado en el Oppo, y el fallo que destapó

### El fallo

Con el endpoint ya en producción, la primera prueba en el Oppo (CPH2639, Android 16)
falló: **el diálogo aparecía y se desvanecía solo un segundo después**, dejando al
usuario dentro de la app con una versión obsoleta. Es decir, la actualización forzada no
forzaba nada.

Causa: `SplashPage` termina navegando con
`Navigator.restorablePushNamedAndRemoveUntil(context, 'login'|'menu_principal', (route) => false)`.
Ese predicado retira **todas** las rutas de la pila, y la del diálogo es una ruta más.
El observador no se enteraba: para él el diálogo simplemente "se había cerrado".

Y hubo un segundo fallo encima del primero. Al reabrirlo, el `push` caía **dentro** del
mismo `removeUntil` que aún estaba vaciando la pila, así que la ruta nueva se iba con la
misma barrida — sin diálogo y sin aviso en el log. Solo se veía una línea de reapertura y
nada en pantalla.

### El arreglo

1. **El diálogo siempre se cierra devolviendo un `CierreActualizacion`** (`usuario` o
   `reintentar`). Para eso el `PopScope` va con `canPop: false` *siempre* y el cierre lo
   decide `onPopInvokedWithResult`, que es lo que permite devolver un motivo también
   cuando se sale con el atrás. Se abre con `barrierDismissible: false` en todos los
   casos, para que no quede ninguna vía de cierre anónima.
2. Con eso, **un resultado nulo solo puede significar una cosa**: que una navegación se
   llevó la ruta. `ActualizacionObserver` lo detecta y vuelve a abrir, hasta 5 veces.
3. Antes de reabrir espera `300 ms` (`_esperaTrasNavegacion`) a que la navegación termine
   de vaciar la pila. Sin esa espera la reapertura se perdía en silencio.
4. El diálogo dejó de tocar el BLoC: solo informa de cómo se cerró. Quien traduce eso a
   eventos —y quien decide reabrir— es el observador.

### Verificado en el dispositivo (Oppo CPH2639, Android 16)

| Caso | Resultado |
| --- | --- |
| Endpoint en producción | `200`, parseado. El backend **no manda `build_minimo`**, así que entra el respaldo por nombre de versión — el diseño tolerante era necesario, no decorativo |
| Aviso sugerido | Diálogo sobre el Menú Principal con "Ahora no" y "Actualizar" |
| Bloqueo obligatorio (build con `--build-name=1.0.22`) | "Actualización necesaria", un solo botón, **dos pulsaciones del atrás no lo cierran** y la app sigue en primer plano |
| Botón "Actualizar" | Abre la ficha correcta de Google Play (`mx.moriah.arjipagos`) |
| Sobrevive al salto del splash | Sí, tras el arreglo |

El caso obligatorio se probó **sin tocar el backend**, compilando con
`flutter build apk --debug --build-name=1.0.22 --build-number=31` para caer por debajo del
mínimo publicado. `pubspec.yaml` no se modificó.

### Trampa de testing que costó varias vueltas

`testWidgets` corre el cuerpo dentro de una zona `FakeAsync`. Un BLoC creado en `setUp`
nace en la zona de **fuera**, y entonces sus eventos no se entregan hasta que la prueba
termina: los `expect` se evaluaban antes de que el diálogo existiera, y `await bloc.close()`
en el `tearDown` dejaba el runner colgado hasta el timeout. **En tests de widget, el BLoC
se construye dentro del cuerpo de la prueba**, no en `setUp`. Queda documentado en la
cabecera de `test/widgets/common/actualizacion_observer_test.dart`.

### Datos que aportó la prueba

- **ID de App Store conseguido**: la respuesta de `plataforma=ios` trae
  `id6760574386`. Ya está en `AppUrls.tiendaIos`, percent-encoded como lo manda el backend
  (`arj%C3%AD-pagos`), porque un carácter no ASCII crudo no sobrevive a `Uri.parse`.
- El backend hoy devuelve `version_minima: 1.0.24` y `version_recomendada: 1.0.25`.

### Verificación

`flutter analyze` limpio y `flutter test` con **805 pasando** (6 nuevos: 5 del observador
—incluido el de regresión del salto del splash— y 1 del diálogo). En el Oppo quedó
instalado el release **1.0.24+33**.

---

## Sesión 2026-08-21 (g) — Mantenimiento probado contra producción y segunda carrera corregida

### Lo que se probó

Con el backend ya mandando `mantenimiento` y `mensaje_mantenimiento`, se verificó el
camino completo en el Oppo (CPH2639), build **release**, contra producción:

| Comprobación | Resultado |
| --- | --- |
| `mantenimiento: true` | Diálogo "En mantenimiento" con el mensaje literal del backend |
| Sin enlace a tienda | Correcto: solo "Reintentar" |
| Manda sobre las versiones | Con `recomendada 1.0.25` tocaba el aviso de versión nueva; salió mantenimiento |
| El atrás no lo cierra | Una pulsación: diálogo intacto, app en primer plano, **mismo PID** |
| `mantenimiento: false` | La app se comporta igual que antes; las claves nuevas no estorban |

Sobre el atrás: la primera pulsación se la come el diálogo. La segunda manda la app a
segundo plano, pero **no es una vía de escape** — al volver, el bloqueo sigue puesto.

### El segundo fallo (mismo día, otra carrera)

Al pulsar **Reintentar** el diálogo se cerraba y no volvía nada, ni siquiera el aviso de
versión nueva que tocaba. En arranque en frío sí salía, así que el hueco estaba en el
reintento.

Causa: `ActualizacionObserver` mandaba **dos eventos seguidos** —
`ActualizacionDialogoCerradoEvent` y `ActualizacionVerificarEvent(forzar: true)`— y `bloc`
**no garantiza el orden entre handlers de eventos distintos**. La comprobación corría
primero, se encontraba `state.dialogoAbierto == true`, y salía por el guard sin consultar
nada. Después el cierre reseteaba el estado y la pantalla se quedaba limpia.

Arreglo: **un evento único**, `ActualizacionReintentarEvent`, cuyo handler emite el estado
neutro y consulta a continuación, en ese orden y sin carrera posible. La consulta se
extrajo a `_consultar(emit)`, compartida con `_onVerificar`.

⚠️ Lección que vale para todo el proyecto: **si dos eventos tienen que ocurrir en orden,
son un solo evento.** `bloc` solo garantiza el orden dentro del mismo tipo de evento.

### Verificación

`flutter analyze` limpio y `flutter test` con **807 pasando** (2 nuevos, ambos de
regresión de esta carrera). Release 1.0.24+33 reinstalado en el Oppo.

### "Reintentar" verificado de verdad

Prueba definitiva en el Oppo, **sin reiniciar la app** (mismo PID 21249 de principio a fin):

1. Con `app_mantenimiento` encendido, arranque en frío → diálogo "En mantenimiento".
2. Pulsar Reintentar con el mantenimiento **aún encendido** → el diálogo vuelve a salir.
   Antes del arreglo aquí no volvía nada, así que la reaparición ya prueba que consultó.
3. Se apaga `app_mantenimiento` en el backend, con el diálogo en pantalla.
4. Pulsar Reintentar → el diálogo cambia a **"Hay una versión nueva"**.

El paso 4 es el que cierra el círculo: solo puede ocurrir si leyó el valor nuevo del
servidor, no una copia en memoria. Los cuatro casos de la feature quedan verificados en
dispositivo contra producción.

---

## Sesión 2026-08-21 (h) — Icono con volumen y nombre "Arjí Pagos"

### Qué se cambió

El icono era el emblema marrón sobre un cuadro blanco: se perdía sobre fondos
claros y no tenía presencia. Ahora es un cuadro con degradado de marca, barrido de luz
y el emblema en crema con sombra — el mismo recurso que usan WhatsApp y Temu, que **no
son 3D**: son figuras planas con degradado y sombra.

Se descartaron dos alternativas probadas: un medallón en relieve (a 48 px el crema sobre
crema se apagaba) y una extrusión real en 3D (se leía como icono de juego y engrosaba el
lettering "ARJÍ" al reducirlo). La comparativa está en `otros/iconos_3d/`.

También se cambió la etiqueta del lanzador: **`arjipagos` → `Arjí Pagos`**, en
`android:label` del manifiesto y en `CFBundleDisplayName` de iOS. `CFBundleName` se dejó
igual: es el nombre interno, no el visible.

### Assets y por qué son cuatro

El emblema es **línea fina**, así que el tamaño se ajustó midiendo, no a ojo: se renderizó
a 48, 72 y 96 px y se amplió sin suavizar para ver qué detalle sobrevivía.

| Archivo | Para qué | Escala del emblema |
| --- | --- | --- |
| `assets/arji/icono_app.png` | iOS y Android antiguo: imagen ya compuesta | **86 %** |
| `assets/arji/icono_fondo.png` | Capa de fondo del icono adaptativo | — |
| `assets/arji/icono_frente.png` | Capa de frente del icono adaptativo | **68 %** |
| `assets/arji/icono_mono.png` | Iconos temáticos de Android 13+ | 68 % |

**La diferencia de escala es intencional.** El icono adaptativo lo recorta cada lanzador
con su propia máscara y solo el 66,7 % central está garantizado; al 86 % una máscara
circular se comería el aro. iOS usa la imagen tal cual y solo redondea esquinas, así que
puede ir mucho más grande.

`app_icon.png` **no se tocó**, para poder revertir.

### Verificado en el Oppo

Instalado en release: el icono se lee bien junto a sus vecinos del cajón de apps y la
etiqueta sale como "Arjí Pagos". Se llegó al 68 % en dos pasadas — al 60 % inicial el
emblema quedaba flotando con demasiado margen.

### iOS: lo que queda pendiente en la Mac

Los 21 PNG se generaron **sin canal alfa** (Apple rechaza en revisión los iconos con
transparencia) y con las esquinas opacas a sangre. Eso está listo.

Las variantes **oscura y con tinte de iOS 18** están generadas y copiadas en el catálogo,
pero **sin declarar en `Contents.json`**, a propósito:

- El catálogo está en formato antiguo (idioms `iphone`/`ipad`/`ios-marketing`); las
  apariencias exigen un slot `universal` de tamaño único, y migrar **borra las entradas
  por tamaño**.
- El objetivo de despliegue es iOS 15 y el icono de tamaño único es de iOS 16+.
- `flutter_launcher_icons` reescribe ese archivo en cada ejecución.

Nada de esto se puede comprobar desde Linux. **Instrucciones completas en
`otros/iconos_3d/LEEME_ios18.md`**; lo recomendado es asignarlas desde el editor de
Assets de Xcode, que escribe el `Contents.json` correcto por sí solo.

### Verificación

`flutter analyze` limpio y `flutter test` con **807 pasando**, sin regresiones.

---

## Sesión 2026-08-21 (i) — Release 1.0.25+34

### Versionado

`pubspec.yaml` estaba en `1.0.24+33`, **igual** que la versión publicada en las tiendas.
La regla del proyecto exige que sea mayor, así que se subió patch y build:
**`1.0.25+34`**. Coincide además con lo que el backend ya anuncia como
`version_recomendada`.

Es la **primera versión que consulta el endpoint de versión**: hasta que se publique,
la actualización forzada no le llega a ningún usuario.

### Verificación previa al release

| Comprobación | Resultado |
| --- | --- |
| `ApiConfig.isProduction` | `true` |
| Permiso INTERNET en el manifiesto | presente |
| `flutter analyze` | sin incidencias |
| `flutter test` | **807 pasando**, 0 fallos |
| `LastUpgradeCheck` / `LastUpgradeVersion` | 2630 en ambos |
| `LaunchAction` / `ArchiveAction` | `Release` en ambos |
| Bloques del Podfile (`objective_c`/dwarf, LastUpgradeCheck, iOS 15.0) | presentes |
| `Info.plist` | XML válido, `CFBundleDisplayName` = "Arjí Pagos" |
| Catálogo de iconos iOS | `Contents.json` válido, sin referencias rotas, **ningún PNG con alfa** |

### Prueba en el Oppo

Instalado el release `1.0.25+34` (`versionName=1.0.25`, `versionCode=34`): la app entra
directa al Menú Principal y **ya no sale ningún aviso de actualización**, porque 1.0.25
iguala la `version_recomendada`. Es el cierre correcto del ciclo: la feature queda muda
para quien ya está al día.

### Artefactos

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Pendiente al publicar

1. **Subir a las tiendas.** Solo cuando la 1.0.25 esté viva en Play **y** en App Store
   tiene sentido tocar `version_minima` en el backend, y conviene hacerlo por plataforma
   por separado (las claves son independientes).
2. **En la Mac:** limpieza obligatoria, asignar las apariencias del icono de iOS 18
   (ver `CLAUDE.md`, sección "PENDIENTE en la Mac") y Archive.

---

## Sesión 2026-08-23 — Icono con el emblema ARJI 3D sobre blanco

**Petición:** cambiar el icono de la app por `assets/arji/logo_arji_3d.png`, sobre fondo
blanco y ocupando lo máximo permitido, quitando el fondo que trajera la imagen.

**El problema del origen:** `logo_arji_3d.png` llegó en RGB **sin canal alfa**, con el
tablero de transparencia del visor ya mezclado en los píxeles (cuadros de 25.6 px que
alternan gris 205 y blanco 255). Usarlo tal cual habría metido el ajedrez en el icono.

**Cómo se limpió:** reconstruir el tablero por fase falló (quedaba residuo en los bordes
de cada cuadro). Lo que funcionó fue separar por **cromaticidad**: el emblema es marrón
(cromático) y todo el fondo —incluidos los huecos calados del anillo— es acromático y
claro. Máscara de fondo `croma < 14 y luminosidad > 140`, con alfa suave en el antialias.
El corte por luminosidad conserva los grabados oscuros del relieve, que también son
acromáticos pero no son claros. Resultado: 0 píxeles de residuo en el fondo.

**Archivos nuevos** (los del icono anterior quedan intactos por si hay que volver atrás):

| Archivo | Uso | Emblema |
| --- | --- | --- |
| `assets/arji/icono_app_3d.png` | iOS y Android legacy, RGB sin alfa | 79.2 % |
| `assets/arji/icono_fondo_3d.png` | capa de fondo adaptativa, blanco liso | — |
| `assets/arji/icono_frente_3d.png` | capa de frente adaptativa | 77.6 % |
| `assets/arji/icono_mono_3d.png` | icono temático Android 13+ | 77.6 % |
| `assets/arji/icono_ios_oscuro_3d.png` | apariencia oscura iOS 18 | 79.2 % |
| `assets/arji/icono_ios_tinte_3d.png` | apariencia con tinte iOS 18 | 79.2 % |

### El tamaño correcto del emblema — investigado, no tanteado

Se probó a ojo al 68 %, 100 %, 95 %, 90 % y 80 % del botón antes de ir a las guías. Las
medidas buenas son estas y ya no hay que volver a experimentar:

**Android.** La capa mide 108 dp, el lanzador solo deja ver los 72 dp centrales y cada
fabricante aplica su forma. Lo único garantizado contra el recorte es un **círculo
centrado de 66 dp**. Ese 66 dp coincide con la **keyline de círculo de los product icons
de Material** (176 de 192 dp = 91.7 %) llevada al recuadro de 72 dp — o sea que para un
emblema circular como el de ARJI no es solo el máximo seguro, es la medida de diseño.

**La trampa de flutter_launcher_icons:** envuelve la capa de frente en un
`<inset android:inset="16%">` al escribir `mipmap-anydpi-v26/ic_launcher.xml`, que la
encoge al 68 %. Ese XML se regenera en cada ejecución, así que **la compensación tiene que
vivir en el PNG de origen**: emblema al **89.9 %** del PNG → 89.9 % × 0.68 × 108 dp = 66 dp.
Fue justo esto lo que hacía que el primer intento se viera chico: iba al 66.7 % del PNG y
acababa en 45 dp, un 62 % del botón.

**iOS.** Apple no publica keylines. Dice llenar el lienzo de 1024, **no** redondear las
esquinas uno mismo (el sistema aplica su superelipse) y mantener lo esencial lejos de las
esquinas. La convención de las plantillas de icono es **10 % de margen por lado** (arte al
80 %). Con un emblema circular va holgado: la superelipse nunca se acerca más que los
puntos medios de los lados.

**Techos reales.** En Android el máximo SEGURO es 66 dp (91.7 % del botón): la
especificación permite máscaras que llegan a 33 dp del centro, o sea un círculo de 66 dp.
Entre 66 y 72 dp hay riesgo de recorte según el lanzador; por encima de 72 dp el recorte es
seguro. En iOS el techo geométrico es el 100 % del lienzo — se verificó numéricamente que el
punto más cercano al centro de la superelipse está en los puntos medios de los lados, a
1.0000 de la semianchura—, pero ningún icono de iOS se diseña así.

**Medida elegida: 57 dp = 79.2 % del botón**, que es la keyline de CUADRADO de Material
(152/192 dp), con 7.5 dp de aire por lado.

**Las dos plataformas al mismo tamaño.** En Android el emblema se mide contra el recuadro
visible de 72 dp; en iOS el lienzo ENTERO es el botón, sin recuadro más pequeño. Por eso
"79.2 % en Android" y "75 % en iOS" NO se veían igual: el emblema salía ~5 % más chico en
iOS. Para igualarlos hay que usar la misma proporción del botón, o sea 57/72 = 79.2 % también
en iOS. Y esa cifra deja 10.4 % de margen por lado, justo la convención del 10 % de las
plantillas de Apple: igualar Android y cumplir la guía de iOS resultan ser lo mismo.

Verificado componiendo los dos botones al mismo número de píxeles —Android con sus dos capas,
el inset del 16 %, el recorte a 72/108 y la squircle; iOS con su superelipse— y midiendo el
emblema sobre cada render: **79.2 % en los dos**.

Ojo: siguen siendo PNG distintos (`icono_frente_3d.png` para la capa adaptativa,
`icono_app_3d.png` para iOS y el mipmap legacy). Cambiar uno NO mueve el otro — se comprobó
por hash. Si se ajusta el tamaño en Android hay que ajustar iOS a mano.

**Trampa del caché de ColorOS.** Reinstalar el APK **no** refresca el icono que pinta el
sistema: dos capturas seguidas con builds distintos salieron idénticas píxel a píxel. Hay
que hacer `adb shell am force-stop com.android.settings` antes de volver a abrir
Información de la aplicación, o se revisa un render viejo creyendo que es el nuevo. Se
verifica midiendo la proporción emblema/botón en la captura, no a ojo.

**Verificado en Android:** APK release instalado en el Oppo, con el caché forzado a
refrescarse. Medido sobre la captura: el emblema ocupa el **79.0 %** del botón — el objetivo
era 79.2 %. Squircle blanco, emblema centrado, sin recortes. El relieve 3D se aplana un poco
al tamaño del lanzador, pero se lee.

**Verificado en iOS (simulado):** desde Linux no hay iPhone (ver CLAUDE.md), así que se
aplicó la **superelipse real de iOS** (exponente 5, con supermuestreo) a los PNG que
`flutter_launcher_icons` ya escribió en el catálogo, a los tamaños reales de pantalla de
inicio (180 y 120 px) y de Ajustes (87 px), sobre fondo claro y oscuro. Encaja en los tres
sin recortes. Es una comprobación fiel de la forma, **no** una captura de dispositivo:
falta confirmarlo en el iPhone cuando haya Mac.

**Pendiente en iOS:** las apariencias oscura y con tinte se regeneraron con el emblema
nuevo pero siguen **sin asignar** en Xcode — `flutter_launcher_icons` reescribió
`Contents.json`, así que la asignación manual del catálogo hay que rehacerla en la Mac.


## Sesión 2026-08-23 (b) — Invitación a calificar la app

**Petición:** invitar cada cierto tiempo al usuario a calificar la app y escribir reseña.

**Paquete:** `in_app_review 2.0.12` (+ su platform interface). Antes de instalarlo se corrió
`flutter pub add --dry-run`: añade solo esos 2 paquetes, sin downgrades ni conflictos.

### Lo que hay que entender de estas APIs

1. **El sistema decide si la hoja aparece, no la app.** Se llama a `requestReview()` y puede
   no pasar nada, sin callback ni error. Apple limita a **3 veces por usuario al año**; Google
   tiene su propia cuota. Cada llamada gasta cuota **a ciegas**, así que la política propia
   tiene que ser conservadora o se quema la oportunidad buena.
2. **Apple prohíbe disparar la hoja desde un botón.** El botón del menú usa
   `openStoreListing()`, que abre la ficha de la tienda y no consume cuota.
3. **En Android solo funciona si la app viene de Google Play.** Con `adb install`
   `isAvailable()` devuelve `false` y no pasa nada. **Esto no se puede probar por USB**: hay
   que subirlo a una pista de prueba interna.

### Arquitectura

| Capa | Archivo |
| --- | --- |
| domain/models | `resena/EstadoResena.dart` |
| domain/repository | `ResenaRepository.dart` |
| domain/useCases | `resena/{SolicitarResena,RegistrarPagoExitoso,AbrirFichaTienda,Resena}UseCase(s).dart` |
| data/dataSource/local | `ResenaStorage.dart` (contadores) · `ResenaNativa.dart` (envoltorio del plugin) |
| data/repository | `ResenaRepositoryImpl.dart` |

`ResenaNativa` existe solo para que el canal nativo sea mockeable: `InAppReview.instance` es
un singleton que llama a plataforma y no se puede ejercitar en un unit test. La **política**
vive en `SolicitarResenaUseCase`, no en el repositorio.

**Condiciones para invitar** — todas a la vez: ≥3 pagos exitosos, ≥7 días desde el primer
pago, ≥120 días desde la invitación anterior y máximo 3 al año. La comprobación nativa
(`isAvailable`) va **la última** a propósito: es la única que cruza el canal de plataforma y
no tiene sentido pagarla si la política ya dijo que no.

El tope anual se guarda como **lista de fechas**, no como contador: el límite de Apple es
deslizante (3 en 365 días) y cualquier contador con corte fijo se desincroniza del suyo.

### Enganches

- **Automático:** `PagoWebViewPage`. Al confirmarse el pago se llama a
  `registrarPagoExitoso`; al cerrar el diálogo de éxito, tras el `popUntil` y dentro de un
  `addPostFrameCallback`, se llama a `solicitarResena`. El post-frame importa: la hoja la
  pinta el sistema encima de lo que haya, y debe salir sobre el estado de cuenta ya
  restaurado, no sobre el WebView cerrándose.
- **Manual:** item "Calificar la app" en el menú (`kMenuCalificarAppId`, sin `ruta`).
  `MenuPrincipalPage` lo intercepta antes del chequeo de ruta y abre la ficha de la tienda.
  Si falla, `AlertDialog` con `AppStrings.resenaErrorAbrirTienda` — nunca la excepción cruda.

`AppUrls.appStoreId = '6760574386'`, que `in_app_review` exige para abrir la ficha en iOS.

### Verificación

- **21 tests nuevos** (`solicitar_resena_usecase_test.dart`, `resena_storage_test.dart`):
  cubren cada condición que corta por separado, la ventana deslizante, los datos corruptos y
  que un fallo no propague al flujo de pago.
- Se actualizó `menu_principal_bloc_test.dart`, que daba por hechos 3 items del menú.
- **Suite completa: 829 tests en verde.** `flutter analyze` sin incidencias.
- APK release instalado en el Oppo.

### Verificado en el dispositivo (Oppo, APK release)

- La app arranca sin crashes; `logcat` limpio de `FATAL` y `E/flutter`.
- El item "Calificar la app" sale en el menú, en claro **y** en oscuro.
- Al pulsarlo, el foco pasa a `com.android.vending` con la ficha de **Arjí Pagos** abierta en
  "Califica esta app" / "Escribe una opinión". El botón manual funciona de verdad.
- R8: se comprobó en el dex del APK release que `in_app_review` y `ReviewInfo` (Play Core)
  sobreviven a la minificación. No hizo falta añadir reglas a `proguard-rules.pro`.

**Pendiente de probar de verdad:** la invitación **automática** no se puede verificar por USB
(`isAvailable()` da `false` fuera de Play Store). Hay que publicar en una pista de prueba
interna e instalar desde ahí. En iOS, cuando haya Mac.

**Pendiente en la Mac:** `ios/Podfile.lock` está versionado y **todavía no incluye
`in_app_review`**. Se resuelve solo con el flujo ya documentado (`flutter clean && flutter pub
get && cd ios && pod install`) antes del Archive. El plugin pide iOS 12.0 y el proyecto va a
15.0, así que no hay conflicto de plataforma.

### Hallazgo: `assets/arji/` se empaqueta entero en la app (6.6 MB muertos)

`pubspec.yaml` declara `assets/arji/` como carpeta de assets, así que **todo** lo que hay
dentro viaja dentro del APK. En el código Dart solo se usa `assets/arji/logo_arji.png`
(159 KB). Lo demás son insumos de build (`icono_*.png` para flutter_launcher_icons,
`splash_logo.png`) y basura acumulada — incluidos **dos ZIP** (`iloveimg-resized-ipad.zip` y
`-iphone.zip`, 1.9 MB entre los dos).

Total: 26 archivos, 6.8 MB empaquetados, de los que **6.6 MB no se usan en runtime**. De esos,
2.9 MB los añadió el cambio de icono de esta sesión (`icono_*_3d.png` + `logo_arji_3d.png`).

**Arreglo propuesto (NO aplicado — requiere tu visto bueno porque implica mover archivos):**
sacar los insumos de icono/splash a una carpeta que NO esté declarada en `pubspec.yaml`
(p. ej. `tool/iconos/`), dejar en `assets/arji/` solo lo que se carga en runtime, y apuntar
`flutter_launcher_icons` y `flutter_native_splash` a la carpeta nueva. Los ZIP no pintan nada
en el repo.

## Sesión 2026-08-23 (c) — Drawer simplificado

**Petición:** quitar del drawer el ID, el correo y el celular; dejar solo el nombre de pila y
ponerlo a la derecha del avatar.

### Qué se quitó

De la sección "Datos personales" salieron **ID**, **Email** y **Celular**. Quedan solo
**Usuario** y **Familia**.

También se quitó el correo de la **cabecera**, no solo la fila de la lista: estaba debajo del
nombre y seguía siendo el email a la vista dentro del drawer. Si se quiere de vuelta, es
reponer el parámetro `email` en `UserDrawerHeader`.

Al quedar sin uso se borraron `AppStrings.drawerIdLabel`, `drawerEmail` y `drawerCelular`.
`drawerSinRegistrar` sigue en uso por Familia.

### Nombre de pila, no nombre completo

El header usa **`user.nombre`**, que el backend ya manda separado de `apPaterno`/`apMaterno`,
en vez de partir `fullName`: adivinar dónde corta un nombre compuesto sale mal. Por eso se ve
"ILEANA KRISTELL" entero —es el nombre compuesto— y desaparecen los apellidos.

Hay respaldo en `UserDrawer._nombreDePila`: si `user` no ha cargado o `nombre` llega vacío,
recorta la primera palabra de `nombreUsuario`, para que el header nunca acabe mostrando
apellidos.

### Cabecera en fila

`UserDrawerHeader` pasó de `Column` (avatar arriba, nombre debajo) a `Row` (avatar a la
izquierda, nombre a su derecha). El nombre va en `Expanded` con `maxLines: 2` y
`TextOverflow.ellipsis`: el avatar es de ancho fijo, así que el que tiene que ceder en un
drawer estrecho es el texto. Se conserva el `SafeArea(bottom: false)` para el notch de iOS.

### Verificación

- **7 tests nuevos** en `test/widgets/menu_principal/drawer_header_test.dart`: que muestra el
  nombre, la inicial del avatar (y su respaldo con nombre vacío), que **no** aparece ningún
  correo, que el nombre queda a la derecha del avatar y no debajo, y que aguanta tanto un
  nombre larguísimo como un drawer de 220 dp sin desbordar.
- **Suite completa: 836 tests en verde.** `flutter analyze` sin incidencias.
- En el Oppo, APK release, **tema claro y oscuro**: cabecera con avatar + nombre de pila, y
  "Datos personales" con solo Usuario y Familia. Sin crashes en `logcat`.
- iOS: el cambio es Dart puro, sin código de plataforma ni plugins nuevos. No hay nada que
  regenerar.

### Nota: `pathImageProfile` no se usa en ninguna parte

El modelo `User` trae `pathImageProfile`, pero **ningún widget de la app lo consume**: el
avatar es la inicial sobre un círculo, no una foto. Si algún día se quiere la foto real, es un
cambio aparte (`cached_network_image` ya está de dependencia, más el respaldo a la inicial
cuando no haya imagen o falle la carga).

### Deuda señalada, no tocada

`user_drawer.dart` tiene 300 líneas, por encima de la regla de 200. Ya estaba en 298 antes de
esta sesión, así que no es una regresión. Lo natural sería sacar `_LogoutLoadingDialog` a su
propio archivo, pero es un refactor aparte y no se hizo sin pedirlo.

## Sesión 2026-08-23 (d) — Concordancia en la barra de total y limpieza de assets

### Qué se arregló: "1 pago seleccionados"

`total_seleccionado_bar.dart` pluralizaba el sustantivo pero dejaba el participio fijo en
plural, así que con un único pago la barra inferior de Estados de Cuenta leía **"1 pago
seleccionados"**. Con dos o más concordaba bien, y por eso pasaba desapercibido.

- `AppStrings.pagosSeleccionadosLabel` (constante fija `'seleccionados'`) se sustituye por
  `seleccionadoSingular` / `seleccionadoPlural`.
- La barra elige sustantivo y participio con el mismo criterio, en dos variables locales en
  vez de dos ternarios metidos en la interpolación.
- La barra del Carrito no sufría el fallo: dice "2 pagos" a secas, sin participio.

**Test de regresión:** `test/widgets/edo_cta/total_seleccionado_bar_test.dart` — cubre
singular, plural, cero y tema oscuro, y comprueba explícitamente que la forma incorrecta ya
no aparezca.

### Assets: 34 MB fuera de la app

`pubspec.yaml` declaraba carpetas enteras, lo que empaquetaba también lo que git ignora. Los
assets pasan a declararse **archivo por archivo** (solo quedan `logo_arji.png` y
`background_shopping.jpg`, 364 KB en total) y los insumos de diseño se agrupan en
`assets/disenio/`. El APK baja de **95.5 MB a 61.6 MB**.

**No se borró nada:** los 38 MB de insumos siguen en disco. `assets/disenio/` está dentro de
`assets/` y aun así **no entra al bundle**, porque solo se empaqueta lo declarado archivo por
archivo. Comprobado con `flutter build bundle`: `build/flutter_assets/assets/` pesa 364 KB y
tiene exactamente los dos archivos declarados.

Eso hace la regla de declarar archivo por archivo **más** crítica: cambiar la lista por un
`- assets/` metería los 38 MB en la app de una sola vez. Queda anotado en `CLAUDE.md`.

`assets/disenio/` se queda con lo que hace falta para construir: `iconos/` (4.4 MB) y
`splash/` (104 KB), que `pubspec.yaml` referencia para `flutter_launcher_icons` y
`flutter_native_splash`. Ambas se versionan.

### Regla nueva: `otros/` es el almacén local

**En `otros/` va todo lo que no debe subir al repositorio pero sí hay que conservar.** Ya
estaba en el `.gitignore`, pero ahora está escrito como regla en `CLAUDE.md`: ante la duda
entre borrar algo y dejarlo en el repo "por si acaso", se mueve ahí. Es lo contrario de
borrar — nada se pierde, solo deja de viajar al remoto.

Los 34 MB de material sin usar pasan a `otros/sin_usar/` (136 archivos, íntegros). Con eso
desaparece la regla que había hecho falta en el `.gitignore`: `otros/` ya la cubre.

### iOS: el ahorro es idéntico

Verificado con `flutter build bundle`: `build/flutter_assets/` se genera del mismo
`pubspec.yaml`, sin ramas por plataforma, y es lo que Android mete en el APK y iOS en
`Runner.app/Frameworks/App.framework/flutter_assets`. El IPA adelgaza lo mismo.

Nada de iOS referenciaba la carpeta `assets/`: ni `Info.plist`, ni `LaunchScreen.storyboard`,
ni `project.pbxproj`, ni los `Contents.json`. `LaunchImage.imageset`, `LaunchBackground.imageset`
y las variantes de icono de iOS 18 viven en `ios/Runner/Assets.xcassets/` y no se tocaron.

### Verificación en el Oppo (CPH2639), APK release 1.0.25+34

Recorrido completo en **tema claro y oscuro**, sin una sola excepción de Dart, ni `FATAL`, ni
`Unable to load asset` en `logcat`:

- Login, Menú Principal con avisos, Drawer con solo el nombre de pila.
- Estados de Cuenta: selección ascendente por ciclo (el primero con casilla, el resto con
  candado), cascada al marcar, total correcto ($23,136.00 = 11,568 × 2).
- Carrito: orden invertido para que solo el último del ciclo sea quitable, arrastre correcto
  al quitarlo, y la deselección se refleja de vuelta en Estados de Cuenta.
- Notificaciones: lista, no leídas resaltadas, detalle con HTML y marcado como leída.

**Suite completa: 843 tests en verde** (839 previos + 4 nuevos). `flutter analyze` sin
incidencias.

### Aviso para quien pruebe en un Oppo: el teclado seguro apaga las capturas

En cuanto el foco entra en un campo `obscureText`, ColorOS lanza
`com.oplus.securitykeyboard` y **bloquea `adb exec-out screencap`**: la captura sale negra
salvo la barra de estado. La app está perfectamente viva. Para volver a capturar, cerrar el
teclado (`input keyevent 4`) y comprobar que `dumpsys input_method` marque `mInputShown=false`.

Distinto es la pantalla negra tras `adb install -r` con la app abierta: ahí el proceso viejo
queda apuntando a un APK ya borrado. Se arregla con `am force-stop` y relanzar.

### Detalle señalado, no tocado

En tema oscuro, el importe de la fila **seleccionada** de Estados de Cuenta queda apagado
frente al amarillo vivo de las no seleccionadas. Es legible, pero pierde jerarquía justo en la
fila que más destaca. No se tocó por no meterlo en este cambio.

`assets/errores/error_noti.jpeg` sigue versionado aunque `assets/errores/` esté en el
`.gitignore` (se añadió antes que la regla). Los otros dos JPEG de esa carpeta sí están fuera.

## Sesión 2026-08-23 (e) — Verificación completa y cierre de la 1.0.25+34

### Estado verificado

Repaso completo del proyecto antes de generar los binarios de la 1.0.25+34, que sigue sin
publicarse en ninguna tienda (por eso se reutiliza y no se incrementa).

- `flutter analyze` — **sin incidencias**.
- `flutter test` — **843 tests, todos en verde**. Incluidos los dos guardianes:
  `assets_declarados_test.dart` y `services_no_filtran_excepciones_test.dart`.
- `ApiConfig.isProduction = true` y permiso `INTERNET` en el manifiesto: confirmados.
- iOS, configuración crítica intacta: `LastUpgradeCheck = 2630`,
  `LastUpgradeVersion = "2630"`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0`,
  `platform :ios, '15.0'` y los bloques del `Podfile` (`objective_c` con `dwarf`, forzado de
  15.0 y restauración del 2630) en su sitio.

El Archive de iOS sigue sin poder verificarse desde Linux; eso solo se cierra en la Mac.

### El bump de `flutter_secure_storage` a 11.0.0 NO es viable

Era la única dependencia directa desatrasada. Se intentó y **no compila**. El plugin declara
`compileSdk = 37` en su `build.gradle` y eso choca dos veces:

1. Google ya no publica la plataforma `android-37` a secas — el repositorio solo ofrece
   `android-37.0`, `android-37.1` y las beta de `37.2`. AGP traduce el 37 entero al hash
   `android-37` y el build muere con *"Failed to find target with hash string 'android-37'"*.
2. Forzar `compileSdkMinor = 0` desde `android/build.gradle.kts` resuelve el hash pero destapa
   el bloqueo de fondo: **AGP 9.0.1 no soporta API 37**. Lo dice el propio Gradle —
   *"Update this project's version of the Android Gradle plugin to one that supports 37"*.

Salir de ahí exigiría subir AGP por encima del toolchain fijado (AGP 9.0.1 / Gradle 9.3.1 /
KGP 2.3.20), y no compensa: la 11.0.0 solo elimina APIs deprecadas que el proyecto **ya no
usa** —`SecureStorage` está migrado a v10, sin `encryptedSharedPreferences` ni
`sharedPreferencesName`— y añade opciones biométricas que aquí no se usan.

Se revirtieron **ambos** cambios: `pubspec.yaml` vuelve a `^10.1.0` y el parche del
`build.gradle.kts` se deshizo. Queda documentado en `CLAUDE.md` (sección "Dependencias
bloqueadas — NO reintentar") para que nadie lo reintente a ciegas.

### Lo único que sí subió

`archive` 4.1.0 → 4.2.0, dependencia transitiva de desarrollo. Es el único cambio de
`pubspec.lock`. Las 11 restantes siguen frenadas por constraints del SDK.

## Sesión 2026-08-23 (f) — Archive de la 1.0.25+34 en la Mac

Primera sesión en la Mac tras traer del remoto los 5 commits de la 1.0.25+34. Se hizo la
limpieza obligatoria de iOS, se resolvieron los dos avisos que ensuciaban el build y se
subió el Archive a App Store Connect.

### Limpieza obligatoria y verificación

`flutter clean` → `flutter pub get` → `pod install` → `./scripts/build_ios.sh`. El
`post_install` del Podfile hizo su trabajo: restauró `LastUpgradeCheck` y
`LastUpgradeVersion` a 2630 y devolvió `Package.swift` a `.iOS("15.0")` después de que
`flutter clean` lo reseteara a 13.0. `flutter analyze` sin incidencias y los 843 tests en
verde.

### Apariencias del icono iOS 18 — descartadas

El pendiente que arrastraba el proyecto desde el 2026-08-21 queda **cerrado, decidiendo no
hacerlo**. La causa real apareció al inspeccionar el catálogo: `AppIcon.appiconset` está en
formato antiguo (11 `iphone`, 13 `ipad`, 1 `ios-marketing`, **ningún `universal`**), y en
ese formato **Xcode no muestra el control "Appearances"**. No hay hueco Dark/Tinted donde
soltar los PNG, así que arrastrarlos solo los copia dentro de la carpeta sin referenciarlos
en `Contents.json`: quedan huérfanos y generan el aviso *"has 2 unassigned children"*.

Ocurrió dos veces antes de entender el porqué. Y conviene subrayarlo: **el aviso ya venía
del repo** —los `Icon-App-1024x1024@1x-dark.png` y `-tinted.png` estaban versionados dentro
del appiconset sin asignar—, no lo introdujo esta sesión.

Se optó por quitar los huérfanos en vez de migrar a *single-size*, que habría borrado las 25
entradas por tamaño con un deployment target en iOS 15. El catálogo quedó con 25 entradas y
21 PNG, **0 huérfanos y 0 fantasmas**, y el build salió sin un solo warning.

Nada se perdió: los dos PNG versionados se respaldaron en `otros/iconos_3d/` antes de
eliminarlos —eran **distintos** a los 3D, comprobado con `cmp`— y las fuentes siguen en
`assets/disenio/iconos/`. Las copias que Xcode había metido en el appiconset sí eran
idénticas a esas fuentes, así que quitarlas no costó nada.

En iOS 18+ el sistema aplicará su tratamiento automático al icono normal. Documentado en
`CLAUDE.md`, sección "Apariencias del icono (iOS 18) — decidido: NO se usan", con el
script de verificación de huérfanos.

### `BSActionErrorDomain Code=1` al arrancar — corregido

`main.dart` pedía `portraitUp` **y** `portraitDown`, pero el `Info.plist` solo declara
`UIInterfaceOrientationPortrait`. iOS respondía `response-not-possible` en cada arranque. Se
suma que los iPhone con Dynamic Island —el iPhone 17 Pro Max de pruebas entre ellos— no
admiten upside-down por hardware, así que esa orientación nunca podría cumplirse.

Ahora `setPreferredOrientations` pide solo `portraitUp`, con el porqué comentado en el
propio código para que nadie la reponga. El comportamiento de la app no cambia. Confirmado
en dispositivo: el error desapareció del log.

### Resto de la consola: ruido, nada que corregir

Se revisó el log completo del arranque en iPhone 17 Pro Max con iOS 26.6.1 y **no hay ni un
error de la app**. Todo catalogado en `CLAUDE.md` → "Ruido normal en la consola de Xcode":
swizzling de Firebase, `focusItemsInRect`, Impeller, el `empty dSYM` de `objective_c`, los
`Unable to simultaneously satisfy constraints` de `_UIModernBarButton` —bug interno de UIKit
en el *share sheet*, ninguna clase del proyecto implicada— y el ruido de LaunchServices y RBS.

Dos comprobaciones que merecía la pena hacer antes del Archive:

- **dSYM de `objective_c`:** el aviso de LLDB dice "empty dSYM", y es esperado porque el
  XCFramework viene precompilado sin debug info. Lo que valida App Store Connect es el UUID,
  y coincide con el del binario (`E32865A6-9B3B-3EFD-9DAA-BCA94A1CA52D`, verificado con
  `dwarfdump --uuid`). El fix del Podfile funciona.
- **Assets:** ni un `Unable to load asset`. Era el riesgo principal tras sacar los 34 MB del
  bundle en la sesión (d).

### Comprobado en dispositivo

Ticket en PDF y ZIP abren bien —el log muestra que caen a la hoja de compartir, con el ruido
habitual de LaunchServices—, y la invitación a calificar se disparó
(`InAppReviewPlugin: handle openStoreListing`).

Archive subido a App Store Connect sin incidencias.

## Próximas tareas

- **Contraste en oscuro:** el importe de la fila seleccionada en Estados de Cuenta queda
  apagado frente a las no seleccionadas (ver sesión 2026-08-23 (d))
- Página de Facturas
- Manejo automático de token expirado (refresh token o logout automático)
- Completar información en App Store Connect y enviar a revisión
- **Antes del 29-oct-2026:** verificar que la renovación del certificado instale
  `fullchain.pem` (ver sesión 2026-08-13)
- Decidir si se elimina `SplashNavigationState.error` (valor de enum sin usar)
- Evaluar el bump de los paquetes Dart bloqueados por constraints (ver sesión 2026-08-13 (f)).
  `flutter_secure_storage` 11.0.0 ya está **descartado y documentado** (ver sesión 2026-08-23
  (e)): pide API 37 y AGP 9.0.1 no la soporta. Queda `package_config` 2.2.0 → 3.0.0, que es
  cambio de major
- Revisar si `open_filex` publica 4.8.x, para quitar la supresión de warnings del
  Podfile en vez de arrastrarla
- **Actualización forzada:** `version_recomendada` está en `1.0.25`, que no existe en
  ninguna tienda: hoy el aviso sugerido manda al usuario a actualizar a una versión que no
  puede instalar. Bajarla a `1.0.24` o publicar. **Actualizado el 2026-08-24:** el binario
  va ya en `1.0.26+35`, así que la `version_recomendada` queda además por detrás de la app.
  El desfase se cierra publicando la 1.0.26 y subiendo `version_recomendada` a `1.0.26`
- **Actualización forzada:** falta ejercitar el diálogo bloqueante en iOS de punta a punta.
  En la sesión (f) se confirmó que el código va en el binario, pero no que el flujo se
  dispare contra el backend

### Resueltas en la sesión 2026-08-23 (f)

- ~~**Icono iOS 18:** asignar las apariencias oscura y con tinte~~ → **descartado a
  propósito**: el catálogo no admite Appearances sin migrar a *single-size*. Ver la sesión
  (f) y `CLAUDE.md`. No reintentar sin leerlo
- ~~Confirmar si el ticket abre en el visor de PDF o cae a la hoja de compartir~~ → **cae a
  la hoja de compartir**, y abre bien. El log lo evidencia (`Failed to request default share
  mode`, `LSBindingEvaluator`), verificado con PDF y ZIP en el iPhone 17 Pro Max

### 2026-08-24 — El cierre de sesión reventaba en Android e iOS

**Síntoma reportado.** "Cierro sesión, sí cierra la sesión pero crashea tanto en iOS como en
Android."

**Causa raíz.** `user_drawer.dart` volvía al login empujando un `MyApp` **nuevo**:

```dart
navigator.pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const MyApp()),
  (route) => false,
);
```

Eso monta un **segundo `MaterialApp` dentro del que ya está corriendo**. Los dos declaran el
mismo `navigatorKey` (`appNavigatorKey`, un `GlobalKey<NavigatorState>`), así que Flutter
**reparenta** el `Navigator` que ya existía hacia dentro del nuevo `MaterialApp`… que a su vez
vive dentro de una ruta de **ese mismo `Navigator`**. El árbol queda cíclico y la recursión de
`redepthChildren` desborda la pila. Capturado en el Oppo CPH2639 con el APK 1.0.25+34:

```
I flutter : Stack Overflow
I flutter : #1  SlottedContainerRenderObjectMixin.childForSlot
I flutter : #3  SlottedContainerRenderObjectMixin.redepthChildren
I flutter : #4  RenderObject.redepthChild            ← se repite hasta agotar la pila
```

Es un fallo de Dart, de ahí que se diera igual en las dos plataformas. Los dos
`restorationScopeId: 'arjipagos'` duplicados iban por el mismo camino.

`CambiarContrasenaResponse.dart` tenía **el mismo bug**: al aceptar el diálogo de "contraseña
actualizada" empujaba otro `MyApp`.

**Corrección.**

| Archivo | Cambio |
| --- | --- |
| `user_drawer.dart` | `navigator.restorablePushNamedAndRemoveUntil('login', (r) => false)` |
| `CambiarContrasenaResponse.dart` | Lo mismo, con `Navigator.restorablePushNamedAndRemoveUntil` |
| `LoginResponse.dart` | Refresca `HomeBloc`, `EdoCtaListBloc`, `EdoCtaPagadosBloc` y `FacturaBloc` al entrar |

Se usa la variante `restorable*` —igual que ya hacía `SplashPage`— para que la pila que Android
guarda al reciclar el proceso quede en `login` y no devuelva al usuario al Menú Principal ya sin
sesión.

**Por qué hizo falta tocar `LoginResponse`.** Al dejar de recrear la app, los BLoCs de
`blocProviders` (que viven en la raíz) **sobreviven** al cierre de sesión. Sin refrescarlos, el
siguiente usuario vería los estados de cuenta, pagados y facturas del anterior: `HomeBloc`,
`EdoCtaListBloc`, `EdoCtaPagadosBloc` y `FacturaBloc` solo cargaban al crearse. `CarritoBloc` y
`NotificacionBloc` ya se recargan solos en el `initState` de su página, y `BannerBloc` al
montarse la tirilla. La sesión persistida sí se limpiaba bien: `AuthRepositoryImpl.logout()`
hace `secureStorage.clearUserSession()` + `sharedPref.clear()`.

**Test guardián nuevo.** `test/unit/no_reinstancia_myapp_test.dart` falla si alguien vuelve a
instanciar `MyApp` fuera de `lib/main.dart`.

**Verificado en dispositivo** (Oppo CPH2639, Android, APK release):

1. Crash reproducido con el build anterior — `Stack Overflow` en logcat
2. Con el arreglo: cerrar sesión aterriza limpio en el login, logcat sin una sola excepción
3. Volver a entrar carga el Menú Principal del usuario correcto
4. Estados de Cuenta recarga bien y con la selección vacía (`0 pagos seleccionados`)
5. Segundo cierre de sesión: idéntico, sin crash
6. El botón atrás desde el login **sale de la app**, no vuelve al menú sin sesión
7. Reabrir la app aterriza en el login: la sesión quedó cerrada

`flutter analyze` limpio. `flutter test`: **844 pasan**.

**Versión: `1.0.25+34` → `1.0.26+35`.**

La publicada en tiendas sigue siendo la `1.0.24+33`. La `1.0.25+34` nunca llegó a publicarse,
pero **su Archive ya está subido a App Store Connect**, así que reutilizar el build 34 haría que
ASC rechazara la subida (*"the bundle version must be higher than the previously uploaded
version"*). Decisión de Carlos: versión nueva completa, no solo build number, porque el arreglo
del crash de cierre de sesión merece número propio.

**Ojo con `version_recomendada`:** el backend la tiene en `1.0.25`, que ahora queda **por
detrás** de la del binario. No rompe nada (el aviso solo se dispara si la instalada es menor),
pero conviene subirla a `1.0.26` cuando esta se publique.

**Pendiente de esta sesión.**
- Verificar el mismo flujo en el iPhone (aquí solo hay Linux; requiere la Mac)
- `MenuPrincipalBloc._onLogout` / `MenuPrincipalLogout` y `HomeLogoutEvent` son **código
  muerto** en producción: solo los despachan los tests, y duplican lo que ya hace el drawer.
  No se borran sin preguntar
