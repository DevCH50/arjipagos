import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para obtener la lista paginada de notificaciones.
///
/// Encapsula la lógica de negocio para recuperar las notificaciones
/// del usuario autenticado desde el repositorio correspondiente.
class GetNotificacionesUseCase {
  final NotificacionRepository repository;

  GetNotificacionesUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// [page] número de página a solicitar al repositorio (por defecto 1).
  /// Retorna [Success] con lista de [Notificacion] o [Error].
  Future<Resource<List<Notificacion>>> run({int page = 1}) async {
    return await repository.getNotificaciones(page: page);
  }
}
