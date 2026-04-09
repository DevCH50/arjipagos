import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para obtener el conteo de notificaciones no leídas.
///
/// Encapsula la lógica de negocio para recuperar el número de
/// notificaciones pendientes de lectura del usuario autenticado.
class GetCountNoLeidasUseCase {
  final NotificacionRepository repository;

  GetCountNoLeidasUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Success] con el número entero de notificaciones no leídas o [Error].
  Future<Resource<int>> run() async {
    return await repository.getCountNoLeidas();
  }
}
