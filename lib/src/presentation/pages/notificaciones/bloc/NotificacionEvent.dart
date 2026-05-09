import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los eventos del BLoC de notificaciones.
///
/// Todos los eventos deben extender esta clase e implementar [props]
/// con los campos que participan en la comparación por igualdad.
abstract class NotificacionEvent extends Equatable {
  const NotificacionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para la carga inicial de notificaciones.
///
/// Se dispara al montar la pantalla de notificaciones por primera vez.
/// Carga la primera página de notificaciones y el conteo de no leídas.
class NotificacionInicialEvent extends NotificacionEvent {
  const NotificacionInicialEvent();
}

/// Evento para cargar la siguiente página de notificaciones (paginación).
///
/// Se dispara cuando el usuario llega al final de la lista y hay más páginas
/// disponibles. Agrega los resultados a la lista existente.
class CargarMasNotificacionesEvent extends NotificacionEvent {
  const CargarMasNotificacionesEvent();
}

/// Evento para marcar una notificación individual como leída.
///
/// [id] identificador único de la notificación a marcar como leída.
class MarcarLeidaEvent extends NotificacionEvent {
  /// Identificador de la notificación a marcar como leída.
  final int id;

  const MarcarLeidaEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Evento para marcar todas las notificaciones del usuario como leídas.
///
/// Actualiza el estado de lectura de forma masiva en el servidor
/// y refleja el cambio localmente sin necesidad de recargar.
class MarcarTodasLeidasEvent extends NotificacionEvent {
  const MarcarTodasLeidasEvent();
}

/// Evento para refrescar únicamente el conteo de notificaciones no leídas.
///
/// Se usa para actualizar el badge/contador sin recargar la lista completa,
/// por ejemplo al regresar a la pantalla desde otra sección de la app.
class ActualizarContadorEvent extends NotificacionEvent {
  const ActualizarContadorEvent();
}

/// Evento para insertar una notificación recibida en foreground (push).
///
/// Se dispara cuando llega una notificación push mientras la app está
/// en primer plano. La notificación se inserta al inicio de la lista
/// y el contador de no leídas se incrementa en 1.
///
/// [notificacion] la notificación recibida desde el servicio de push.
class NotificacionForegroundRecibidaEvent extends NotificacionEvent {
  /// La notificación recibida en foreground.
  final Notificacion notificacion;

  const NotificacionForegroundRecibidaEvent({required this.notificacion});

  @override
  List<Object?> get props => [notificacion];
}

/// Evento para limpiar el indicador de "nueva notificación".
///
/// Se dispara cuando el usuario toca el ícono de la campana,
/// apagando el punto rojo pulsante del AppBar.
class ResetNuevaNotificacionEvent extends NotificacionEvent {
  const ResetNuevaNotificacionEvent();
}

/// Evento para cuando el usuario abre la app tocando una notificación
/// que llegó mientras la app estaba en background o completamente cerrada.
///
/// Activa [hayNueva] y [debeNavegar], y refresca el contador desde el servidor.
/// [MenuPrincipalPage] reacciona a [debeNavegar] para navegar automáticamente
/// a [NotificacionesPage] y luego emite [ResetDebeNavegarEvent].
class NotificacionAbiertaDesdeBackgroundEvent extends NotificacionEvent {
  const NotificacionAbiertaDesdeBackgroundEvent();
}

/// Evento para limpiar la señal de navegación automática.
///
/// Se emite desde [MenuPrincipalPage] inmediatamente después de haber
/// disparado la navegación a [NotificacionesPage], para evitar re-navegaciones
/// en reconstrucciones posteriores del widget.
class ResetDebeNavegarEvent extends NotificacionEvent {
  const ResetDebeNavegarEvent();
}
