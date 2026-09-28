import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/data/api/pasarela_pago.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/OpenpayService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/ErrorCobroOpenpay.dart';
import 'package:arjipagos/src/domain/models/OpenpayCheckout.dart';
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

  /// Emisor fiscal de este carrito.
  ///
  /// Parte de su identidad, no un estado que cambie: hay un carrito por emisor
  /// y ninguno sabe que existen los demás.
  final int emisorFiscalId;

  /// Cobro por OpenPay. Solo lo usan los emisores con
  /// [PasarelaPago.openpay]; para los de Adquira nunca se llama.
  final OpenpayService _openpayService;

  CarritoBloc({
    required SeleccionPagosStorage seleccionStorage,
    required AuthUseCases authUseCases,
    required EdoCtaUseCases edoCtaUseCases,
    required this.emisorFiscalId,
    OpenpayService? openpayService,
  }) : _seleccionStorage = seleccionStorage,
       _authUseCases = authUseCases,
       _edoCtaUseCases = edoCtaUseCases,
       // Opcional para que los tests puedan meter un doble sin montar el
       // registro entero. Construirlo no hace nada: solo guarda el
       // `authUseCases` que ya recibimos, y la petición sale en `_onPagar`.
       _openpayService = openpayService ?? OpenpayService(authUseCases),
       super(CarritoState(emisorFiscalActivo: emisorFiscalId)) {
    on<CarritoInitialEvent>(_onInitial);
    on<CarritoQuitarPagoEvent>(_onQuitarPago);
    on<CarritoLimpiarEvent>(_onLimpiar);
    on<CarritoPagarEvent>(_onPagar);
    on<CarritoPagoExitosoEvent>(_onPagoExitoso);
    on<CarritoPagoFallidoEvent>(_onPagoFallido);
    on<CarritoCancelarPagoEvent>(_onCancelarPago);
    on<CarritoLimpiarErrorEvent>(_onLimpiarError);
  }

  /// Descarta el error que el usuario ya vio. Ver [CarritoLimpiarErrorEvent].
  void _onLimpiarError(
    CarritoLimpiarErrorEvent event,
    Emitter<CarritoState> emit,
  ) {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
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
        emit(
          state.copyWith(isLoading: false, pagosSeleccionados: {}, alumnos: []),
        );
        return;
      }

      // Obtener datos de alumnos desde el servidor, acotados al emisor de este
      // carrito: un carrito nunca mezcla emisores, porque sería una sola
      // transacción hacia dos cuentas bancarias distintas.
      final result = await _edoCtaUseCases.getEstadosDeCuenta.run(
        emisorFiscalId: emisorFiscalId,
      );

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
            '(${estadoCargado.longitudReferencia}/${estadoCargado.maxLongitudReferencia} chars)',
            tag: 'Carrito',
          );
          emit(
            estadoCargado.copyWith(
              errorMessage: AppStrings.carritoReferenciaExcede,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(isLoading: false, errorMessage: (result as Error).msg),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error inesperado cargando el carrito',
        error: e,
        tag: 'Carrito',
      );
      emit(state.copyWith(isLoading: false, errorMessage: mensajeErrorRed(e)));
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
        '(${state.longitudReferencia}/${state.maxLongitudReferencia} chars)',
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
        emit(
          state.copyWith(
            isProcesandoPago: false,
            errorMessage: AppStrings.errorSesionInvalida,
          ),
        );
        return;
      }

      // Cada carrito cobra por el contrato de su emisor fiscal. El importe, la
      // referencia y los renglones que se ven ya vienen acotados a él.
      final ConfiguracionAdquira configuracion = ConfiguracionAdquira.para(
        emisorFiscalId,
      );

      if (!ConfiguracionAdquira.conoce(emisorFiscalId)) {
        AppLogger.warning(
          'Emisor fiscal $emisorFiscalId desconocido en esta versión: se cobra '
          'con ${configuracion.descripcion}',
          tag: 'Carrito',
        );
      }

      // Cada pasarela consigue la URL del WebView a su manera. A partir de que
      // esa URL existe, la pantalla de pago es idéntica para las dos.
      switch (configuracion.pasarela) {
        case PasarelaPago.adquira:
          _cobrarPorAdquira(configuracion, authResponse, emit);
        case PasarelaPago.openpay:
          await _cobrarPorOpenpay(configuracion, authResponse, emit);
      }
    } catch (e) {
      AppLogger.error('Error al iniciar el pago', error: e, tag: 'Carrito');
      emit(
        state.copyWith(
          isProcesandoPago: false,
          errorMessage: mensajeErrorRed(e),
        ),
      );
    }
  }

  /// Cobro por Adquira — **el camino de siempre, sin un solo cambio.**
  ///
  /// La app arma el formulario con los parámetros del contrato y el WebView le
  /// hace un POST al endpoint del comercio. Lo usa el emisor fiscal 1 ("Pagos
  /// Pendientes").
  void _cobrarPorAdquira(
    ConfiguracionAdquira configuracion,
    AuthResponse authResponse,
    Emitter<CarritoState> emit,
  ) {
    if (configuracion.esProvisional) {
      AppLogger.warning(
        'CONFIGURACIÓN PROVISIONAL — ${configuracion.descripcion} está usando '
        'los datos de otro contrato (idexpress ${configuracion.idExpress}): '
        'el cobro entra en la cuenta bancaria equivocada',
        tag: 'Carrito',
      );
    }

    final pagoRequest = PagoRequest(
      token: authResponse.accessToken,
      userId: authResponse.user.id,
      importe: state.totalAPagar,
      urlRetorno: Endpoints.pagoUrlRetorno,
      referencia: state.referenciaPago,
      emisorFiscalId: emisorFiscalId,
      idExpress: configuracion.idExpress,
      financiamiento: configuracion.financiamiento,
      moneda: configuracion.moneda,
      tipo: configuracion.tipo,
      tipoPago: configuracion.tipoPago,
      plazos: configuracion.plazos,
      mediosPago: configuracion.mediosPago,
    );

    AppLogger.debug(
      'Pago — ref: ${pagoRequest.referencia} | importe: ${pagoRequest.importe} '
      '| userId: ${pagoRequest.userId} | ${configuracion.descripcion}',
      tag: 'Carrito',
    );

    emit(
      state.copyWith(
        isProcesandoPago: false,
        pagoData: {
          'url': configuracion.endpoint,
          'params': pagoRequest.toMap(),
          'token': pagoRequest.token,
        },
      ),
    );
  }

  /// Cobro por OpenPay — «Otros pagos», emisor fiscal 2.
  ///
  /// Le pide al backend la URL del formulario alojado de OpenPay y la deja en
  /// `pagoData` para que el WebView la abra. Tres diferencias con Adquira, y
  /// las tres son deliberadas:
  ///
  /// 1. **Hay una petición HTTP antes de navegar.** Con Adquira la URL es
  ///    constante y se conoce sin preguntar; aquí el cobro se crea en OpenPay
  ///    y hasta que no responde no hay a dónde ir. Por eso esto puede fallar
  ///    antes de que el usuario vea nada, y el error se enseña en el carrito.
  /// 2. **`params` va vacío.** Es la señal de que el WebView debe cargar con
  ///    un GET: la URL de OpenPay ya lleva dentro el identificador del cobro y
  ///    no hay formulario que enviar.
  /// 3. **No se manda el importe.** El backend lo calcula de los cargos que
  ///    nombra la referencia. `state.totalAPagar` solo se registra en el log
  ///    para poder contrastarlo; si no coincidieran, manda el del servidor.
  Future<void> _cobrarPorOpenpay(
    ConfiguracionAdquira configuracion,
    AuthResponse authResponse,
    Emitter<CarritoState> emit,
  ) async {
    final String referencia = state.referenciaPago;

    AppLogger.debug(
      'Cobro por OpenPay — ref: $referencia | total en pantalla: '
      '${state.totalAPagar} | userId: ${authResponse.user.id} | '
      '${configuracion.descripcion}',
      tag: 'Carrito',
    );

    final resultado = await _openpayService.crearCargo(referencia);

    // El evento pudo cerrarse mientras esperábamos —el usuario salió del
    // carrito, o se cerró la sesión—. Emitir aquí reventaría.
    if (emit.isDone) {
      AppLogger.warning(
        'El carrito se cerró antes de recibir la URL de OpenPay — '
        'ref $referencia',
        tag: 'Carrito',
      );
      return;
    }

    if (resultado is! Success<OpenpayCheckout>) {
      final String mensaje = resultado is Error<OpenpayCheckout>
          ? resultado.msg
          : AppStrings.openpayNoSePudoIniciar;

      emit(
        state.copyWith(
          isProcesandoPago: false,
          errorMessage: mensaje,
          // El carrito decide qué hacer al cerrar el diálogo: login (401),
          // recargar los cargos (422) o nada.
          motivoFallo: resultado is ErrorCobroOpenpay
              ? resultado.motivo
              : MotivoFalloCobro.otro,
        ),
      );
      return;
    }

    final OpenpayCheckout checkout = resultado.data;

    emit(
      state.copyWith(
        isProcesandoPago: false,
        pagoData: {
          'url': checkout.url,
          // Vacío = cargar con GET. Ver `PagoWebViewPage._cargarPagina`.
          'params': const <String, String>{},
          // Viaja para no cambiar la forma de `pagoData`, pero el WebView NO
          // se lo manda a OpenPay: sería filtrarle la sesión del tutor a un
          // tercero. Ver `PagoWebViewPage._cargarPagina`.
          'token': authResponse.accessToken,
          // Para preguntar en qué quedó el cobro si el tutor cierra el
          // WebView sin que llegue el retorno. Ver `PagoWebViewArgs.orderId`.
          'orderId': checkout.orderId,
        },
      ),
    );
  }

  /// Maneja el evento de pago exitoso.
  Future<void> _onPagoExitoso(
    CarritoPagoExitosoEvent event,
    Emitter<CarritoState> emit,
  ) async {
    // Limpiar el carrito del storage
    await _seleccionStorage.guardar({});

    emit(
      state.copyWith(
        pagosSeleccionados: {},
        pagoExitoso: true,
        mensajeExito: AppStrings.pagoRealizadoConExito,
        clearPagoData: true,
      ),
    );
  }

  /// Maneja el evento de pago fallido.
  void _onPagoFallido(
    CarritoPagoFallidoEvent event,
    Emitter<CarritoState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.mensaje, clearPagoData: true));
  }

  /// Maneja el evento de cancelar pago (limpiar estado de URL).
  void _onCancelarPago(
    CarritoCancelarPagoEvent event,
    Emitter<CarritoState> emit,
  ) {
    emit(state.copyWith(clearPagoData: true, clearError: true));
  }
}
