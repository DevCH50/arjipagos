import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/AuthService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de autenticación.
///
/// Utiliza [SecureStorage] para almacenar datos sensibles
/// como tokens y sesión de usuario de forma encriptada.
/// Utiliza [SharedPref] para almacenar preferencias no sensibles.
class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  final SecureStorage secureStorage;
  final SharedPref sharedPref;

  AuthRepositoryImpl(this.authService, this.secureStorage, this.sharedPref);

  @override
  Future<Resource> login(String username, String password) {
    return authService.login(username, password);
  }

  @override
  Future<Resource> registerUser({
    required String nombre,
    required String apPaterno,
    required String apMaterno,
    required String celular,
    required String email,
    required String password,
  }) {
    return authService.register(
      nombre: nombre,
      apPaterno: apPaterno,
      apMaterno: apMaterno,
      celular: celular,
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse?> getUserSession() async {
    final data = await secureStorage.getUserSession();
    if (data != null) {
      try {
        return AuthResponse.fromJson(data);
      } catch (e) {
        // Si hay error al parsear, limpiamos la sesión corrupta
        await secureStorage.clearUserSession();
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveUserSession(AuthResponse authResponse) async {
    await secureStorage.saveUserSession(authResponse.toJson());

    // Guardar el token de acceso por separado para uso rápido
    await secureStorage.saveAccessToken(authResponse.accessToken);
  }

  @override
  Future<Resource> cambiarContrasena({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    // Obtener el token de acceso desde el almacenamiento seguro
    final String? token = await secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return Error(AppStrings.errorNoToken);
    }

    // Obtener el user_id desde la sesión almacenada
    final sessionData = await secureStorage.getUserSession();
    final int? userId = sessionData?['user']?['id'] as int?;
    if (userId == null) {
      return Error(AppStrings.errorNoToken);
    }

    return authService.cambiarContrasena(
      token: token,
      userId: userId,
      passwordActual: passwordActual,
      passwordNuevo: passwordNuevo,
    );
  }

  @override
  Future<Resource> recuperarContrasena({
    required String username,
    required String email,
    required String deviceName,
  }) {
    return authService.recuperarContrasena(
      username: username,
      email: email,
      deviceName: deviceName,
    );
  }

  @override
  Future<bool> logout() async {
    try {
      // Limpiar datos sensibles (tokens, sesión)
      await secureStorage.clearUserSession();

      // Limpiar datos no sensibles (pagos seleccionados, carrito, etc.)
      await sharedPref.clear();

      return true;
    } catch (e) {
      return false;
    }
  }
}
