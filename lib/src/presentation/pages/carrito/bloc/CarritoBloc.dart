import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC para manejar el carrito de compras.
///
/// Carga los pagos seleccionados desde el storage y permite
/// quitar items, limpiar el carrito y procesar el pago.
class CarritoBloc extends Bloc<CarritoEvent, CarritoState> {
  final SeleccionPagosStorage _seleccionStorage;
  final AuthUseCases _authUseCases;
  final EdoCtaUseCases _edoCtaUseCases;

  CarritoBloc({
    required SeleccionPagosStorage seleccionStorage,
    required AuthUseCases authUseCases,
    required EdoCtaUseCases edoCtaUseCases,
  })  : _seleccionStorage = seleccionStorage,
        _authUseCases = authUseCases,
        _edoCtaUseCases = edoCtaUseCases,
        super(const CarritoState()) {
    on<CarritoInitialEvent>(_onInitial);
    on<CarritoQuitarPagoEvent>(_onQuitarPago);
    on<CarritoLimpiarEvent>(_onLimpiar);
    on<CarritoPagarEvent>(_onPagar);
    on<CarritoPagoExitosoEvent>(_onPagoExitoso);
    on<CarritoPagoFallidoEvent>(_onPagoFallido);
    on<CarritoCancelarPagoEvent>(_onCancelarPago);
  }

  /// Maneja el evento inicial: carga los pagos seleccionados del storage.
  Future<void> _onInitial(
    CarritoInitialEvent event,
    Emitter<CarritoState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Cargar pagos seleccionados del storage
      final pagosSeleccionados = await _seleccionStorage.cargar();

      if (pagosSeleccionados.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          pagosSeleccionados: {},
          alumnos: [],
        ));
        return;
      }

      // Obtener datos de alumnos desde el servidor
      final result = await _edoCtaUseCases.getEstadosDeCuenta.run();

      if (result is Success) {
        final response = (result as Success).data;
        final estadoCargado = state.copyWith(
          isLoading: false,
          alumnos: response.alumnos,
          pagosSeleccionados: pagosSeleccionados,
        );
        emit(estadoCargado);

        // Validación defensiva: si los pagos guardados en storage forman una
        // referencia que ya excede el límite, avisar al usuario para que la reduzca.
        if (!estadoCargado.referenciaValida) {
          AppLogger.warning(
            'Referencia excede límite al cargar carrito — "${estadoCargado.referenciaPago}" '
            '(${estadoCargado.longitudReferencia}/${AppConstants.maxLongitudReferencia} chars)',
            tag: 'Carrito',
          );
          emit(estadoCargado.copyWith(
            errorMessage: AppStrings.carritoReferenciaExcede,
          ));
        }
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: (result as Error).msg,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Maneja el evento de quitar un pago del carrito.
  ///
  /// Solo toca el ciclo al que pertenece el pago: la selección del resto de
  /// ciclos queda intacta.
  Future<void> _onQuitarPago(
    CarritoQuitarPagoEvent event,
    Emitter<CarritoState> emit,
  ) async {
    final cicloId = _cicloDelPago(event.alumnoId, event.pagoId);
    if (cicloId == null) {
      return;
    }

    final nuevosPagos = <int, Map<int, List<int>>>{};
    state.pagosSeleccionados.forEach((ciclo, alumnos) {
      nuevosPagos[ciclo] = Map<int, List<int>>.from(alumnos);
    });

    final alumnosDelCiclo = nuevosPagos[cicloId];
    if (alumnosDelCiclo != null &&
        alumnosDelCiclo.containsKey(event.alumnoId)) {
      final pagosAlumno = List<int>.from(alumnosDelCiclo[event.alumnoId]!);
      pagosAlumno.remove(event.pagoId);

      if (pagosAlumno.isEmpty) {
        alumnosDelCiclo.remove(event.alumnoId);
      } else {
        alumnosDelCiclo[event.alumnoId] = pagosAlumno;
      }

      if (alumnosDelCiclo.isEmpty) {
        nuevosPagos.remove(cicloId);
      }
    }

    emit(state.copyWith(pagosSeleccionados: nuevosPagos));
    await _seleccionStorage.guardar(nuevosPagos);
  }

  /// Busca el ciclo al que pertenece un pago dentro de los alumnos cargados.
  ///
  /// Devuelve `null` si el pago no está en los datos actuales, en cuyo caso no
  /// hay nada que quitar.
  int? _cicloDelPago(int alumnoId, int pagoId) {
    for (final alumno in state.alumnos ?? const []) {
      if (alumno.alumnoId != alumnoId) {
        continue;
      }
      for (final pago in alumno.estadoDeCuenta) {
        if (pago.id == pagoId) {
          return pago.cicloId;
        }
      }
    }
    return null;
  }

  /// Maneja el evento de limpiar el carrito.
  Future<void> _onLimpiar(
    CarritoLimpiarEvent event,
    Emitter<CarritoState> emit,
  ) async {
    emit(state.copyWith(pagosSeleccionados: {}));
    await _seleccionStorage.guardar({});
  }

  /// Maneja el evento de iniciar el pago.
  Future<void> _onPagar(
    CarritoPagarEvent event,
    Emitter<CarritoState> emit,
  ) async {
    if (state.cantidadPagos == 0) {
      emit(state.copyWith(errorMessage: AppStrings.carritoSinPagos));
      return;
    }

    // Validar que la referencia no exceda el límite de Adquira México.
    // Esto protege contra datos cargados desde versiones anteriores de la app
    // y como segunda barrera ante la validación en EdoCta.
    if (!state.referenciaValida) {
      AppLogger.warning(
        'Referencia excede límite al intentar pagar — "${state.referenciaPago}" '
        '(${state.longitudReferencia}/${AppConstants.maxLongitudReferencia} chars)',
        tag: 'Carrito',
      );
      emit(state.copyWith(errorMessage: AppStrings.carritoReferenciaExcede));
      return;
    }

    emit(state.copyWith(isProcesandoPago: true, clearError: true));

    try {
      // Obtener datos de autenticación
      final authResponse = await _authUseCases.getUserSession.run();

      if (authResponse == null) {
        emit(state.copyWith(
          isProcesandoPago: false,
          errorMessage: AppStrings.errorSesionInvalida,
        ));
        return;
      }

      // Construir el request de pago
      final pagoRequest = PagoRequest(
        token: authResponse.accessToken,
        userId: authResponse.user.id,
        importe: state.totalAPagar,
        urlRetorno: Endpoints.pagoUrlRetorno,
        referencia: state.referenciaPago,
      );

      AppLogger.debug(
        'Pago — ref: ${pagoRequest.referencia} | importe: ${pagoRequest.importe} | userId: ${pagoRequest.userId}',
        tag: 'Carrito',
      );

      // Construir datos para el WebView
      emit(state.copyWith(
        isProcesandoPago: false,
        pagoData: {
          'url': Endpoints.pagoAdquira,
          'params': pagoRequest.toMap(),
          'token': pagoRequest.token,
        },
      ));
    } catch (e) {
      emit(state.copyWith(
        isProcesandoPago: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Maneja el evento de pago exitoso.
  Future<void> _onPagoExitoso(
    CarritoPagoExitosoEvent event,
    Emitter<CarritoState> emit,
  ) async {
    // Limpiar el carrito del storage
    await _seleccionStorage.guardar({});

    emit(state.copyWith(
      pagosSeleccionados: {},
      pagoExitoso: true,
      mensajeExito: AppStrings.pagoRealizadoConExito,
      clearPagoData: true,
    ));
  }

  /// Maneja el evento de pago fallido.
  void _onPagoFallido(
    CarritoPagoFallidoEvent event,
    Emitter<CarritoState> emit,
  ) {
    emit(state.copyWith(
      errorMessage: event.mensaje,
      clearPagoData: true,
    ));
  }

  /// Maneja el evento de cancelar pago (limpiar estado de URL).
  void _onCancelarPago(
    CarritoCancelarPagoEvent event,
    Emitter<CarritoState> emit,
  ) {
    emit(state.copyWith(clearPagoData: true, clearError: true));
  }

}
