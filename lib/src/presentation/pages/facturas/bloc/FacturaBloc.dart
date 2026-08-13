import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/useCases/facturas/FacturaUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado de la página de Facturas.
///
/// Maneja la carga y refresco de facturas.
/// El proceso de compartir (base64 → archivo temporal → share_plus)
/// se gestiona en la capa de presentación para mantener BLoC libre
/// de dependencias de plataforma.
class FacturaBloc extends Bloc<FacturaEvent, FacturaState> {
  final FacturaUseCases facturaUseCases;

  FacturaBloc(this.facturaUseCases) : super(FacturaState.initial()) {
    on<FacturaInicialEvent>(_onInicial);
    on<FacturaRefreshEvent>(_onRefresh);
  }

  /// Carga inicial de facturas.
  Future<void> _onInicial(
    FacturaInicialEvent event,
    Emitter<FacturaState> emit,
  ) async {
    await _cargarFacturas(emit);
  }

  /// Refresca la lista de facturas.
  Future<void> _onRefresh(
    FacturaRefreshEvent event,
    Emitter<FacturaState> emit,
  ) async {
    await _cargarFacturas(emit);
  }

  /// Ejecuta la carga de facturas desde el servidor.
  Future<void> _cargarFacturas(Emitter<FacturaState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final result = await facturaUseCases.getFacturas.run();

      if (result is utils.Success<FacturaResponse>) {
        final data = result.data;
        emit(state.copyWith(
          isLoading: false,
          response: data,
          facturas: data.facturas,
          clearError: true,
        ));
      } else if (result is utils.Error<FacturaResponse>) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.msg,
        ));
      }
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error inesperado cargando facturas: $e', tag: 'Factura');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: mensajeErrorRed(e),
      ));
    }
  }
}
