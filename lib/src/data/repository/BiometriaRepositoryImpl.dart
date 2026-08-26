import 'package:arjipagos/src/data/dataSource/local/AutenticadorBiometrico.dart';
import 'package:arjipagos/src/data/dataSource/local/BiometriaStorage.dart';
import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/domain/repository/BiometriaRepository.dart';

/// Implementación del repositorio del bloqueo biométrico.
///
/// Une las dos mitades: lo que dice el aparato ([AutenticadorBiometrico]) y lo
/// que eligió el usuario ([BiometriaStorage]).
class BiometriaRepositoryImpl implements BiometriaRepository {
  final AutenticadorBiometrico autenticador;
  final BiometriaStorage biometriaStorage;

  BiometriaRepositoryImpl(this.autenticador, this.biometriaStorage);

  @override
  Future<EstadoBiometria> consultarEstado() async {
    final BiometriaDisponible disponible =
        await autenticador.consultarDisponible();
    final bool activado = await biometriaStorage.bloqueoActivado();

    return EstadoBiometria(disponible: disponible, activado: activado);
  }

  @override
  Future<ResultadoBiometria> autenticar({required String motivo}) {
    return autenticador.autenticar(motivo: motivo);
  }

  @override
  Future<void> guardarBloqueoActivado(bool activado) {
    return biometriaStorage.guardarBloqueoActivado(activado);
  }
}
