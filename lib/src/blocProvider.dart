import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
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
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
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
  BlocProvider<RegisterBloc>(
    create: (context) =>
        RegisterBloc(locator<AuthUseCases>())..add(const RegisterInitialEvent()),
  ),
  BlocProvider<HomeBloc>(
    create: (context) =>
        HomeBloc(locator<HomeUseCases>())..add(const GetHomesList()),
  ),
  BlocProvider<MenuPrincipalBloc>(
    create: (context) => MenuPrincipalBloc(
      locator<AuthUseCases>(),
      locator<EdoCtaUseCases>(),
      locator<FcmService>(),
    )..add(const MenuPrincipalInitialEvent()),
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
  BlocProvider<EdoCtaPagadosBloc>(
    create: (context) =>
        EdoCtaPagadosBloc(locator<EdoCtaPagadosUseCases>())
          ..add(const EdoCtaPagadosInitialEvent()),
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
  BlocProvider<FacturaBloc>(
    create: (context) =>
        FacturaBloc(locator<FacturaUseCases>())
          ..add(const FacturaInicialEvent()),
  ),
];
