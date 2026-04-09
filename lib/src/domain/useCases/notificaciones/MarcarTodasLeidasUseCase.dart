import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para marcar todas las notificaciones del usuario como leídas.
///
/// Encapsula la lógica de negocio para realizar una actualización masiva
/// del estado de lectura de todas las notificaciones pendientes.
class MarcarTodasLeidasUseCase {
  final NotificacionRepository repository;

  MarcarTodasLeidasUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Success] con `true` si todas las notificaciones fueron
  /// marcadas como leídas correctamente, o [Error] en caso de falla.
  Future<Resource<bool>> run() async {
    return await repository.marcarTodasLeidas();
  }
}
