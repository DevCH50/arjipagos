import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/NotificacionService.dart';
import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de notificaciones.
///
/// Delega todas las operaciones al servicio HTTP [NotificacionService],
/// aplicando un try/catch adicional como capa de seguridad ante errores
/// inesperados provenientes del servicio.
class NotificacionRepositoryImpl implements NotificacionRepository {
  final NotificacionService notificacionService;

  NotificacionRepositoryImpl(this.notificacionService);

  /// Obtiene la lista paginada de notificaciones del usuario autenticado.
  ///
  /// [page] indica el número de página (por defecto 1).
  @override
  Future<Resource<List<Notificacion>>> getNotificaciones({int page = 1}) async {
    try {
      return await notificacionService.getNotificaciones(page: page);
    } catch (e) {
      AppLogger.error('Error al obtener notificaciones: $e', tag: 'Notificacion');
      return Error<List<Notificacion>>(mensajeErrorRed(e));
    }
  }

  /// Obtiene el conteo de notificaciones no leídas del usuario.
  @override
  Future<Resource<int>> getCountNoLeidas() async {
    try {
      return await notificacionService.getCountNoLeidas();
    } catch (e) {
      AppLogger.error('Error al obtener conteo de no leídas: $e', tag: 'Notificacion');
      return Error<int>(mensajeErrorRed(e));
    }
  }

  /// Marca una notificación específica como leída.
  ///
  /// [id] es el identificador único de la notificación a marcar.
  @override
  Future<Resource<bool>> marcarLeida(int id) async {
    try {
      return await notificacionService.marcarLeida(id);
    } catch (e) {
      AppLogger.error('Error al marcar notificación como leída: $e', tag: 'Notificacion');
      return Error<bool>(mensajeErrorRed(e));
    }
  }

  /// Marca todas las notificaciones del usuario como leídas.
  @override
  Future<Resource<bool>> marcarTodasLeidas() async {
    try {
      return await notificacionService.marcarTodasLeidas();
    } catch (e) {
      AppLogger.error(
          'Error al marcar todas las notificaciones como leídas: $e',
          tag: 'Notificacion');
      return Error<bool>(mensajeErrorRed(e));
    }
  }
}
