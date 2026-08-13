import 'dart:async';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:http/http.dart' as http;

/// Traduce una excepción técnica de red a un mensaje entendible para el usuario.
///
/// Los Services capturan excepciones crudas (`HandshakeException`,
/// `SocketException`, `FormatException`...) cuyo `toString()` es texto técnico
/// que nunca debe llegar a un `AlertDialog`. Ejemplo real visto en producción:
///
/// ```
/// HandshakeException: Handshake error in client (OS Error:
/// CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate...)
/// ```
///
/// Esta función centraliza la traducción para no repetirla en cada `catch`.
///
/// [error] - La excepción capturada.
/// Retorna un mensaje de [AppStrings] listo para mostrar al usuario.
String mensajeErrorRed(Object error) {
  // TlsException cubre HandshakeException y CertificateException, que son sus
  // subclases. Es el caso de un certificado inválido o una cadena incompleta.
  if (error is TlsException) {
    return AppStrings.errorConexionSegura;
  }

  // Sin red, DNS que no resuelve o conexión rechazada.
  if (error is SocketException) {
    return AppStrings.errorConnection;
  }

  // El servidor no respondió a tiempo.
  if (error is TimeoutException) {
    return AppStrings.errorTimeout;
  }

  // package:http envuelve varios fallos de transporte en ClientException.
  if (error is http.ClientException) {
    return AppStrings.errorConnection;
  }

  // El cuerpo de la respuesta no era JSON válido.
  if (error is FormatException) {
    return AppStrings.errorRespuestaInvalida;
  }

  // Cualquier otra cosa: mensaje genérico. El detalle técnico ya quedó en el
  // log vía AppLogger, que es donde corresponde.
  return AppStrings.errorUnexpected;
}
