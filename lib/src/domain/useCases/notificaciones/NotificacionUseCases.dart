import 'package:arjipagos/src/domain/useCases/notificaciones/GetCountNoLeidasUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/GetNotificacionesUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/MarcarLeidaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/MarcarTodasLeidasUseCase.dart';

/// Agrupador de casos de uso relacionados con el sistema de notificaciones.
///
/// Facilita la inyección de dependencias al centralizar en un solo objeto
/// todos los casos de uso disponibles para la gestión de notificaciones.
class NotificacionUseCases {
  /// Caso de uso para obtener la lista paginada de notificaciones.
  final GetNotificacionesUseCase getNotificaciones;

  /// Caso de uso para obtener el conteo de notificaciones no leídas.
  final GetCountNoLeidasUseCase getCountNoLeidas;

  /// Caso de uso para marcar una notificación individual como leída.
  final MarcarLeidaUseCase marcarLeida;

  /// Caso de uso para marcar todas las notificaciones como leídas.
  final MarcarTodasLeidasUseCase marcarTodasLeidas;

  const NotificacionUseCases({
    required this.getNotificaciones,
    required this.getCountNoLeidas,
    required this.marcarLeida,
    required this.marcarTodasLeidas,
  });
}
