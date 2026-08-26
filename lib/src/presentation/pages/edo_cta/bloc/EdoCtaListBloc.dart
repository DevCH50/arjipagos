import 'dart:async';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/models/PoliticaEmisor.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado de la página de estados de cuenta.
///
/// Maneja la carga de estados de cuenta, selección de pagos
/// (respetando el orden de ID ascendente **dentro de cada ciclo**) y limpieza
/// de selección. Los pagos seleccionados se persisten vía
/// [SeleccionPagosStorage], que también los comparte con el carrito.
class EdoCtaListBloc extends Bloc<EdoCtaListEvent, EdoCtaListState> {
  final EdoCtaUseCases edoCtaUseCases;
  final SeleccionPagosStorage seleccionStorage;

  /// Reglas de este emisor: orden ascendente, tope y formato de la referencia.
  PoliticaEmisor get _politica =>
      ConfiguracionAdquira.para(emisorFiscalId).politica;

  /// Emisor fiscal del que se ocupa esta instancia.
  ///
  /// Es parte de su identidad, no un estado que cambie: hay un BLoC por emisor
  /// y ninguno sabe que existen los demás.
  final int emisorFiscalId;

  StreamSubscription<RemoteMessage>? _fcmPrimerPlanoSub;
  StreamSubscription<RemoteMessage>? _fcmToqueSub;

  /// Claves y valores de la convención del push de pago exitoso.
  ///
  /// Las mismas que usa `EdoCtaPagadosBloc`: un push es de pago solo si trae
  /// `campania` **y** `accion`. Se repiten aquí en vez de importarlas de aquel
  /// BLoC para no atar dos pantallas independientes.
  static const String _claveCampania = 'campania';
  static const String _claveAccion = 'accion';
  static const String _claveEmisorFiscal = 'emisorfiscal_id';
  static const String _campaniaPago = 'pago';
  static const String _accionPagoExitoso = 'pago_exitoso';

  /// Los streams se inyectan para poder probar sin Firebase real, igual que en
  /// `BannerBloc`, `NotificacionBloc` y `EdoCtaPagadosBloc`.
  EdoCtaListBloc(
    this.edoCtaUseCases,
    this.seleccionStorage, {
    required this.emisorFiscalId,
    Stream<RemoteMessage>? fcmPrimerPlanoStream,
    Stream<RemoteMessage>? fcmToqueStream,
  }) : super(EdoCtaListState.initial(emisorFiscalId)) {
    on<EdoCtaListInitialEvent>(_onInitial);
    on<EdoCtaListPagoConfirmadoEvent>(_onPagoConfirmado);
    on<EdoCtaListRefreshEvent>(_onRefresh);
    on<EdoCtaTogglePagoEvent>(_onTogglePago);
    on<EdoCtaLimpiarSeleccionEvent>(_onLimpiarSeleccion);
    on<EdoCtaRecargarSeleccionEvent>(_onRecargarSeleccion);
    on<EdoCtaListLimpiarSesionEvent>(_onLimpiarSesion);

    _fcmPrimerPlanoSub =
        (fcmPrimerPlanoStream ?? FirebaseMessaging.onMessage).listen(_alLlegar);
    _fcmToqueSub = (fcmToqueStream ?? FirebaseMessaging.onMessageOpenedApp)
        .listen(_alLlegar);
  }

  @override
  Future<void> close() {
    _fcmPrimerPlanoSub?.cancel();
    _fcmToqueSub?.cancel();
    return super.close();
  }

  /// Atiende un push, solo si confirma un pago **de este emisor fiscal**.
  ///
  /// No hay `getInitialMessage` aquí a propósito: de abrir la pantalla que toca
  /// cuando la app arranca desde el push ya se encarga `EdoCtaPagadosBloc`.
  /// Duplicarlo haría que dos pantallas pidieran navegar a la vez.
  void _alLlegar(RemoteMessage message) {
    if (isClosed || !_confirmaPagoDeEsteEmisor(message)) {
      return;
    }
    add(const EdoCtaListPagoConfirmadoEvent());
  }

  /// `true` si el push confirma un pago y es de este emisor.
  bool _confirmaPagoDeEsteEmisor(RemoteMessage message) {
    final bool esDePago =
        message.data[_claveCampania]?.toString() == _campaniaPago &&
            message.data[_claveAccion]?.toString() == _accionPagoExitoso;
    if (!esDePago) {
      return false;
    }
    return _leerEmisorFiscal(message) == emisorFiscalId;
  }

  /// Lee `emisorfiscal_id` del push, que FCM entrega **siempre como texto**.
  ///
  /// Si no viene o no es un número se asume el emisor predeterminado, que es
  /// como se comportaba la app cuando había un solo contrato: así un backend
  /// que aún no mande la clave sigue refrescando la lista de siempre en vez de
  /// no refrescar ninguna.
  int _leerEmisorFiscal(RemoteMessage message) {
    final String? crudo = message.data[_claveEmisorFiscal]?.toString();
    if (crudo == null || crudo.isEmpty) {
      return kEmisorFiscalPredeterminado;
    }
    return int.tryParse(crudo) ?? kEmisorFiscalPredeterminado;
  }

  /// Relee los pagos sin pagar tras confirmarse un cobro de este emisor.
  ///
  /// Se limpia la selección junto con la recarga: lo que se acaba de liquidar
  /// ya no está en la lista, y dejar marcados los IDs viejos daría un total y
  /// una referencia que no corresponden a nada. Es lo mismo que hace el
  /// refresco normal.
  Future<void> _onPagoConfirmado(
    EdoCtaListPagoConfirmadoEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    AppLogger.info(
      'Push de pago confirmado para el emisor fiscal $emisorFiscalId: '
      'se releen sus pagos sin pagar',
      tag: 'EdoCta',
    );
    await seleccionStorage.guardar({});
    await _cargarEstadosDeCuenta(emit, limpiarSeleccion: true);
  }

  /// Carga inicial de estados de cuenta y pagos seleccionados guardados.
  Future<void> _onInitial(
    EdoCtaListInitialEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    // Cargar pagos seleccionados guardados
    final pagosGuardados = await seleccionStorage.cargar();
    if (pagosGuardados.isNotEmpty) {
      emit(state.copyWith(pagosSeleccionados: pagosGuardados));
    }
    await _cargarEstadosDeCuenta(emit);
  }

  /// Devuelve el BLoC a su estado inicial al cerrar sesión.
  ///
  /// Se emite el estado inicial entero y no un `copyWith`: este último nunca
  /// vacía `alumnos` ni `response`, así que arrastraría los datos del usuario
  /// que se va. Ver [EdoCtaListLimpiarSesionEvent].
  void _onLimpiarSesion(
    EdoCtaListLimpiarSesionEvent event,
    Emitter<EdoCtaListState> emit,
  ) {
    emit(EdoCtaListState.initial(emisorFiscalId));
  }

  /// Refresca la lista de estados de cuenta.
  Future<void> _onRefresh(
    EdoCtaListRefreshEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    // Al refrescar, limpiamos las selecciones (en memoria y storage)
    seleccionStorage.guardar({});
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
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error inesperado cargando estados de cuenta: $e',
          tag: 'EdoCta');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: mensajeErrorRed(e),
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

    // El ciclo del pago delimita el ámbito de toda la regla de selección.
    final cicloId = pago.cicloId;

    // Obtener los pagos disponibles en internet DEL MISMO CICLO Y DEL MISMO
    // EMISOR FISCAL, ordenados por ID. Filtrar por ciclo es lo que impide que
    // un pago de otro ciclo condicione el orden ascendente de éste; filtrar por
    // emisor impide algo peor: sin ello, para marcar el primer pago de "Otros
    // pagos" habría que haber marcado antes los de "Pagos Pendientes" del mismo
    // ciclo, que están en otra pantalla y en otro carrito. El renglón quedaría
    // bloqueado sin explicación posible.
    final pagosDisponibles = alumno.estadoDeCuenta
        .where((e) =>
            e.estaDisponibleEnInternet &&
            e.cicloId == cicloId &&
            e.emisorFiscalId == pago.emisorFiscalId)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idsDisponibles = pagosDisponibles.map((e) => e.id).toList();

    // Obtener los pagos actualmente seleccionados para este alumno en el ciclo
    final pagosActuales = List<int>.from(state.pagosDe(cicloId, alumnoId));
    final estaSeleccionado = pagosActuales.contains(pagoId);

    if (estaSeleccionado) {
      // Deseleccionar
      if (pago.aceptaPagosDiversos && _politica.exigeOrdenAscendente) {
        // Si acepta pagos diversos, deseleccionar también los de ID mayor.
        //
        // Acotado a `idsDisponibles` —mismo ciclo y mismo emisor—. El filtro
        // por emisor hace falta porque la respuesta del servidor trae los
        // pagos de todos: sin él, desmarcar aquí arrastraría renglones que
        // pertenecen a otra pantalla y a otro contrato.
        pagosActuales
            .removeWhere((id) => id >= pagoId && idsDisponibles.contains(id));
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
      // La referencia agrega los pagos de TODOS los ciclos, igual que
      // CarritoState.referenciaPago: el ámbito por ciclo aplica al orden de
      // selección, no al cobro.
      //
      // Lo que sí acota el cobro es el emisor fiscal: cada uno se cobra en su
      // propia transacción y con su propia referencia. Contar aquí los pagos
      // del otro emisor daría por alcanzado un tope que esta referencia no va
      // a tener, y bloquearía la selección sin motivo.
      final idsDelEmisor = <int>{};
      for (final a in state.alumnos ?? const []) {
        for (final p in a.estadoDeCuenta) {
          if (p.emisorFiscalId == pago.emisorFiscalId) {
            idsDelEmisor.add(p.id);
          }
        }
      }

      final allIds = <int>[];
      state.pagosSeleccionados.forEach((ciclo, alumnos) {
        alumnos.forEach((alumnoIdMapa, ids) {
          allIds.addAll(ids.where(idsDelEmisor.contains));
        });
      });
      allIds.add(pagoId);

      final refSimulada = _politica.generarReferencia(allIds);
      if (!_politica.referenciaDentroDelLimite(refSimulada)) {
        AppLogger.warning(
          'Tope máximo de referencia alcanzado\n'
          '  referencia  : "$refSimulada"\n'
          '  longitud    : ${refSimulada.length} chars\n'
          '  límite máx  : ${_politica.maxLongitudReferencia} chars',
          tag: 'CARRITO',
        );
        emit(state.copyWith(
          errorMessage: AppStrings.edoCtaReferenciaLimiteAlcanzado,
        ));
        emit(state.copyWith(errorMessage: null));
        return;
      }

      if (pago.aceptaPagosDiversos && _politica.exigeOrdenAscendente) {
        // Verificar que se puede seleccionar (orden ascendente)
        if (state.puedeSelecionarPago(cicloId, alumnoId, pagoId, idsDisponibles)) {
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

    // Crear nuevo mapa de selecciones, tocando solo el ciclo afectado
    final nuevosSeleccionados = <int, Map<int, List<int>>>{};
    state.pagosSeleccionados.forEach((ciclo, alumnos) {
      nuevosSeleccionados[ciclo] = Map<int, List<int>>.from(alumnos);
    });

    final alumnosDelCiclo =
        Map<int, List<int>>.from(nuevosSeleccionados[cicloId] ?? {});
    if (pagosActuales.isEmpty) {
      alumnosDelCiclo.remove(alumnoId);
    } else {
      alumnosDelCiclo[alumnoId] = pagosActuales;
    }

    if (alumnosDelCiclo.isEmpty) {
      nuevosSeleccionados.remove(cicloId);
    } else {
      nuevosSeleccionados[cicloId] = alumnosDelCiclo;
    }

    emit(state.copyWith(pagosSeleccionados: nuevosSeleccionados));

    // Guardar en storage
    seleccionStorage.guardar(nuevosSeleccionados);
  }

  /// Limpia todas las selecciones.
  void _onLimpiarSeleccion(
    EdoCtaLimpiarSeleccionEvent event,
    Emitter<EdoCtaListState> emit,
  ) {
    emit(state.copyWith(pagosSeleccionados: {}));
    // Limpiar del storage
    seleccionStorage.guardar({});
  }

  /// Recarga los pagos seleccionados desde el storage.
  /// Se usa para sincronizar después de regresar del carrito.
  Future<void> _onRecargarSeleccion(
    EdoCtaRecargarSeleccionEvent event,
    Emitter<EdoCtaListState> emit,
  ) async {
    final pagosGuardados = await seleccionStorage.cargar();
    emit(state.copyWith(pagosSeleccionados: pagosGuardados));
  }
}
