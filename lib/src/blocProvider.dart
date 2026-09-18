import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/data/dataSource/local/DispositivoStorage.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/banners/BannerUseCases.dart';
import 'package:arjipagos/src/domain/useCases/biometria/BiometriaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaPagadosUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/facturas/FacturaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/NotificacionUseCases.dart';
import 'package:arjipagos/src/domain/useCases/version/VersionUseCases.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> blocProviders = [
  // La comprobación de versión NO se dispara aquí: la lanza
  // `ActualizacionObserver` tras el primer frame, cuando ya existe el
  // navegador que necesita el diálogo de bloqueo.
  BlocProvider<ActualizacionBloc>(
    create: (context) => ActualizacionBloc(
      locator<VersionUseCases>(),
      locator<SharedPref>(),
    ),
  ),
  // El cerrojo biométrico tampoco se dispara aquí: lo arranca
  // `CerrojoBiometrico` tras el primer frame, por el mismo motivo que la
  // comprobación de versión — hasta entonces no hay árbol donde pintarlo.
  BlocProvider<BiometriaBloc>(
    create: (context) => BiometriaBloc(
      locator<BiometriaUseCases>(),
      locator<AuthUseCases>(),
    ),
  ),
  BlocProvider<LoginBloc>(
    create: (context) =>
        LoginBloc(locator<AuthUseCases>())..add(const LoginInitialEvent()),
  ),
  // MenuPrincipalBloc, EdoCtaPagadosBloc y FacturaBloc nacen VACÍOS: su
  // `create` no dispara ninguna carga. Los carga `LoginResponse` después de
  // guardar la sesión, y su pantalla si los encuentra vacíos (el mismo
  // `_cargarSiHaceFalta` de `EdoCtaPage`).
  //
  // Hasta el 2026-09-18 cada `create` hacía `..add(InitialEvent)`. Como
  // `blocProviders` es perezoso, en el primer login tras abrir la app estos
  // BLoC nacían dentro de `LoginResponse._entrar`: el `create` lanzaba una
  // carga —compitiendo además con el guardado de la sesión— y `_entrar` otra.
  // Resultado: menú, Pagos Realizados y Facturas pedidos dos veces.
  BlocProvider<MenuPrincipalBloc>(
    create: (context) => MenuPrincipalBloc(
      locator<AuthUseCases>(),
      locator<EdoCtaUseCases>(),
      locator<FcmService>(),
      locator<DispositivoStorage>(),
    ),
  ),
  // EdoCtaListBloc y CarritoBloc NO están aquí: hay una instancia por emisor
  // fiscal y viven en `RegistroEmisores`, de donde las toma cada pantalla. Con
  // una sola instancia compartida, vaciar un carrito o completar un pago
  // alcanzaba al otro emisor.
  // El evento de carga NO se dispara aquí: lo manda la propia tirilla al
  // montarse, ya dentro del Menú Principal, para que los banners se pidan
  // siempre con la sesión iniciada y con el usuario correcto.
  BlocProvider<BannerBloc>(
    create: (context) => BannerBloc(locator<BannerUseCases>()),
  ),
  // Nace vacío: ver MenuPrincipalBloc arriba.
  BlocProvider<EdoCtaPagadosBloc>(
    create: (context) => EdoCtaPagadosBloc(locator<EdoCtaPagadosUseCases>()),
  ),
  BlocProvider<CambiarContrasenaBloc>(
    create: (context) =>
        CambiarContrasenaBloc(locator<AuthUseCases>())
          ..add(const CambiarContrasenaInitialEvent()),
  ),
  BlocProvider<NotificacionBloc>(
    create: (context) =>
        NotificacionBloc(locator<NotificacionUseCases>())
          ..add(const NotificacionInicialEvent()),
  ),
  // Nace vacío: ver MenuPrincipalBloc arriba. Además, `CierreDeSesion` lo lee
  // para vaciarlo; con la carga en el `create`, cerrar sesión sin haber abierto
  // Facturas lo creaba y pedía las facturas en pleno cierre.
  BlocProvider<FacturaBloc>(
    create: (context) => FacturaBloc(locator<FacturaUseCases>()),
  ),
];
