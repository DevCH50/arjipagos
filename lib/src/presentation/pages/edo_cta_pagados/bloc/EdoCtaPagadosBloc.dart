import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaPagadosUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona la pantalla de pagos realizados.
///
/// Solo carga y refresca datos. No persiste selección ni comparte estado con
/// el carrito: los pagos que muestra ya están liquidados.
class EdoCtaPagadosBloc extends Bloc<EdoCtaPagadosEvent, EdoCtaPagadosState> {
  final EdoCtaPagadosUseCases edoCtaPagadosUseCases;

  EdoCtaPagadosBloc(this.edoCtaPagadosUseCases)
      : super(EdoCtaPagadosState.initial()) {
    on<EdoCtaPagadosInitialEvent>(_onInitial);
    on<EdoCtaPagadosRefreshEvent>(_onRefresh);
  }

  /// Carga inicial de los pagos realizados.
  Future<void> _onInitial(
    EdoCtaPagadosInitialEvent event,
    Emitter<EdoCtaPagadosState> emit,
  ) async {
    await _cargarPagosRealizados(emit);
  }

  /// Refresca la lista de pagos realizados desde el servidor.
  Future<void> _onRefresh(
    EdoCtaPagadosRefreshEvent event,
    Emitter<EdoCtaPagadosState> emit,
  ) async {
    await _cargarPagosRealizados(emit);
  }

  /// Consulta los pagos realizados y emite el estado correspondiente.
  Future<void> _cargarPagosRealizados(Emitter<EdoCtaPagadosState> emit) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final result =
          await edoCtaPagadosUseCases.getEstadosDeCuentaPagados.run();

      if (result is utils.Success<EstadosDeCuentaResponse>) {
        final data = result.data;
        emit(state.copyWith(
          alumnos: data.alumnos,
          isLoading: false,
          errorMessage: null,
        ));
      } else if (result is utils.Error<EstadosDeCuentaResponse>) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.msg,
        ));
      }
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error(
        'Error inesperado cargando pagos realizados: $e',
        tag: 'EdoCtaPagados',
      );
      emit(state.copyWith(
        isLoading: false,
        errorMessage: mensajeErrorRed(e),
      ));
    }
  }
}
