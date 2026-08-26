import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';

/// Interface para el bloqueo biométrico de la aplicación.
///
/// Solo cubre el **cerrojo**: pedir la identidad al volver a la app. El login
/// biométrico —entrar sin escribir la contraseña tras cerrar sesión— es una
/// función aparte que depende de tres endpoints que el backend aún no tiene.
/// Ver `PLAN_FACE_ID_BACKEND.md`.
abstract class BiometriaRepository {
  /// Qué admite el aparato y qué eligió el usuario.
  Future<EstadoBiometria> consultarEstado();

  /// Lanza el diálogo nativo del sistema.
  Future<ResultadoBiometria> autenticar({required String motivo});

  /// Persiste la preferencia del cerrojo.
  Future<void> guardarBloqueoActivado(bool activado);
}
