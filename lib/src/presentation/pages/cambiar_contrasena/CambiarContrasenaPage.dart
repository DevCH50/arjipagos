import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaBloc.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/includes/CambiarContrasenaContent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/includes/CambiarContrasenaResponse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de cambio de contraseña del usuario autenticado.
///
/// Accesible desde el Drawer del Menú Principal.
/// Envía una petición POST a /api/v1/usuarios/cambiar-contrasena
/// con el token del usuario en el header Authorization.
///
/// Sigue el patrón Clean Architecture con BLoC + Use Cases.
class CambiarContrasenaPage extends StatefulWidget {
  const CambiarContrasenaPage({super.key});

  @override
  State<CambiarContrasenaPage> createState() => _CambiarContrasenaPageState();
}

class _CambiarContrasenaPageState extends State<CambiarContrasenaPage> {
  CambiarContrasenaBloc? bloc;

  @override
  void initState() {
    super.initState();
    // Inicializar el BLoC después del primer frame para tener el context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bloc?.add(const CambiarContrasenaInitialEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<CambiarContrasenaBloc>(context);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cambiarContrasenaTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: bottomInset > 0 ? bottomInset + 24 : 32,
          ),
          child: Column(
            children: [
              // Indicador de carga / mensaje de respuesta
              CambiarContrasenaResponse(bloc),
              // Formulario principal
              CambiarContrasenaContent(bloc),
            ],
          ),
        ),
      ),
    );
  }
}
