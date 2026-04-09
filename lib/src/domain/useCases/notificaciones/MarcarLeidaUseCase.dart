import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para marcar una notificación específica como leída.
///
/// Encapsula la lógica de negocio para actualizar el estado de lectura
/// de una notificación individual identificada por su ID.
class MarcarLeidaUseCase {
  final NotificacionRepository repository;

  MarcarLeidaUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// [id] identificador único de la notificación a marcar como leída.
  /// Retorna [Success] con `true` si la operación fue exitosa o [Error].
  Future<Resource<bool>> run(int id) async {
    return await repository.marcarLeida(id);
  }
}
