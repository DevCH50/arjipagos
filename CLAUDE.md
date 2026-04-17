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
flutter build ios --release              # Build para iOS

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
| `project.pbxproj` | `LastUpgradeCheck = 1510`                     | Xcode beta lo sube a 2630; revertir si cambia    |
| `Runner.xcscheme` | `LastUpgradeVersion = "1510"`                 | Mismo motivo                                     |
| `Runner.xcscheme` | `LaunchAction buildConfiguration = "Release"` | Necesario para Archive/Distribute                |
| `Podfile`         | `objective_c` usa `dwarf`                     | XCFramework precompilado — no puede generar dSYM |

### Advertencia — Xcode beta / actualizaciones de Xcode

Si Xcode muestra el dialogo **"Update to recommended settings"** al abrir el proyecto:

- **RECHAZAR** (click en "Later" o "Don't Update")
- Si se acepta, `LastUpgradeCheck` y `LastUpgradeVersion` subirán a 2630+
- Revertir con: `git checkout ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`

### Errores conocidos y soluciones

**Error: "Missing dSYM" al subir a App Store Connect**

- Causa: pod `objective_c` es XCFramework precompilado, no puede generar dSYM
- Solución: ya está en `Podfile` — el pod usa `dwarf` en vez de `dwarf-with-dsym`
- Si reaparece, verificar que el bloque `if target.name == 'objective_c'` siga en el Podfile y correr `pod install`

**Error: Archive genera configuración Debug en vez de Release**

- Causa: `LaunchAction` en `Runner.xcscheme` apunta a Debug
- Solución: asegurar `buildConfiguration = "Release"` y `selectedLauncherIdentifier = "Xcode.IDEFoundation.Launcher.PosixSpawn"` en `LaunchAction`

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

- Todo en español (comentarios, commits, documentación)
- Widgets < 200 líneas
- No utilizar más de 3 niveles de anidación de widgets
- Los widgets deben ser finamente responsivos para Android e iOS
- Tests obligatorios para features nuevas
- Material Design 3
- Revisa que tengas todos los permisos necesarios tanto para iOS como para Android tanto de manera implícita como explícita
- Archivos bien comentados
- Guardar todo el progreso en ARJIPAGOS_PROGRESS.md
- Guarda todo lo que ya esta aprobado y funcionando bien
- No borrar nada sin preguntar
- Asegúrate de que todos los widgets y pantallas estén bien optimizados para Android e iOS y en ambos temas, oscuros y claros
- En la medida de lo posible usa agentes y/o subagentes, por ejemplo para crear un widget, utiliza un subagente para crear el widget, otro para crear el bloc, otro para crear el evento, otro para crear el estado, etc.
- Debes asegurarte de no romper nada y que se apegue estrictamente a las arquitecturas limpias y la inyección de dependencias
- Si tienes dudas, pregunta, antes de proceder
- Si tienes que crear un nuevo archivo, asegúrate de que esté bien comentado y que esté bien estructurado
- No Toast, utiliza SnackBar para mostrar mensajes de error o éxito
- Quita del git, todo aquello que no debe ir o que es peligroso que este en git. Me refiero al  
  remoto. Incluye la carpeta "otros".
- No uses emojis en los nombres de los archivos
- No uses emojis en los nombres de las carpetas
- No uses emojis en los nombres de los widgets
- No uses emojis en los nombres de los eventos
- No uses emojis en los nombres de los estados
- No uses emojis en los nombres de los repositorios
- No uses emojis en los nombres de los casos de uso
- No uses emojis en los nombres de los modelos
- No uses emojis en los nombres de las entidades
- No uses emojis en los nombres de las interfaces
- No uses emojis en los nombres de los servicios
- No uses emojis en los nombres de las utilidades
- No uses emojis en los nombres de los archivos de configuración
- No uses emojis en los nombres de los archivos de prueba
- Revisa que no haya desperdicio de memoria o de espacio en disco. Sino que tengas un uso eficiente de los recursos. Y que no quede ningun tipo de basura. Por ejemplo, si vas a usar una variable, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar una función, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar una clase, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar un widget, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un evento, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un estado, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un repositorio, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un caso de uso, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un modelo, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar una entidad, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar una interfaz, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar un servicio, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar una utilidad, asegúrate de que la uses y no la dejes ahí sin usar. Si vas a usar un archivo de configuración, asegúrate de que lo uses y no lo dejes ahí sin usar. Si vas a usar un archivo de prueba, asegúrate de que lo uses y no lo dejes ahí sin usar.
- Todos los strings hardcodeados en el código que deberían estar en AppStrings
- No te metas al backend a menos que el usuario te lo pida.
