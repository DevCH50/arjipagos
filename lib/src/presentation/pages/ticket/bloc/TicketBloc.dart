import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/domain/useCases/ticket/TicketUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketEvent.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC de la pantalla del ticket de pago.
///
/// Solo descarga: la hoja de compartir es una llamada de plataforma y se
/// dispara desde la pantalla, igual que en el flujo de facturas.
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketUseCases ticketUseCases;

  TicketBloc(this.ticketUseCases) : super(TicketState.initial()) {
    on<TicketDescargarEvent>(_onDescargar);
  }

  /// Descarga el ticket y emite la ruta del archivo listo en disco.
  Future<void> _onDescargar(
    TicketDescargarEvent event,
    Emitter<TicketState> emit,
  ) async {
    try {
      emit(state.copyWith(
        folio: event.folio,
        url: event.url,
        isLoading: true,
        errorMessage: null,
        rutaArchivo: '',
      ));

      final result = await ticketUseCases.descargarTicket.run(
        event.url,
        event.folio,
      );

      if (result is utils.Success<String>) {
        emit(state.copyWith(
          rutaArchivo: result.data,
          isLoading: false,
          errorMessage: null,
        ));
      } else if (result is utils.Error<String>) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.msg,
        ));
      }
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error inesperado abriendo el ticket: $e', tag: 'Ticket');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: mensajeErrorRed(e),
      ));
    }
  }
}
