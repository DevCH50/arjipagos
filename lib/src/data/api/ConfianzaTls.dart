import 'dart:io';

import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Añade la raíz **ISRG Root X1** a las autoridades de confianza de la app.
///
/// ## Por qué existe esto
///
/// El 2026-08-27 varios usuarios no podían ni entrar: la app mostraba
/// «No se pudo establecer una conexión segura con el servidor». No era un fallo
/// del código —el `network_error_mapper` traducía correctamente un
/// `HandshakeException`—, sino que **el certificado del servidor cerraba su
/// cadena en una raíz que esos teléfonos no tenían**.
///
/// El cliente HTTP de Dart valida contra el almacén de confianza **del sistema
/// operativo**, y ese almacén se congela con la versión de Android: un teléfono
/// que no recibe actualizaciones no conoce las raíces emitidas después de salir
/// de fábrica. El servidor ya se corrigió para servir una cadena que termina en
/// ISRG Root X1 (presente en Android desde la 7.1.1, de 2016), pero el
/// `minSdk` de este proyecto es **24 — Android 7.0**, una versión anterior.
/// En esos aparatos seguiría fallando.
///
/// Empaquetar la raíz cierra ese hueco y, de paso, deja a la app inmune a que
/// el almacén del sistema esté incompleto o corrupto.
///
/// ## Esto NO es certificate pinning
///
/// El `SecurityContext` se construye con `withTrustedRoots: true`, así que
/// conserva **todas** las autoridades del sistema y se limita a **añadir** una
/// más. Si mañana el servidor cambia de autoridad certificadora, la app sigue
/// funcionando sin publicar versión. El pinning haría lo contrario —confiar
/// solo en un certificado concreto— y dejaría la app fuera de servicio en
/// cuanto rotara el certificado.
///
/// ## Por qué un `HttpOverrides` y no tocar cada servicio
///
/// Ningún `Service` de este proyecto crea su propio `http.Client`: todos usan
/// las funciones de nivel superior de `package:http` (`http.get`, `http.post`,
/// `http.delete`), que por debajo construyen un `HttpClient` de `dart:io`. Al
/// sustituir la fábrica global, **los quince y pico servicios quedan cubiertos
/// sin tocar ni una línea de ninguno**, igual que las descargas de imágenes de
/// `cached_network_image`.
///
/// Los tests que inyectan un cliente falso con `runWithClient` no se ven
/// afectados: son mecanismos independientes y ese cliente nunca llega a abrir
/// un socket real.
class ConfianzaTls {
  const ConfianzaTls._();

  /// Ruta del certificado dentro del bundle.
  ///
  /// Debe estar declarado en `pubspec.yaml` **y** en
  /// `test/unit/assets_declarados_test.dart`; los assets se dan de alta archivo
  /// por archivo y olvidarlo compila pero revienta en tiempo de ejecución.
  static const String rutaCertificado = 'assets/certs/isrg_root_x1.pem';

  /// Instala el `HttpOverrides` global con la raíz añadida.
  ///
  /// Debe llamarse en `main()` **antes** de cualquier trabajo de red, incluida
  /// la inicialización de Firebase.
  ///
  /// Nunca lanza: si el certificado no se pudiera cargar, se registra el fallo
  /// y la app sigue con el almacén del sistema, que es exactamente el
  /// comportamiento que tenía antes de existir esta clase. Un problema con un
  /// certificado de refuerzo no puede ser motivo de que la app no arranque.
  static Future<void> instalar() async {
    try {
      final datos = await rootBundle.load(rutaCertificado);
      final contexto = SecurityContext(withTrustedRoots: true);

      try {
        contexto.setTrustedCertificatesBytes(datos.buffer.asUint8List());
      } on TlsException catch (e) {
        // Si el sistema YA trae ISRG Root X1 —lo normal en Android 7.1.1+ y en
        // cualquier iOS soportado—, algunas plataformas rechazan volver a
        // añadirla con «CERT_ALREADY_IN_HASH_TABLE». No es un error: significa
        // que la confianza que se quería garantizar ya estaba. Se continúa con
        // el contexto tal cual, que sigue teniendo las raíces del sistema.
        AppLogger.info(
          'ISRG Root X1 ya estaba en el almacén del sistema: ${e.osError?.message ?? e.message}',
          tag: 'TLS',
        );
      }

      HttpOverrides.global = _OverridesConRaizPropia(contexto);
      AppLogger.info('Confianza TLS reforzada con ISRG Root X1', tag: 'TLS');
    } catch (e) {
      AppLogger.error(
        'No se pudo reforzar la confianza TLS; se usará solo el almacén del sistema: $e',
        tag: 'TLS',
      );
    }
  }
}

/// `HttpOverrides` que entrega clientes atados al [SecurityContext] reforzado.
class _OverridesConRaizPropia extends HttpOverrides {
  final SecurityContext _contexto;

  _OverridesConRaizPropia(this._contexto);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Se ignora a propósito el `context` que llegue por parámetro: hoy nadie en
    // el proyecto crea clientes con contexto propio, y si alguien lo hiciera
    // querría igualmente esta raíz. Lo que NO se toca es
    // `badCertificateCallback`: sigue en su valor por defecto, es decir,
    // rechazando cualquier certificado que no valide. Aceptarlo todo aquí
    // desactivaría TLS de hecho.
    return super.createHttpClient(_contexto);
  }
}
