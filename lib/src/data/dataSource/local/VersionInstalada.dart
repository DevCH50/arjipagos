import 'package:package_info_plus/package_info_plus.dart';

/// Lee del sistema la versión de la app que el usuario tiene instalada.
///
/// Vive en la capa de datos porque `package_info_plus` habla con el canal
/// nativo: el caso de uso solo recibe el resultado, así que puede probarse sin
/// levantar los bindings de Flutter.
///
/// Devuelve el build number (el `+33` de `pubspec.yaml`, que es `versionCode`
/// en Android y `CFBundleVersion` en iOS) y el nombre de versión (`1.0.24`).
/// Un build que no se pueda interpretar como número se reporta como `0`, y el
/// caso de uso lo trata como "desconocido" en lugar de asumir que es antiguo.
Future<({int build, String version})> leerVersionInstalada() async {
  final info = await PackageInfo.fromPlatform();

  return (
    build: int.tryParse(info.buildNumber.trim()) ?? 0,
    version: info.version.trim(),
  );
}
