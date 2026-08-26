import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// Envoltorio delgado sobre `local_auth`.
///
/// Existe por el mismo motivo que `ResenaNativa`: `LocalAuthentication` habla
/// con el canal de plataforma y no se puede ejercitar en un unit test. Todo lo
/// que hay aquí es traducción —del canal nativo a los enums del dominio— para
/// que los casos de uso y el BLoC sí sean testeables.
///
/// **Ninguna decisión de producto vive aquí.** Si el bloqueo se apaga solo o no,
/// lo decide el caso de uso a partir del [ResultadoBiometria] que se devuelve.
///
/// ## Nota sobre la versión del plugin
///
/// Escrito contra `local_auth` **3.x**, que cambió la API respecto de la 2.x:
/// los errores llegan como [LocalAuthException] con un `code` de enum, en vez
/// de un `PlatformException` con códigos en texto. La documentación del propio
/// enum advierte que **pueden añadirse valores nuevos sin considerarlo un
/// cambio incompatible**, así que el `switch` de abajo tiene `default`
/// obligatorio: no se puede asumir que estén cubiertos todos los casos.
class AutenticadorBiometrico {
  final LocalAuthentication _localAuth;

  AutenticadorBiometrico([LocalAuthentication? localAuth])
      : _localAuth = localAuth ?? LocalAuthentication();

  // ==========================================================================
  // CONSULTA DE CAPACIDADES
  // ==========================================================================

  /// Qué admite este aparato.
  ///
  /// Devuelve [BiometriaDisponible.ninguna] ante cualquier fallo del canal: si
  /// no se puede saber si hay sensor, lo seguro es no ofrecer el bloqueo.
  Future<BiometriaDisponible> consultarDisponible() async {
    try {
      // `isDeviceSupported` cubre el hardware Y el bloqueo de pantalla. Si es
      // false no hay nada que ofrecer, ni siquiera PIN.
      final bool soportado = await _localAuth.isDeviceSupported();
      if (!soportado) {
        return BiometriaDisponible.ninguna;
      }

      // Es un getter, no un método. Da false cuando hay hardware pero el
      // usuario no dio de alta ninguna huella ni rostro. El cerrojo sigue
      // sirviendo con la credencial del aparato, así que no se descarta.
      final bool puedeBiometria = await _localAuth.canCheckBiometrics;
      if (!puedeBiometria) {
        return BiometriaDisponible.soloCredencial;
      }

      final List<BiometricType> tipos =
          await _localAuth.getAvailableBiometrics();

      if (tipos.isEmpty) {
        return BiometriaDisponible.soloCredencial;
      }
      if (tipos.contains(BiometricType.face)) {
        return BiometriaDisponible.rostro;
      }
      if (tipos.contains(BiometricType.fingerprint)) {
        return BiometriaDisponible.huella;
      }

      // Android normalmente responde solo `strong` o `weak`, sin decir de qué
      // sensor se trata. No se puede prometer cara ni huella: genérico.
      return BiometriaDisponible.generica;
    } on LocalAuthException catch (e) {
      AppLogger.error(
        'No se pudo consultar la biometría disponible: ${e.code.name} ${e.description}',
        tag: 'Biometria',
      );
      return BiometriaDisponible.ninguna;
    } catch (e) {
      // El canal puede fallar de formas que el plugin no envuelve.
      AppLogger.error(
        'Fallo inesperado al consultar la biometría: $e',
        tag: 'Biometria',
      );
      return BiometriaDisponible.ninguna;
    }
  }

  // ==========================================================================
  // AUTENTICACIÓN
  // ==========================================================================

  /// Lanza el diálogo nativo y traduce el desenlace.
  ///
  /// [motivo] es el texto que el sistema muestra explicando para qué se le pide
  /// la identidad al usuario. iOS lo enseña bajo el icono de Face ID.
  Future<ResultadoBiometria> autenticar({required String motivo}) async {
    try {
      final bool concedido = await _localAuth.authenticate(
        localizedReason: motivo,
        authMessages: _mensajes,
        // Decidido con el usuario: se permite caer al PIN/patrón del aparato.
        // Con `true` quedarían fuera quienes no registran su huella.
        biometricOnly: false,
        sensitiveTransaction: true,
        // Sustituye al `stickyAuth` de la 2.x. Sin esto, una notificación push
        // que llegue con el diálogo abierto cancela la autenticación a media;
        // con `true` el plugin la reintenta al volver al frente.
        persistAcrossBackgrounding: true,
      );

      // Según el contrato de la plataforma, `false` es "el usuario falló el
      // reto sin más consecuencias" — algunas plataformas ni lo devuelven,
      // porque lanzan excepción. Se trata como cancelación: seguir bloqueado,
      // sin regañar a nadie, con el botón de reintentar a la vista.
      return concedido ? ResultadoBiometria.exito : ResultadoBiometria.cancelada;
    } on LocalAuthException catch (e) {
      return _traducirError(e);
    } catch (e) {
      AppLogger.error('Fallo inesperado en la biometría: $e', tag: 'Biometria');
      return ResultadoBiometria.error;
    }
  }

  /// Traduce el código del plugin al enum del dominio.
  ResultadoBiometria _traducirError(LocalAuthException e) {
    switch (e.code) {
      // Cancelaciones. No son errores y no se le muestra nada al usuario.
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.userRequestedFallback:
        return ResultadoBiometria.cancelada;

      // El usuario borró sus huellas, quitó el PIN, o el aparato dejó de
      // admitir biometría desde que se activó el bloqueo. El caso de uso
      // apagará el cerrojo para no dejar a nadie encerrado fuera de su app.
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
        AppLogger.warning(
          'La biometría dejó de estar disponible: ${e.code.name}',
          tag: 'Biometria',
        );
        return ResultadoBiometria.noDisponible;

      // Se reintenta más tarde; el bloqueo NO se apaga.
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        AppLogger.warning(
          'Sensor no disponible por ahora: ${e.code.name}',
          tag: 'Biometria',
        );
        return ResultadoBiometria.bloqueoTemporal;

      case LocalAuthExceptionCode.biometricLockout:
        AppLogger.warning('Sensor bloqueado hasta desbloquear el aparato',
            tag: 'Biometria');
        return ResultadoBiometria.bloqueoPermanente;

      // `default` y no una lista cerrada: el plugin documenta que añadirá
      // códigos nuevos sin considerarlo un cambio incompatible.
      default:
        // El detalle técnico va al log, nunca a la pantalla.
        AppLogger.error(
          'Fallo de autenticación biométrica: ${e.code.name} ${e.description}',
          tag: 'Biometria',
        );
        return ResultadoBiometria.error;
    }
  }

  // ==========================================================================
  // TEXTOS DEL DIÁLOGO NATIVO
  // ==========================================================================

  /// Botones y textos del diálogo del sistema, en español.
  ///
  /// Sin esto salen en inglés aunque el teléfono esté en español, porque los
  /// valores por omisión están escritos dentro del plugin.
  ///
  /// En la 3.x la lista es corta a propósito: el plugin ya no muestra sus
  /// propios diálogos de "ve a Ajustes" —eso ahora lo decide la app—, así que
  /// esos textos desaparecieron.
  ///
  /// `IOSAuthMessages.localizedFallbackTitle` se deja sin poner adrede: iOS
  /// pone ahí su propio texto ya traducido para el botón del código de acceso,
  /// y pasarle una cadena vacía **oculta el botón**.
  static const List<AuthMessages> _mensajes = <AuthMessages>[
    AndroidAuthMessages(
      signInTitle: AppStrings.biometriaTituloNativo,
      signInHint: AppStrings.biometriaMotivoDesbloqueo,
      cancelButton: AppStrings.biometriaCancelar,
    ),
    IOSAuthMessages(
      cancelButton: AppStrings.biometriaCancelar,
    ),
  ];

  /// Nombre correcto del método en este aparato, para hablarle al usuario.
  ///
  /// "Face ID" y "Touch ID" son marcas de Apple: usarlas en Android sería
  /// incorrecto, y llamar "huella" a un reconocimiento facial, también.
  static String nombreDe(BiometriaDisponible disponible) {
    switch (disponible) {
      case BiometriaDisponible.rostro:
        return Platform.isIOS
            ? AppStrings.biometriaFaceId
            : AppStrings.biometriaRostro;
      case BiometriaDisponible.huella:
        return Platform.isIOS
            ? AppStrings.biometriaTouchId
            : AppStrings.biometriaHuella;
      case BiometriaDisponible.generica:
      case BiometriaDisponible.ninguna:
        return AppStrings.biometriaGenerica;
      case BiometriaDisponible.soloCredencial:
        return AppStrings.biometriaCredencial;
    }
  }
}
