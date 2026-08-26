import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/repository/BiometriaRepository.dart';

/// Consulta qué admite el aparato y si el usuario activó el bloqueo.
class ConsultarBiometriaUseCase {
  final BiometriaRepository biometriaRepository;

  ConsultarBiometriaUseCase(this.biometriaRepository);

  Future<EstadoBiometria> run() => biometriaRepository.consultarEstado();
}
