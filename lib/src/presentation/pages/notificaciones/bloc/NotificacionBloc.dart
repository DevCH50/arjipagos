import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/NotificacionUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado de la pantalla de notificaciones.
///
/// Responsabilidades:
/// - Carga paginada de notificaciones desde el servidor.
/// - Seguimiento del conteo de notificaciones no leídas (badge).
/// - Marcar una o todas las notificaciones como leídas (optimistic update local).
/// - Insertar notificaciones recibidas en foreground sin recargar la lista.
///
/// Depende de [NotificacionUseCases] para acceder a la capa de dominio.
class NotificacionBloc extends Bloc<NotificacionEvent, NotificacionState> {
  /// Casos de uso del dominio para la gestión de notificaciones.
  final NotificacionUseCases notificacionUseCases;

  NotificacionBloc(this.notificacionUseCases) : super(const NotificacionState()) {
    on<NotificacionInicialEvent>(_onNotificacionInicialEvent);
    on<CargarMasNotificacionesEvent>(_onCargarMasNotificaciones);
    on<MarcarLeidaEvent>(_onMarcarLeida);
    on<MarcarTodasLeidasEvent>(_onMarcarTodasLeidas);
    on<ActualizarContadorEvent>(_onActualizarContador);
    on<NotificacionForegroundRecibidaEvent>(_onNotificacionForegroundRecibida);
  }

  // ---------------------------------------------------------------------------
  // Handlers de eventos
  // ---------------------------------------------------------------------------

  /// Carga la primera página de notificaciones y el conteo de no leídas en paralelo.
  ///
  /// Ambas peticiones se lanzan simultáneamente con [Future.wait] para reducir
  /// la latencia percibida. Si cualquiera de las dos falla, se emite el error.
  Future<void> _onNotificacionInicialEvent(
    NotificacionInicialEvent event,
    Emitter<NotificacionState> emit,
  ) async {
    // Indicar carga inicial, limpiar errores anteriores y resetear paginación.
    emit(state.copyWith(
      isLoading: true,
      notificaciones: const [],
      paginaActual: 1,
      hayMas: true,
      clearError: true,
    ));

    try {
      // Ejecutar ambas peticiones en paralelo.
      final resultados = await Future.wait([
        notificacionUseCases.getNotificaciones.run(page: 1),
        notificacionUseCases.getCountNoLeidas.run(),
      ]);

      if (emit.isDone) {
        return;
      }

      final resultadoLista = resultados[0] as utils.Resource<List<Notificacion>>;
      final resultadoConteo = resultados[1] as utils.Resource<int>;

      // Procesar resultado de la lista.
      if (resultadoLista is utils.Error<List<Notificacion>>) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: resultadoLista.msg,
        ));
        return;
      }

      // Procesar resultado del conteo (error no bloquea la lista).
      final int conteoNoLeidas;
      if (resultadoConteo is utils.Success<int>) {
        conteoNoLeidas = resultadoConteo.data;
      } else {
        // Si falla el conteo, conservar el valor actual para no degradar la UI.
        conteoNoLeidas = state.noLeidas;
      }

      final lista = (resultadoLista as utils.Success<List<Notificacion>>).data;

      emit(state.copyWith(
        notificaciones: lista,
        noLeidas: conteoNoLeidas,
        isLoading: false,
        // Si la primera página devuelve menos registros de lo esperado o vacía,
        // asumimos que no hay más páginas.
        hayMas: lista.isNotEmpty,
        paginaActual: 1,
        clearError: true,
      ));
    } catch (e) {
      if (emit.isDone) {
        return;
      }
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar notificaciones: $e',
      ));
    }
  }

  /// Carga la siguiente página y agrega los resultados a la lista existente.
  ///
  /// No hace nada si ya se está cargando más o si no hay más páginas disponibles.
  Future<void> _onCargarMasNotificaciones(
    CargarMasNotificacionesEvent event,
    Emitter<NotificacionState> emit,
  ) async {
    // Evitar peticiones redundantes.
    if (state.isCargandoMas || !state.hayMas) {
      return;
    }

    emit(state.copyWith(isCargandoMas: true, clearError: true));

    try {
      final siguientePagina = state.paginaActual + 1;
      final resultado = await notificacionUseCases.getNotificaciones.run(
        page: siguientePagina,
      );

      if (emit.isDone) {
        return;
      }

      if (resultado is utils.Success<List<Notificacion>>) {
        final nuevas = resultado.data;
        emit(state.copyWith(
          // Agregar las nuevas notificaciones al final de la lista actual.
          notificaciones: List<Notificacion>.from(state.notificaciones)
            ..addAll(nuevas),
          isCargandoMas: false,
          // Si la respuesta llegó vacía, no hay más páginas.
          hayMas: nuevas.isNotEmpty,
          paginaActual: nuevas.isNotEmpty ? siguientePagina : state.paginaActual,
        ));
      } else if (resultado is utils.Error<List<Notificacion>>) {
        emit(state.copyWith(
          isCargandoMas: false,
          errorMessage: resultado.msg,
        ));
      } else {
        emit(state.copyWith(isCargandoMas: false));
      }
    } catch (e) {
      if (emit.isDone) {
        return;
      }
      emit(state.copyWith(
        isCargandoMas: false,
        errorMessage: 'Error inesperado al cargar más notificaciones: $e',
      ));
    }
  }

  /// Marca una notificación individual como leída.
  ///
  /// Primero llama al servidor y, si tiene éxito, actualiza el item en la lista
  /// local y decrementa el contador de no leídas (optimistic update tras confirmación).
  Future<void> _onMarcarLeida(
    MarcarLeidaEvent event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      final resultado = await notificacionUseCases.marcarLeida.run(event.id);

      if (emit.isDone) {
        return;
      }

      if (resultado is utils.Success<bool> && resultado.data) {
        // Actualizar el item localmente sin recargar la lista completa.
        final listaActualizada = state.notificaciones.map((n) {
          if (n.id == event.id && !n.isRead) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        // Solo decrementar el contador si la notificación no estaba ya leída.
        final eraNoLeida = state.notificaciones
            .any((n) => n.id == event.id && !n.isRead);
        final nuevoConteo = eraNoLeida
            ? (state.noLeidas - 1).clamp(0, state.noLeidas)
            : state.noLeidas;

        emit(state.copyWith(
          notificaciones: listaActualizada,
          noLeidas: nuevoConteo,
          clearError: true,
        ));
      } else if (resultado is utils.Error<bool>) {
        emit(state.copyWith(errorMessage: resultado.msg));
      }
    } catch (e) {
      if (emit.isDone) {
        return;
      }
      emit(state.copyWith(
        errorMessage: 'Error inesperado al marcar notificación como leída: $e',
      ));
    }
  }

  /// Marca todas las notificaciones del usuario como leídas.
  ///
  /// Si el servidor confirma la operación, actualiza toda la lista local
  /// poniendo [isRead] en true y resetea el contador de no leídas a cero.
  Future<void> _onMarcarTodasLeidas(
    MarcarTodasLeidasEvent event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      final resultado = await notificacionUseCases.marcarTodasLeidas.run();

      if (emit.isDone) {
        return;
      }

      if (resultado is utils.Success<bool> && resultado.data) {
        // Marcar todas las notificaciones de la lista local como leídas.
        final listaActualizada = state.notificaciones
            .map((n) => n.copyWith(isRead: true))
            .toList();

        emit(state.copyWith(
          notificaciones: listaActualizada,
          noLeidas: 0,
          clearError: true,
        ));
      } else if (resultado is utils.Error<bool>) {
        emit(state.copyWith(errorMessage: resultado.msg));
      }
    } catch (e) {
      if (emit.isDone) {
        return;
      }
      emit(state.copyWith(
        errorMessage: 'Error inesperado al marcar todas las notificaciones como leídas: $e',
      ));
    }
  }

  /// Recarga únicamente el conteo de notificaciones no leídas.
  ///
  /// No modifica la lista de notificaciones. Útil para refrescar el badge
  /// al volver a la pantalla o al recibir un evento externo.
  Future<void> _onActualizarContador(
    ActualizarContadorEvent event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      final resultado = await notificacionUseCases.getCountNoLeidas.run();

      if (emit.isDone) {
        return;
      }

      if (resultado is utils.Success<int>) {
        emit(state.copyWith(noLeidas: resultado.data, clearError: true));
      } else if (resultado is utils.Error<int>) {
        emit(state.copyWith(errorMessage: resultado.msg));
      }
    } catch (e) {
      if (emit.isDone) {
        return;
      }
      emit(state.copyWith(
        errorMessage: 'Error inesperado al actualizar el contador de notificaciones: $e',
      ));
    }
  }

  /// Inserta una notificación recibida en foreground al inicio de la lista.
  ///
  /// No realiza ninguna llamada de red. La notificación se agrega directamente
  /// al principio de la lista en memoria y se incrementa el contador de no leídas.
  void _onNotificacionForegroundRecibida(
    NotificacionForegroundRecibidaEvent event,
    Emitter<NotificacionState> emit,
  ) {
    // Insertar la nueva notificación al inicio para que aparezca en primer lugar.
    final listaActualizada = [
      event.notificacion,
      ...state.notificaciones,
    ];

    emit(state.copyWith(
      notificaciones: listaActualizada,
      noLeidas: state.noLeidas + 1,
    ));
  }
}
