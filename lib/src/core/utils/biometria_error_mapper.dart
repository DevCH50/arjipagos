import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';

/// Traduce el desenlace de un intento biométrico al texto que ve el usuario.
///
/// Mismo criterio que `mensajeErrorRed` para los errores de red: **el detalle
/// técnico va a `AppLogger`, nunca a la pantalla**. Aquí solo salen frases que
/// le dicen a la persona qué pasó y qué puede hacer.
///
/// Devuelve `null` cuando no hay nada que mostrar. Eso es tan importante como
/// los mensajes: cancelar un Face ID es algo que el usuario acaba de hacer a
/// propósito, y sacarle un diálogo para informarle de su propia decisión sería
/// ruido. Se queda el cerrojo con su botón de reintentar, y ya.
String? mensajeResultadoBiometria(ResultadoBiometria resultado) {
  switch (resultado) {
    // El usuario lo sabe: lo hizo él. Nada que decir.
    case ResultadoBiometria.exito:
    case ResultadoBiometria.cancelada:
      return null;

    case ResultadoBiometria.bloqueoTemporal:
      return AppStrings.biometriaBloqueoTemporal;

    case ResultadoBiometria.bloqueoPermanente:
      return AppStrings.biometriaBloqueoPermanente;

    // El cerrojo ya se apagó solo en el caso de uso; esto solo lo explica.
    case ResultadoBiometria.noDisponible:
      return AppStrings.biometriaDesactivadoSoloMensaje;

    case ResultadoBiometria.error:
      return AppStrings.biometriaErrorGenerico;
  }
}

/// Título del diálogo que acompaña a [mensajeResultadoBiometria].
///
/// El caso de "ya no hay biometría en el aparato" no es un error —el bloqueo se
/// desactivó solo y a propósito—, así que lleva su propio título en vez del de
/// fallo.
String tituloResultadoBiometria(ResultadoBiometria resultado) {
  return resultado == ResultadoBiometria.noDisponible
      ? AppStrings.biometriaDesactivadoSoloTitulo
      : AppStrings.biometriaErrorTitulo;
}
