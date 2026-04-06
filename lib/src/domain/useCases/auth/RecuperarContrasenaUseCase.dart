import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para solicitar el restablecimiento de contraseña.
///
/// Llama al repositorio de autenticación con los datos del usuario.
class RecuperarContrasenaUseCase {
  final AuthRepository repository;

  RecuperarContrasenaUseCase(this.repository);

  /// [username] - Nombre de usuario escrito en el diálogo.
  /// [email] - Correo electrónico registrado.
  /// [deviceName] - Nombre/tipo del dispositivo.
  Future<Resource<dynamic>> run({
    required String username,
    required String email,
    required String deviceName,
  }) =>
      repository.recuperarContrasena(
        username: username,
        email: email,
        deviceName: deviceName,
      );
}
