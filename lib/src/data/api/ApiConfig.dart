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
}
