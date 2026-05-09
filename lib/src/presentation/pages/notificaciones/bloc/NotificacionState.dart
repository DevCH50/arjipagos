import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:equatable/equatable.dart';

/// Estado único del BLoC de notificaciones.
///
/// Sigue el patrón de estado único con [copyWith], de modo que la UI
/// solo necesita escuchar un tipo de estado y reacciona a sus campos.
///
/// - [notificaciones] lista acumulada de todas las páginas cargadas.
/// - [noLeidas] contador para el badge; se actualiza de forma independiente.
/// - [hayNueva] verdadero cuando acaba de llegar una notificación en foreground.
/// - [debeNavegar] verdadero cuando el usuario abrió la app tocando una notificación
///   de sistema (background/terminada). La UI navega a [NotificacionesPage] y luego
///   emite [ResetDebeNavegarEvent] para volver a false.
/// - [isLoading] verdadero durante la carga inicial de la primera página.
/// - [isCargandoMas] verdadero mientras se carga una página adicional (paginación).
/// - [hayMas] falso cuando el servidor ya no devuelve más registros.
/// - [paginaActual] número de la última página cargada con éxito.
/// - [errorMessage] mensaje de error de la última operación fallida; null si no hay error.
class NotificacionState extends Equatable {
  /// Lista acumulada de notificaciones del usuario.
  final List<Notificacion> notificaciones;

  /// Cantidad de notificaciones no leídas (usado para el badge).
  final int noLeidas;

  /// Verdadero cuando acaba de llegar una notificación en foreground.
  /// Activa el punto rojo pulsante en el AppBar. Se limpia al tocar la campana.
  final bool hayNueva;

  /// Verdadero cuando el usuario abrió la app tocando una notificación del sistema
  /// (app en background o terminada). MenuPrincipalPage navega a NotificacionesPage
  /// y emite ResetDebeNavegarEvent para volver a false.
  final bool debeNavegar;

  /// Indica si se está realizando la carga inicial (primera página).
  final bool isLoading;

  /// Indica si se está cargando una página adicional (paginación).
  final bool isCargandoMas;

  /// Indica si existe al menos una página más por cargar.
  final bool hayMas;

  /// Número de la última página cargada con éxito.
  final int paginaActual;

  /// Mensaje de error de la última operación fallida.
  /// Null si la última operación fue exitosa o no hubo error.
  final String? errorMessage;

  const NotificacionState({
    this.notificaciones = const [],
    this.noLeidas = 0,
    this.hayNueva = false,
    this.debeNavegar = false,
    this.isLoading = false,
    this.isCargandoMas = false,
    this.hayMas = true,
    this.paginaActual = 1,
    this.errorMessage,
  });

  /// Retorna una copia del estado con los campos proporcionados reemplazados.
  ///
  /// Para limpiar [errorMessage] usa [clearError]; si se pasa null implícitamente,
  /// se conserva el valor anterior (comportamiento de copyWith estándar).
  /// Si se pasa [errorMessage] explícitamente, se sustituye aunque sea null.
  ///
  /// Uso de limpieza: `state.copyWith(clearError: true)` o simplemente
  /// emitir `state.copyWith(errorMessage: null)` — ambas formas son equivalentes
  /// por diseño de este método.
  NotificacionState copyWith({
    List<Notificacion>? notificaciones,
    int? noLeidas,
    bool? hayNueva,
    bool? debeNavegar,
    bool? isLoading,
    bool? isCargandoMas,
    bool? hayMas,
    int? paginaActual,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificacionState(
      notificaciones: notificaciones ?? this.notificaciones,
      noLeidas: noLeidas ?? this.noLeidas,
      hayNueva: hayNueva ?? this.hayNueva,
      debeNavegar: debeNavegar ?? this.debeNavegar,
      isLoading: isLoading ?? this.isLoading,
      isCargandoMas: isCargandoMas ?? this.isCargandoMas,
      hayMas: hayMas ?? this.hayMas,
      paginaActual: paginaActual ?? this.paginaActual,
      // Si clearError=true se limpia; si se pasó errorMessage explícito se usa ese valor;
      // de lo contrario se conserva el existente.
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        notificaciones,
        noLeidas,
        hayNueva,
        debeNavegar,
        isLoading,
        isCargandoMas,
        hayMas,
        paginaActual,
        errorMessage,
      ];
}
