import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
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
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart'; // MenuPrincipalRegistrarFcm
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginResponse extends StatelessWidget {
  final LoginBloc? bloc;

  const LoginResponse(this.bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.response != current.response,
      listener: (context, state) {
        final responseState = state.response;
        if (responseState is Success) {
          if (responseState.data.status == 1) {
            final data = responseState.data as AuthResponse;
            bloc?.add(LoginSaveUserSession(authResponse: data));
            // Registrar token FCM con el accessToken directo.
            context.read<MenuPrincipalBloc>().add(
              MenuPrincipalRegistrarFcm(accessToken: data.accessToken),
            );
            // Re-cargar datos del usuario después de que la sesión se guarde.
            //
            // También se refrescan los BLoCs de datos: viven en la raíz de la
            // app (`blocProviders`) y sobreviven al cierre de sesión, así que
            // sin esto el siguiente usuario vería los estados de cuenta,
            // pagados y facturas del anterior. Carrito y Notificaciones se
            // recargan solos en el `initState` de su página.
            final menuBloc = context.read<MenuPrincipalBloc>();
            final homeBloc = context.read<HomeBloc>();
            final edoCtaBloc = context.read<EdoCtaListBloc>();
            final pagadosBloc = context.read<EdoCtaPagadosBloc>();
            final facturaBloc = context.read<FacturaBloc>();
            Future.delayed(const Duration(milliseconds: 500), () {
              menuBloc.add(const MenuPrincipalInitialEvent());
              homeBloc.add(const RefreshHomesList());
              edoCtaBloc.add(const EdoCtaListRefreshEvent());
              pagadosBloc.add(const EdoCtaPagadosRefreshEvent());
              facturaBloc.add(const FacturaRefreshEvent());
            });
            Navigator.restorablePushNamedAndRemoveUntil(
              context,
              'menu_principal',
              (route) => false,
            );
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
