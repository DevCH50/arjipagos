import 'dart:async';

import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/useCases/banners/BannerUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerState.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC de la tirilla de banners del Menú Principal.
///
/// Un fallo aquí **no debe estorbar**: los banners son contenido informativo,
/// no parte del flujo de pago. Por eso el error se guarda en el estado y se
/// registra en el log, pero la pantalla se limita a no mostrar la tirilla; no
/// hay diálogo de error que interrumpa al usuario al entrar al menú.
///
/// ## Refresco desde el servidor
///
/// El backend avisa de altas, cambios y bajas con un push cuyo `data` trae
/// `campania: "banner"` y `accion: "refrescar_banners"`. Al recibirlo se vuelve
/// a pedir la lista **entera**: nunca se parchea la local con lo que trae el
/// push, porque el servidor manda el catálogo ya vigente y ya ordenado.
///
/// Se atienden los dos canales que pueden llegar con la app viva —mensaje en
/// primer plano y toque en la notificación desde segundo plano—. El handler de
/// `onBackgroundMessage` **no** entra aquí a propósito: corre en un isolate
/// aparte, sin acceso a este BLoC ni al árbol de widgets, así que no tiene nada
/// que refrescar. Ese hueco lo cubre la tirilla recargando al volver del
/// segundo plano, que además salva el caso de que iOS descarte el push
/// silencioso por bajo consumo.
class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final BannerUseCases bannerUseCases;

  StreamSubscription<RemoteMessage>? _fcmPrimerPlanoSub;
  StreamSubscription<RemoteMessage>? _fcmToqueSub;

  /// Clave y valores que marcan un push de banners.
  static const String _claveCampania = 'campania';
  static const String _claveAccion = 'accion';
  static const String _claveBannerId = 'banner_id';
  static const String _campaniaBanner = 'banner';
  static const String _accionRefrescar = 'refrescar_banners';

  /// Los streams se inyectan para poder probar el refresco sin Firebase real,
  /// igual que en `NotificacionBloc`.
  BannerBloc(
    this.bannerUseCases, {
    Stream<RemoteMessage>? fcmPrimerPlanoStream,
    Stream<RemoteMessage>? fcmToqueStream,
    Future<RemoteMessage?> Function()? getInitialMessage,
  }) : super(BannerState.initial()) {
    on<BannerCargarEvent>(_onCargar);
    on<BannerRefrescarEvent>(_onRefrescar);
    on<BannerAbrirDetalleEvent>(_onAbrirDetalle);
    on<BannerDetalleAtendidoEvent>(_onDetalleAtendido);

    // App abierta: FCM entrega el mensaje directamente.
    _fcmPrimerPlanoSub =
        (fcmPrimerPlanoStream ?? FirebaseMessaging.onMessage).listen(_alLlegar);

    // App en segundo plano y el usuario toca la notificación.
    _fcmToqueSub = (fcmToqueStream ?? FirebaseMessaging.onMessageOpenedApp)
        .listen(_alLlegar);

    // App cerrada: la notificación la lanzó. La lista ya se pide sola al
    // montarse la tirilla, así que aquí solo interesa el id para abrir la nota.
    (getInitialMessage ?? FirebaseMessaging.instance.getInitialMessage)()
        .then((message) {
      if (message != null && _esDeBanners(message)) {
        _abrirSiTraeId(message);
      }
    });
  }

  /// Decide qué hacer con un mensaje que llega con la app viva.
  void _alLlegar(RemoteMessage message) {
    if (!_esDeBanners(message)) {
      return;
    }
    if (isClosed) {
      return;
    }

    add(const BannerRefrescarEvent());
    _abrirSiTraeId(message);
  }

  /// `true` solo si el push es de los que piden recargar la tirilla.
  ///
  /// Se exigen las dos claves: un mensaje de otra campaña que por casualidad
  /// llevara `accion` no debe mover los banners.
  bool _esDeBanners(RemoteMessage message) {
    return message.data[_claveCampania]?.toString() == _campaniaBanner &&
        message.data[_claveAccion]?.toString() == _accionRefrescar;
  }

  /// Pide abrir la nota si el push trae `banner_id`.
  ///
  /// El id falta cuando el aviso se eliminó; entonces solo se recarga.
  void _abrirSiTraeId(RemoteMessage message) {
    final String id = message.data[_claveBannerId]?.toString() ?? '';
    if (id.isEmpty || isClosed) {
      return;
    }
    add(BannerAbrirDetalleEvent(id));
  }

  /// Carga inicial: muestra el esqueleto mientras llega la respuesta.
  Future<void> _onCargar(
    BannerCargarEvent event,
    Emitter<BannerState> emit,
  ) {
    return _pedirBanners(emit, mostrarEsqueleto: true);
  }

  /// Recarga silenciosa: la tirilla no parpadea.
  Future<void> _onRefrescar(
    BannerRefrescarEvent event,
    Emitter<BannerState> emit,
  ) {
    return _pedirBanners(emit, mostrarEsqueleto: false);
  }

  /// Anota qué nota abrir y pide la lista, por si el aviso es recién publicado.
  Future<void> _onAbrirDetalle(
    BannerAbrirDetalleEvent event,
    Emitter<BannerState> emit,
  ) {
    emit(state.copyWith(bannerIdAAbrir: event.bannerId));
    return _pedirBanners(emit, mostrarEsqueleto: false);
  }

  /// La pantalla ya abrió el modal: se suelta la petición.
  void _onDetalleAtendido(
    BannerDetalleAtendidoEvent event,
    Emitter<BannerState> emit,
  ) {
    emit(state.sinBannerAAbrir());
  }

  /// Consulta los banners y emite el estado correspondiente.
  Future<void> _pedirBanners(
    Emitter<BannerState> emit, {
    required bool mostrarEsqueleto,
  }) async {
    try {
      if (mostrarEsqueleto) {
        emit(state.copyWith(isLoading: true, errorMessage: null));
      }

      final result = await bannerUseCases.getBanners.run();

      if (result is utils.Success<BannersResponse>) {
        emit(state.copyWith(
          banners: result.data.banners,
          isLoading: false,
          errorMessage: null,
        ));
      } else if (result is utils.Error<BannersResponse>) {
        // Se conserva la tirilla anterior si ya había una cargada: al usuario
        // le sirve más el contenido viejo que una franja vacía.
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.msg,
        ));
      }
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error inesperado cargando banners: $e', tag: 'Banners');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: mensajeErrorRed(e),
      ));
    }
  }

  @override
  Future<void> close() {
    // Sin esto quedan dos listeners de FCM vivos apuntando a un BLoC cerrado.
    _fcmPrimerPlanoSub?.cancel();
    _fcmToqueSub?.cancel();
    return super.close();
  }
}
