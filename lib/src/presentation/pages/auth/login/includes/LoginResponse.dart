import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginResponse extends StatelessWidget {
  const LoginResponse({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.response != current.response,
      listener: (context, state) {
        final responseState = state.response;
        if (responseState is Success) {
          if (responseState.data.status == 1) {
            _entrar(context, responseState.data as AuthResponse);
          } else {
            _showErrorDialog(context, responseState.data.msg);
          }
        } else if (responseState is Error) {
          _showErrorDialog(context, responseState.msg);
        }
      },
      buildWhen: (previous, current) => previous.response != current.response,
      builder: (context, state) {
        final responseState = state.response;
        if (responseState is Loading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Guarda la sesión, recarga los datos y entra al Menú Principal, **en ese
  /// orden**.
  ///
  /// El orden no es cosmético. Los BLoCs de datos viven en `blocProviders`, en
  /// la raíz de la app, y sobreviven al cierre de sesión: al entrar todavía
  /// tienen lo del usuario anterior. Recargarlos es lo que pone al día la
  /// pantalla, y para recargar hace falta que la sesión nueva ya esté escrita,
  /// porque cada servicio lee el token y el `user_id` del almacenamiento.
  ///
  /// Antes esto se resolvía mandando `LoginSaveUserSession` al BLoC y lanzando
  /// la recarga con un `Future.delayed` de 500 ms a ojo. No había ninguna
  /// garantía de orden: si el guardado en `flutter_secure_storage` —que cifra
  /// contra el keystore— tardaba más que el temporizador, la recarga leía una
  /// sesión que aún no existía, no emitía nada, y **la familia del usuario
  /// anterior se quedaba en pantalla**. Con el `await` no hay carrera.
  ///
  /// El guardado va DIRECTO por el `locator`, no por el BLoC, exactamente por el
  /// mismo motivo por el que el cierre de sesión hace lo propio: un evento de
  /// BLoC no se puede esperar.
  Future<void> _entrar(BuildContext context, AuthResponse data) async {
    // Todo lo que dependa del `context` se toma ANTES del await: después de
    // esperar, este widget puede haber dejado de estar montado.
    final NavigatorState navigator = Navigator.of(context);
    final MenuPrincipalBloc menuBloc = context.read<MenuPrincipalBloc>();
    final HomeBloc homeBloc = context.read<HomeBloc>();
    final EdoCtaListBloc edoCtaBloc = context.read<EdoCtaListBloc>();
    final EdoCtaPagadosBloc pagadosBloc = context.read<EdoCtaPagadosBloc>();
    final FacturaBloc facturaBloc = context.read<FacturaBloc>();

    await locator<AuthUseCases>().saveUserSession.run(data);

    // Ya hay sesión escrita: cada BLoC puede pedir sus datos con el usuario
    // nuevo. `MenuPrincipalInitialEvent` registra además el token de FCM.
    menuBloc.add(const MenuPrincipalInitialEvent());
    homeBloc.add(const RefreshHomesList());
    edoCtaBloc.add(const EdoCtaListRefreshEvent());
    pagadosBloc.add(const EdoCtaPagadosRefreshEvent());
    facturaBloc.add(const FacturaRefreshEvent());

    // Carrito y Notificaciones se recargan solos en el `initState` de su página.
    navigator.restorablePushNamedAndRemoveUntil(
      'menu_principal',
      (route) => false,
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.error_outline,
            color: Theme.of(ctx).colorScheme.error,
            size: 48,
          ),
          title: const Text(AppStrings.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.accept),
            ),
          ],
        ),
      );
    });
  }
}
