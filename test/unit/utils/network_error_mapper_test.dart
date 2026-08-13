import 'dart:async';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Tests de [mensajeErrorRed]: la traducción de excepciones técnicas de red a
/// mensajes que sí puede leer el usuario.
///
/// Origen: incidente del 2026-08-13, donde un `HandshakeException` por cadena
/// TLS incompleta llegó crudo a un AlertDialog en la pantalla de login.
void main() {
  group('mensajeErrorRed', () {
    test('HandshakeException → mensaje de conexión segura', () {
      const error = HandshakeException(
        'Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED: '
        'unable to get local issuer certificate(handshake.cc:298))',
      );

      expect(mensajeErrorRed(error), AppStrings.errorConexionSegura);
    });

    test('CertificateException → mensaje de conexión segura', () {
      expect(
        mensajeErrorRed(const CertificateException('certificado inválido')),
        AppStrings.errorConexionSegura,
      );
    });

    test('TlsException genérica → mensaje de conexión segura', () {
      expect(
        mensajeErrorRed(const TlsException('fallo TLS')),
        AppStrings.errorConexionSegura,
      );
    });

    test('SocketException → sin conexión', () {
      expect(
        mensajeErrorRed(const SocketException('Network unreachable')),
        AppStrings.errorConnection,
      );
    });

    test('TimeoutException → timeout', () {
      expect(
        mensajeErrorRed(TimeoutException('tardó demasiado')),
        AppStrings.errorTimeout,
      );
    });

    test('http.ClientException → sin conexión', () {
      expect(
        mensajeErrorRed(http.ClientException('Connection closed')),
        AppStrings.errorConnection,
      );
    });

    test('FormatException → respuesta inválida', () {
      expect(
        mensajeErrorRed(const FormatException('Unexpected character')),
        AppStrings.errorRespuestaInvalida,
      );
    });

    test('excepción desconocida → error genérico', () {
      expect(mensajeErrorRed(Exception('algo raro')), AppStrings.errorUnexpected);
      expect(mensajeErrorRed(StateError('estado inválido')), AppStrings.errorUnexpected);
    });

    test('ningún mensaje filtra detalle técnico al usuario', () {
      final errores = <Object>[
        const HandshakeException('CERTIFICATE_VERIFY_FAILED (handshake.cc:298)'),
        const SocketException('errno = 101'),
        TimeoutException('timeout'),
        http.ClientException('Connection reset by peer'),
        const FormatException('Unexpected character (at offset 0)'),
        Exception('stack trace interno'),
      ];

      // Términos técnicos que nunca deben aparecer en un AlertDialog.
      const prohibidos = [
        'Exception',
        'Error:',
        'errno',
        'handshake',
        'CERTIFICATE',
        'offset',
        'OS Error',
      ];

      for (final error in errores) {
        final mensaje = mensajeErrorRed(error);
        for (final termino in prohibidos) {
          expect(
            mensaje.toLowerCase().contains(termino.toLowerCase()),
            isFalse,
            reason: '"$mensaje" no debe contener "$termino"',
          );
        }
      }
    });
  });
}
