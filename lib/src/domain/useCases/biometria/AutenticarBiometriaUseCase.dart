import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/domain/repository/BiometriaRepository.dart';

/// Pide la identidad al usuario para levantar el cerrojo.
///
/// Además de lanzar el diálogo, aquí vive **la única decisión de producto** de
/// todo el flujo: si el aparato responde que ya no admite biometría, el bloqueo
/// se apaga solo.
///
/// Sin eso, alguien que active el cerrojo y luego borre sus huellas —o quite el
/// PIN del teléfono— se queda **encerrado fuera de su propia app**, sin manera
/// de llegar al interruptor que lo apagaría, porque el interruptor está dentro.
/// El cerrojo protege datos que ya están protegidos por la sesión: no vale la
/// pena dejar a nadie fuera por sostenerlo.
///
/// Los bloqueos por reintentos ([ResultadoBiometria.bloqueoTemporal] y
/// [ResultadoBiometria.bloqueoPermanente]) **no** lo apagan: ahí el aparato
/// sigue siendo capaz, solo hay que esperar o desbloquearlo con el código.
class AutenticarBiometriaUseCase {
  final BiometriaRepository biometriaRepository;

  AutenticarBiometriaUseCase(this.biometriaRepository);

  Future<ResultadoBiometria> run({required String motivo}) async {
    final ResultadoBiometria resultado =
        await biometriaRepository.autenticar(motivo: motivo);

    if (resultado == ResultadoBiometria.noDisponible) {
      await biometriaRepository.guardarBloqueoActivado(false);
    }

    return resultado;
  }
}
