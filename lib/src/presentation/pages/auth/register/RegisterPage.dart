import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/includes/RegisterContent.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/includes/RegisterResponse.dart';
import 'package:arjipagos/src/presentation/widgets/BackgroundImage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de registro de nuevos usuarios.
///
/// Permite a los usuarios crear una nueva cuenta ingresando
/// sus datos personales y credenciales.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  RegisterBloc? bloc;

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<RegisterBloc>(context);

    // Obtener el padding del teclado para ajustar el scroll
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const BackgroundImage(),
          SafeArea(
            child: Column(
              children: [
                // Botón de regreso
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ),
                ),
                // Contenido del registro
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: bottomInset > 0 ? 20 : 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RegisterResponse(bloc),
                          RegisterContent(bloc),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
