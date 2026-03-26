import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para cambiar la contraseña del usuario autenticado.
///
/// Delega la operación al repositorio de autenticación,
/// el cual obtiene el token de acceso y llama al servicio HTTP.
class CambiarContrasenaUseCase {
  final AuthRepository repository;
  CambiarContrasenaUseCase(this.repository);

  /// Ejecuta el cambio de contraseña.
  ///
  /// [passwordActual] - Contraseña vigente del usuario.
  /// [passwordNuevo] - Nueva contraseña deseada.
  Future<Resource<dynamic>> run(String passwordActual, String passwordNuevo) =>
      repository.cambiarContrasena(
        passwordActual: passwordActual,
        passwordNuevo: passwordNuevo,
      );
}
