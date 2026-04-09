import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/NotificacionUseCases.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> blocProviders = [
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
        HomeBloc(locator<HomeUseCases>(), locator<AuthUseCases>())
          ..add(const GetHomesList()),
  ),
  BlocProvider<MenuPrincipalBloc>(
    create: (context) => MenuPrincipalBloc(
      locator<AuthUseCases>(),
      locator<EdoCtaUseCases>(),
      locator<FcmService>(),
    )..add(const MenuPrincipalInitialEvent()),
  ),
  BlocProvider<EdoCtaListBloc>(
    create: (context) =>
        EdoCtaListBloc(locator<EdoCtaUseCases>(), locator<SharedPref>())
          ..add(const EdoCtaListInitialEvent()),
  ),
  BlocProvider<CarritoBloc>(
    create: (context) => CarritoBloc(
      sharedPref: locator<SharedPref>(),
      authUseCases: locator<AuthUseCases>(),
      edoCtaUseCases: locator<EdoCtaUseCases>(),
    )..add(const CarritoInitialEvent()),
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
];
