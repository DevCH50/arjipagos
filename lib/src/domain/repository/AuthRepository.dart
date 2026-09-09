import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interface para la capa de datos de autenticación.
abstract class AuthRepository {
  Future<AuthResponse?> getUserSession();
  Future<void> saveUserSession(AuthResponse authResponse);
  Future<Resource> login(String username, String password);
  Future<bool> logout();

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
