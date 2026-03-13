import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para registrar un nuevo usuario.
///
/// Recibe los datos del formulario de registro y los envía
/// al servidor para crear una nueva cuenta.
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Ejecuta el registro con los datos proporcionados.
  ///
  /// [nombre] - Nombre del usuario.
  /// [apPaterno] - Apellido paterno.
  /// [apMaterno] - Apellido materno (opcional).
  /// [celular] - Número de celular.
  /// [email] - Correo electrónico.
  /// [password] - Contraseña.
  Future<Resource> run({
    required String nombre,
    required String apPaterno,
    required String apMaterno,
    required String celular,
    required String email,
    required String password,
  }) {
    return repository.registerUser(
      nombre: nombre,
      apPaterno: apPaterno,
      apMaterno: apMaterno,
      celular: celular,
      email: email,
      password: password,
    );
  }
}
