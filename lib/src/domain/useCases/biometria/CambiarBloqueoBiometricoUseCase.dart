import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/domain/repository/BiometriaRepository.dart';

/// Enciende o apaga el bloqueo desde el interruptor del menú.
///
/// **Encender exige pasar la biometría primero.** No es un trámite: si se
/// guardara la preferencia sin comprobar nada, bastaría con que alguien
/// agarrara el teléfono desbloqueado para activar un cerrojo que el dueño no
/// puede abrir —porque la huella registrada no es la suya—. Se comprueba que
/// quien activa el bloqueo es quien podrá levantarlo.
///
/// **Apagar no la exige.** Puede parecer incoherente, pero quien llega a este
/// interruptor ya pasó el cerrojo al abrir la app: pedírsela otra vez solo
/// estorba. Y es la salida de emergencia si el sensor empieza a fallar.
class CambiarBloqueoBiometricoUseCase {
  final BiometriaRepository biometriaRepository;

  CambiarBloqueoBiometricoUseCase(this.biometriaRepository);

  /// Devuelve el desenlace de la comprobación.
  ///
  /// Al apagar siempre es [ResultadoBiometria.exito]: no hay nada que fallar.
  /// Al encender, la preferencia solo se guarda si el resultado es
  /// [ResultadoBiometria.exito]; en cualquier otro caso el interruptor se queda
  /// como estaba y la pantalla explica por qué.
  Future<ResultadoBiometria> run({
    required bool activar,
    required String motivo,
  }) async {
    if (!activar) {
      await biometriaRepository.guardarBloqueoActivado(false);
      return ResultadoBiometria.exito;
    }

    final ResultadoBiometria resultado =
        await biometriaRepository.autenticar(motivo: motivo);

    if (resultado == ResultadoBiometria.exito) {
      await biometriaRepository.guardarBloqueoActivado(true);
    }

    return resultado;
  }
}
