import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio para el sistema de notificaciones.
///
/// Define el contrato que deben implementar las fuentes de datos
/// (remota o local) para gestionar las notificaciones del usuario.
abstract class NotificacionRepository {
  /// Obtiene la lista paginada de notificaciones del usuario autenticado.
  ///
  /// [page] indica el número de página a solicitar (por defecto 1).
  /// Retorna [Success] con la lista de [Notificacion] o [Error].
  Future<Resource<List<Notificacion>>> getNotificaciones({int page = 1});

  /// Obtiene el conteo de notificaciones no leídas del usuario.
  ///
  /// Retorna [Success] con el número entero de no leídas o [Error].
  Future<Resource<int>> getCountNoLeidas();

  /// Marca una notificación específica como leída.
  ///
  /// [id] es el identificador único de la notificación a marcar.
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> marcarLeida(int id);

  /// Marca todas las notificaciones del usuario como leídas.
  ///
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> marcarTodasLeidas();
}
