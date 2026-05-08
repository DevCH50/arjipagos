import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro para datos sensibles.
///
/// Utiliza flutter_secure_storage para encriptar datos como
/// tokens de autenticación y credenciales de usuario.
///
/// En Android usa cifrado propio (v10+, migración automática desde EncryptedSharedPreferences).
/// En iOS usa Keychain.
class SecureStorage {
  late final FlutterSecureStorage _storage;

  SecureStorage() {
    // v10+: encryptedSharedPreferences eliminado; datos migrados automáticamente.
    const androidOptions = AndroidOptions(
      resetOnError: true,
    );

    // Opciones de iOS
    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    _storage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );
  }

  // ============================================================================
  // OPERACIONES BÁSICAS
  // ============================================================================

  /// Guarda un valor string de forma segura.
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Lee un valor string.
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Elimina un valor.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Verifica si existe una clave.
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Elimina todos los valores almacenados.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ============================================================================
  // OPERACIONES CON JSON
  // ============================================================================

  /// Guarda un Map como JSON encriptado.
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await write(key, jsonString);
  }

  /// Lee un valor JSON y lo convierte a Map.
  Future<Map<String, dynamic>?> readJson(String key) async {
    final jsonString = await read(key);
    if (jsonString == null) {
      return null;
    }

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Si hay error de parsing, eliminamos el valor corrupto
      await delete(key);
      return null;
    }
  }

  // ============================================================================
  // CLAVES PREDEFINIDAS PARA LA APP
  // ============================================================================

  /// Clave para la sesión de usuario.
  static const String keyUserSession = 'user_session';

  /// Clave para el token de acceso.
  static const String keyAccessToken = 'access_token';

  /// Clave para el token de refresh.
  static const String keyRefreshToken = 'refresh_token';

  // ============================================================================
  // MÉTODOS DE CONVENIENCIA PARA SESIÓN
  // ============================================================================

  /// Guarda la sesión del usuario.
  Future<void> saveUserSession(Map<String, dynamic> session) async {
    await writeJson(keyUserSession, session);
  }

  /// Obtiene la sesión del usuario.
  Future<Map<String, dynamic>?> getUserSession() async {
    return await readJson(keyUserSession);
  }

  /// Elimina la sesión del usuario (logout).
  Future<void> clearUserSession() async {
    await delete(keyUserSession);
    await delete(keyAccessToken);
    await delete(keyRefreshToken);
  }

  /// Guarda el token de acceso.
  Future<void> saveAccessToken(String token) async {
    await write(keyAccessToken, token);
  }

  /// Obtiene el token de acceso.
  Future<String?> getAccessToken() async {
    return await read(keyAccessToken);
  }
}
