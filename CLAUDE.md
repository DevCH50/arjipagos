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
flutter pub run flutter_native_splash:create  # Regenerar splash
```

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
