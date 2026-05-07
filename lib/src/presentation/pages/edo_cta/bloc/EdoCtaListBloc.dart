import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Clave para guardar los pagos seleccionados en SharedPreferences.
const String _kPagosSeleccionadosKey = 'edo_cta_pagos_seleccionados';

/// BLoC que gestiona el estado de la página de estados de cuenta.
///
/// Maneja la carga de estados de cuenta, selección de pagos
/// (respetando el orden de ID ascendente) y limpieza de selección.
/// Los pagos seleccionados se persisten en SharedPreferences.
class EdoCtaListBloc extends Bloc<EdoCtaListEvent, EdoCtaListState> {
  final EdoCtaUseCases edoCtaUseCases;
  final SharedPref sharedPref;

  EdoCtaListBloc(this.edoCtaUseCases, this.sharedPref) : super(EdoCtaListState.initial()) {
    on<EdoCtaListInitialEvent>(_onInitial);
    on<EdoCtaListRefreshEvent>(_onRefresh);
    on<EdoCtaTogglePagoEvent>(_onTogglePago);
    on<EdoCtaLimpiarSeleccionEvent>(_onLimpiarSeleccion);
    on<EdoCtaRecargarSeleccionEvent>(_onRecargarSeleccion);
  }

  /// Carga inicial de estados de cuenta y pagos seleccionados guardados.
  Future<void> _onInitial(
    EdoCtaListInitialEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    // Cargar pagos seleccionados guardados
    final pagosGuardados = await _cargarPagosSeleccionados();
    if (pagosGuardados.isNotEmpty) {
      emit(state.copyWith(pagosSeleccionados: pagosGuardados));
    }
    await _cargarEstadosDeCuenta(emit);
  }

  /// Refresca la lista de estados de cuenta.
  Future<void> _onRefresh(
    EdoCtaListRefreshEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    // Al refrescar, limpiamos las selecciones (en memoria y storage)
    _guardarPagosSeleccionados({});
    await _cargarEstadosDeCuenta(emit, limpiarSeleccion: true);
  }

  /// Carga los estados de cuenta desde el servidor.
  Future<void> _cargarEstadosDeCuenta(
    Emitter<EdoCtaListState> emit, {
    bool limpiarSeleccion = false,
  }) async {
    try {
      emit(state.copyWith(
        isLoading: true,
        errorMessage: null,
        pagosSeleccionados: limpiarSeleccion ? {} : null,
      ));

      final result = await edoCtaUseCases.getEstadosDeCuenta.run();

      if (result is utils.Success<EstadosDeCuentaResponse>) {
        final data = result.data;
        emit(state.copyWith(
          alumnos: data.alumnos,
          response: data,
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
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado: $e',
      ));
    }
  }

  /// Maneja la selección/deselección de un pago.
  ///
  /// Si aceptaPagosDiversos es true, respeta el orden de ID ascendente:
  /// - Solo puede seleccionar si todos los anteriores están seleccionados.
  /// - Al deseleccionar, también deselecciona los de ID mayor.
  ///
  /// Si aceptaPagosDiversos es false, se puede marcar/desmarcar libremente.
  void _onTogglePago(
    EdoCtaTogglePagoEvent event,
    Emitter<EdoCtaListState> emit,
  ) {
    final alumnoId = event.alumnoId;
    final pagoId = event.pagoId;

    // Buscar el alumno y sus pagos
    final alumno = state.alumnos?.firstWhere(
      (a) => a.alumnoId == alumnoId,
      orElse: () => throw Exception('Alumno no encontrado'),
    );

    if (alumno == null) {
      return;
    }

    // Buscar el pago específico para verificar aceptaPagosDiversos
    final pago = alumno.estadoDeCuenta.firstWhere(
      (e) => e.id == pagoId,
      orElse: () => throw Exception('Pago no encontrado'),
    );

    // Obtener solo los pagos disponibles en internet, ordenados por ID
    final pagosDisponibles = alumno.estadoDeCuenta
        .where((e) => e.estaDisponibleEnInternet)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idsDisponibles = pagosDisponibles.map((e) => e.id).toList();

    // Obtener los pagos actualmente seleccionados para este alumno
    final pagosActuales = List<int>.from(state.pagosSeleccionados[alumnoId] ?? []);
    final estaSeleccionado = pagosActuales.contains(pagoId);

    if (estaSeleccionado) {
      // Deseleccionar
      if (pago.aceptaPagosDiversos) {
        // Si acepta pagos diversos, deseleccionar también los de ID mayor
        pagosActuales.removeWhere((id) => id >= pagoId);
      } else {
        // Si no acepta pagos diversos, solo deseleccionar este pago
        pagosActuales.remove(pagoId);
      }
    } else {
      // Seleccionar — validar primero que la referencia resultante no exceda el límite.
      //
      // Simular cómo quedaría la referencia si se añade este pago.
      // Se replica la misma lógica que CarritoState.referenciaPago para
      // garantizar consistencia entre ambos puntos de validación.
      final mapaSimulado = Map<int, List<int>>.from(state.pagosSeleccionados);
      final idsSimulados = List<int>.from(mapaSimulado[alumnoId] ?? [])
        ..add(pagoId);
      mapaSimulado[alumnoId] = idsSimulados;

      final allIds = <int>[];
      for (final ids in mapaSimulado.values) {
        allIds.addAll(ids);
      }

      final refSimulada = AppConstants.generarReferencia(allIds);
      if (refSimulada.length > AppConstants.maxLongitudReferencia) {
        AppLogger.warning(
          'Tope máximo de referencia alcanzado\n'
          '  referencia  : "$refSimulada"\n'
          '  longitud    : ${refSimulada.length} chars\n'
          '  límite máx  : ${AppConstants.maxLongitudReferencia} chars',
          tag: 'CARRITO',
        );
        emit(state.copyWith(
          errorMessage: AppStrings.edoCtaReferenciaLimiteAlcanzado,
        ));
        emit(state.copyWith(errorMessage: null));
        return;
      }

      if (pago.aceptaPagosDiversos) {
        // Verificar que se puede seleccionar (orden ascendente)
        if (state.puedeSelecionarPago(alumnoId, pagoId, idsDisponibles)) {
          pagosActuales.add(pagoId);
          pagosActuales.sort(); // Mantener ordenados
        } else {
          // No se puede seleccionar, emitir error temporal
          emit(state.copyWith(
            errorMessage: AppStrings.edoCtaOrdenPagosMsg,
          ));
          // Limpiar el error después de mostrarlo
          emit(state.copyWith(errorMessage: null));
          return;
        }
      } else {
        // Sin restricción de orden, seleccionar directamente
        pagosActuales.add(pagoId);
        pagosActuales.sort(); // Mantener ordenados para consistencia
      }
    }

    // Crear nuevo mapa de selecciones
    final nuevosSeleccionados = Map<int, List<int>>.from(state.pagosSeleccionados);
    if (pagosActuales.isEmpty) {
      nuevosSeleccionados.remove(alumnoId);
    } else {
      nuevosSeleccionados[alumnoId] = pagosActuales;
    }

    emit(state.copyWith(pagosSeleccionados: nuevosSeleccionados));

    // Guardar en storage
    _guardarPagosSeleccionados(nuevosSeleccionados);
  }

  /// Limpia todas las selecciones.
  void _onLimpiarSeleccion(
    EdoCtaLimpiarSeleccionEvent event,
    Emitter<EdoCtaListState> emit,
  ) {
    emit(state.copyWith(pagosSeleccionados: {}));
    // Limpiar del storage
    _guardarPagosSeleccionados({});
  }

  /// Recarga los pagos seleccionados desde el storage.
  /// Se usa para sincronizar después de regresar del carrito.
  Future<void> _onRecargarSeleccion(
    EdoCtaRecargarSeleccionEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    final pagosGuardados = await _cargarPagosSeleccionados();
    emit(state.copyWith(pagosSeleccionados: pagosGuardados));
  }

  /// Guarda los pagos seleccionados en SharedPreferences.
  Future<void> _guardarPagosSeleccionados(Map<int, List<int>> pagos) async {
    try {
      // Convertir Map<int, List<int>> a Map<String, dynamic> para JSON
      final Map<String, dynamic> jsonMap = {};
      pagos.forEach((key, value) {
        jsonMap[key.toString()] = value;
      });
      await sharedPref.save(_kPagosSeleccionadosKey, jsonMap);
    } catch (e) {
      // Si hay error al guardar, solo lo ignoramos (no es crítico)
    }
  }

  /// Carga los pagos seleccionados desde SharedPreferences.
  Future<Map<int, List<int>>> _cargarPagosSeleccionados() async {
    try {
      final data = await sharedPref.readMap(_kPagosSeleccionadosKey);
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
      // Si hay error al leer, retornar vacío
      return {};
    }
  }
}
