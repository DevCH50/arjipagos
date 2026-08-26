import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/includes/LoginContent.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/includes/LoginResponse.dart';
import 'package:arjipagos/src/presentation/widgets/BackgroundImage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginBloc? bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Cuando aparece el teclado, hace scroll al final para que el botón
  /// "Iniciar Sesión" y el enlace de recuperación queden visibles.
  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<LoginBloc>(context);

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Cada vez que el teclado aparece, desplaza hasta el final del scroll
    if (keyboardHeight > 0) {
      _scrollAlFinal();
    }

    // El fondo vive FUERA del Scaffold → nunca se recorta con el teclado.
    // El Scaffold (resizeToAvoidBottomInset: true) encoge su body cuando
    // aparece el teclado y Flutter hace scroll automático al campo activo.
    // _scrollAlFinal() garantiza que el botón debajo del campo también sea visible.
    return Stack(
      children: [
        const Positioned.fill(child: BackgroundImage()),
        Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const LoginResponse(),
              SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: LoginContent(bloc)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
