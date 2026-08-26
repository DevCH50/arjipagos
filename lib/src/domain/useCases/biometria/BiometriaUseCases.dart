import 'package:arjipagos/src/domain/useCases/biometria/AutenticarBiometriaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/biometria/CambiarBloqueoBiometricoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/biometria/ConsultarBiometriaUseCase.dart';

/// Contenedor de casos de uso del bloqueo biométrico.
class BiometriaUseCases {
  ConsultarBiometriaUseCase consultar;
  AutenticarBiometriaUseCase autenticar;
  CambiarBloqueoBiometricoUseCase cambiarBloqueo;

  BiometriaUseCases({
    required this.consultar,
    required this.autenticar,
    required this.cambiarBloqueo,
  });
}
