import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interface para la capa de datos de autenticación.
abstract class AuthRepository {
  Future<AuthResponse?> getUserSession();
  Future<void> saveUserSession(AuthResponse authResponse);
  Future<Resource> login(String username, String password);
  Future<bool> logout();

  /// Registra un nuevo usuario en el sistema.
  Future<Resource> registerUser({
    required String nombre,
    required String apPaterno,
    required String apMaterno,
    required String celular,
    required String email,
    required String password,
  });

  /// Cambia la contraseña del usuario autenticado.
  Future<Resource> cambiarContrasena({
    required String passwordActual,
    required String passwordNuevo,
  });

  /// Solicita el restablecimiento de contraseña.
  Future<Resource> recuperarContrasena({
    required String username,
    required String email,
    required String deviceName,
  });
}
