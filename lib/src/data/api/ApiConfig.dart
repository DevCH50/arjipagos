class ApiConfig {
  static const bool isProduction = true;

  // Cambiar a true cuando uses dispositivo físico por WiFi
  static const bool isPhysicalDevice = true;

  // IP del emulador Android (accede a localhost de la PC)
  static const String emulatorUrl = '10.0.2.2:8000';

  // IP de tu PC en la red local (para dispositivo físico)
  // Ejecuta: hostname -I | awk '{print $1}' para obtenerla
  static const String physicalDeviceUrl = '192.168.1.73:8000';

  static const String remoteUrl = 'arjipagos.moriah.mx';

  static String get localUrl => isPhysicalDevice ? physicalDeviceUrl : emulatorUrl;
  static String get baseUrl => isProduction ? remoteUrl : localUrl;
  static bool get useHttps => isProduction;

  static Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    if (useHttps) {
      return Uri.https(baseUrl, path, queryParameters);
    } else {
      return Uri.http(baseUrl, path, queryParameters);
    }
  }

  /// Hosts que solo existen dentro de la máquina que corre el servidor.
  static const Set<String> _hostsLocales = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '::1',
  };

  /// Repara una URL absoluta que el backend arma con un host inalcanzable.
  ///
  /// En desarrollo el servidor firma sus URLs con `localhost:8000`, un host que
  /// solo resuelve dentro de la PC: desde el emulador de Android hay que pegarle
  /// a `10.0.2.2`, y desde un teléfono físico —Android o iPhone— a la IP de la
  /// red local. Solo el simulador de iOS comparte la red del host y funcionaría
  /// tal cual, de ahí que el problema pase inadvertido al probar en Mac.
  ///
  /// Se conservan ruta y query, y se cambia el host por el que corresponde a
  /// esta plataforma. Una URL con host real —producción— se devuelve intacta,
  /// para nunca redirigir a otro servidor por accidente.
  static String repararUrlDelBackend(String url) {
    if (url.isEmpty) {
      return url;
    }

    final original = Uri.tryParse(url);
    if (original == null || !original.hasAuthority) {
      return url;
    }

    if (!_hostsLocales.contains(original.host.toLowerCase())) {
      return url;
    }

    final reparada = buildUri(
      original.path,
      original.queryParameters.isEmpty ? null : original.queryParameters,
    );
    return reparada.toString();
  }
}
