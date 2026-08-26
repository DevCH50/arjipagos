import 'dart:async';

import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaPagadosUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona la pantalla de pagos realizados.
///
/// Carga y refresca datos —no persiste selección ni comparte estado con el
/// carrito: los pagos que muestra ya están liquidados— y **atiende el push de
/// pago exitoso**.
///
/// El push llega con `campania: "pago"` y `accion: "pago_exitoso"`. Se escuchan
/// los tres canales, igual que en `BannerBloc`: app en primer plano
/// (`onMessage`), toque desde segundo plano (`onMessageOpenedApp`) y app cerrada
/// (`getInitialMessage`). El handler de `onBackgroundMessage` **no** entra aquí
/// a propósito: corre en un isolate aparte, sin acceso a este BLoC.
///
/// El push **no trae la URL ni el id del ticket**, por decisión del encargo al
/// backend: el push viaja por los servidores de Google y esa liga lleva datos
/// del pago. Con `alumno_id` basta — la app pide el ticket por su propia API
/// autenticada, que es lo que ya hace esta pantalla.
class EdoCtaPagadosBloc extends Bloc<EdoCtaPagadosEvent, EdoCtaPagadosState> {
  final EdoCtaPagadosUseCases edoCtaPagadosUseCases;

  StreamSubscription<RemoteMessage>? _fcmPrimerPlanoSub;
  StreamSubscription<RemoteMessage>? _fcmToqueSub;

  /// Clave y valores que marcan un push de pago exitoso.
  static const String _claveCampania = 'campania';
  static const String _claveAccion = 'accion';
  static const String _claveAlumnoId = 'alumno_id';
  static const String _claveTicketFolio = 'ticket_folio';
  static const String campaniaPago = 'pago';
  static const String _accionPagoExitoso = 'pago_exitoso';

  /// Los streams se inyectan para poder probar sin Firebase real, igual que en
  /// `BannerBloc` y `NotificacionBloc`.
  EdoCtaPagadosBloc(
    this.edoCtaPagadosUseCases, {
    Stream<RemoteMessage>? fcmPrimerPlanoStream,
    Stream<RemoteMessage>? fcmToqueStream,
    Future<RemoteMessage?> Function()? getInitialMessage,
  }) : super(EdoCtaPagadosState.initial()) {
    on<EdoCtaPagadosInitialEvent>(_onInitial);
    on<EdoCtaPagadosRefreshEvent>(_onRefresh);
    on<EdoCtaPagadosPushRecibidoEvent>(_onPushRecibido);
    on<EdoCtaPagadosNavegacionAtendidaEvent>(_onNavegacionAtendida);
    on<EdoCtaPagadosDestacadoAtendidoEvent>(_onDestacadoAtendido);
    on<EdoCtaPagadosLimpiarSesionEvent>(_onLimpiarSesion);

    _fcmPrimerPlanoSub =
        (fcmPrimerPlanoStream ?? FirebaseMessaging.onMessage).listen(_alLlegar);

    _fcmToqueSub = (fcmToqueStream ?? FirebaseMessaging.onMessageOpenedApp)
        .listen(_alLlegar);

    (getInitialMessage ?? FirebaseMessaging.instance.getInitialMessage)()
        .then((message) {
      if (message != null) {
        _alLlegar(message);
      }
    });
  }

  @override
  Future<void> close() {
    _fcmPrimerPlanoSub?.cancel();
    _fcmToqueSub?.cancel();
    return super.close();
  }

  /// Atiende un push, si es de los suyos.
  void _alLlegar(RemoteMessage message) {
    if (!_esDePago(message) || isClosed) {
      return;
    }
    add(EdoCtaPagadosPushRecibidoEvent(
      alumnoId: _leerAlumnoId(message),
      ticketFolio: _leerTexto(message, _claveTicketFolio),
    ));
  }

  /// Un push es de pagos solo si trae **las dos** claves de la convención.
  ///
  /// Es la misma que ya usan los banners (`campania: "banner"`), y respetarla es
  /// lo que evita que las pantallas se pisen entre ellas.
  bool _esDePago(RemoteMessage message) {
    return message.data[_claveCampania]?.toString() == campaniaPago &&
        message.data[_claveAccion]?.toString() == _accionPagoExitoso;
  }

  /// Lee una clave de texto de `data`, o `null` si no viene o viene vacía.
  ///
  /// El push trae además `ticket_id`, que aquí **se ignora a propósito**: la app
  /// no maneja ese identificador en ninguna parte —sus modelos de pago solo
  /// conocen el folio, que es lo que además se le enseña al usuario—. Guardarlo
  /// sin usarlo sería dejar basura. Si algún día hace falta, ahí está.
  String? _leerTexto(RemoteMessage message, String clave) {
    final String? crudo = message.data[clave]?.toString();
    return (crudo == null || crudo.isEmpty) ? null : crudo;
  }

  /// Lee `alumno_id`, que FCM entrega **siempre como texto**.
  ///
  /// Devuelve `null` si no viene —cobro repartido entre varios alumnos— o si no
  /// es un número: en ambos casos se abre la pantalla sin destacar a nadie, que
  /// es mejor que señalar al alumno equivocado.
  int? _leerAlumnoId(RemoteMessage message) {
    final String? crudo = message.data[_claveAlumnoId]?.toString();
    if (crudo == null || crudo.isEmpty) {
      return null;
    }
    return int.tryParse(crudo);
  }

  /// Recarga la lista y pide abrir la pantalla.
  ///
  /// Se recarga **siempre**, aunque el usuario ya esté en Pagos Realizados: el
  /// pago es de hace segundos y lo que hay en memoria todavía no lo tiene.
  Future<void> _onPushRecibido(
    EdoCtaPagadosPushRecibidoEvent event,
    Emitter<EdoCtaPagadosState> emit,
  ) async {
    AppLogger.info(
      'Push de pago exitoso recibido (alumno_id: ${event.alumnoId}, '
      'ticket_folio: ${event.ticketFolio})',
      tag: 'EdoCtaPagados',
    );
    await _cargarPagosRealizados(emit);
    emit(state.copyWith(
      debeNavegar: true,
      alumnoDestacadoId: event.alumnoId,
      folioDestacado: event.ticketFolio,
      // El `??` de `copyWith` no puede vaciar un campo nullable: si el push no
      // trae ninguna de las dos pistas, hay que limpiar a mano lo que quedara
      // de un push anterior.
      limpiarDestacado: event.alumnoId == null && event.ticketFolio == null,
    ));
  }

  /// La app ya navegó: se apaga la señal para no repetir el viaje.
  void _onNavegacionAtendida(
    EdoCtaPagadosNavegacionAtendidaEvent event,
    Emitter<EdoCtaPagadosState> emit,
  ) {
    emit(state.copyWith(debeNavegar: false));
  }

  /// La lista ya se desplazó y resaltó: se apaga el destacado.
  void _onDestacadoAtendido(
    EdoCtaPagadosDestacadoAtendidoEvent event,
    Emitter<EdoCtaPagadosState> emit,
  ) {
    emit(state.copyWith(limpiarDestacado: true));
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

  /// Devuelve el BLoC a su estado inicial al cerrar sesión.
  ///
  /// Estado inicial entero y no un `copyWith`: este último nunca vacía la lista,
  /// así que arrastraría los pagos del usuario que se va.
  void _onLimpiarSesion(
    EdoCtaPagadosLimpiarSesionEvent event,
    Emitter<EdoCtaPagadosState> emit,
  ) {
    emit(EdoCtaPagadosState.initial());
  }
}
