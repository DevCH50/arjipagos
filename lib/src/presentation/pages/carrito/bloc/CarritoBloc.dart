import 'package:flutter/foundation.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
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
  final SharedPref _sharedPref;
  final AuthUseCases _authUseCases;
  final EdoCtaUseCases _edoCtaUseCases;

  static const String _storageKey = 'edo_cta_pagos_seleccionados';

  CarritoBloc({
    required SharedPref sharedPref,
    required AuthUseCases authUseCases,
    required EdoCtaUseCases edoCtaUseCases,
  })  : _sharedPref = sharedPref,
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
      final pagosSeleccionados = await _cargarPagosSeleccionados();

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
        emit(state.copyWith(
          isLoading: false,
          alumnos: response.alumnos,
          pagosSeleccionados: pagosSeleccionados,
        ));
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
  Future<void> _onQuitarPago(
    CarritoQuitarPagoEvent event,
    Emitter<CarritoState> emit,
  ) async {
    final nuevosPagos = Map<int, List<int>>.from(state.pagosSeleccionados);

    if (nuevosPagos.containsKey(event.alumnoId)) {
      final pagosAlumno = List<int>.from(nuevosPagos[event.alumnoId]!);
      pagosAlumno.remove(event.pagoId);

      if (pagosAlumno.isEmpty) {
        nuevosPagos.remove(event.alumnoId);
      } else {
        nuevosPagos[event.alumnoId] = pagosAlumno;
      }
    }

    emit(state.copyWith(pagosSeleccionados: nuevosPagos));
    await _guardarPagosSeleccionados(nuevosPagos);
  }

  /// Maneja el evento de limpiar el carrito.
  Future<void> _onLimpiar(
    CarritoLimpiarEvent event,
    Emitter<CarritoState> emit,
  ) async {
    emit(state.copyWith(pagosSeleccionados: {}));
    await _guardarPagosSeleccionados({});
  }

  /// Maneja el evento de iniciar el pago.
  Future<void> _onPagar(
    CarritoPagarEvent event,
    Emitter<CarritoState> emit,
  ) async {
    if (state.cantidadPagos == 0) {
      emit(state.copyWith(errorMessage: 'No hay pagos seleccionados'));
      return;
    }

    emit(state.copyWith(isProcesandoPago: true, clearError: true));

    try {
      // Obtener datos de autenticación
      final authResponse = await _authUseCases.getUserSession.run();

      if (authResponse == null) {
        emit(state.copyWith(
          isProcesandoPago: false,
          errorMessage: 'Sesión no válida',
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

      // Log para debug
      debugPrint('=== DATOS DE PAGO ===');
      debugPrint('Referencia: ${pagoRequest.referencia}');
      debugPrint('Importe: ${pagoRequest.importe}');
      debugPrint('User ID: ${pagoRequest.userId}');
      debugPrint('URL Retorno: ${pagoRequest.urlRetorno}');
      debugPrint('Params: ${pagoRequest.toMap()}');
      debugPrint('=====================');

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
    await _guardarPagosSeleccionados({});

    emit(state.copyWith(
      pagosSeleccionados: {},
      pagoExitoso: true,
      mensajeExito: 'Pago realizado con éxito',
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

  /// Carga los pagos seleccionados desde SharedPreferences.
  Future<Map<int, List<int>>> _cargarPagosSeleccionados() async {
    try {
      final data = await _sharedPref.readMap(_storageKey);
      if (data == null) {
        return {};
      }

      // Convertir Map<String, dynamic> a Map<int, List<int>>
      final Map<int, List<int>> result = {};
      data.forEach((key, value) {
        final alumnoId = int.tryParse(key);
        if (alumnoId != null && value is List) {
          result[alumnoId] = List<int>.from(value.map((e) => e as int));
        }
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Guarda los pagos seleccionados en SharedPreferences.
  Future<void> _guardarPagosSeleccionados(Map<int, List<int>> pagos) async {
    // Convertir Map<int, List<int>> a Map<String, dynamic> para JSON
    final Map<String, dynamic> jsonMap = {};
    pagos.forEach((key, value) {
      jsonMap[key.toString()] = value;
    });
    await _sharedPref.save(_storageKey, jsonMap);
  }
}
