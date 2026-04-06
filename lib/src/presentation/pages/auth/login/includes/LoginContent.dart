import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/RecuperarContrasenaPage.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:arjipagos/src/presentation/widgets/DefaultTextField.dart';
import 'package:arjipagos/src/presentation/widgets/GlassContainer.dart';
import 'package:arjipagos/src/presentation/widgets/LogoRedondeUno.dart';
import 'package:arjipagos/src/presentation/widgets/NoTienesCuentaAun.dart';
import 'package:arjipagos/src/presentation/widgets/PrimaryElevatedButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que contiene el formulario de inicio de sesión.
///
/// Muestra los campos de email y contraseña, el botón de login
/// y enlaces a recuperación de contraseña y registro.
class LoginContent extends StatelessWidget {
  final LoginBloc? bloc;

  const LoginContent(this.bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Form(
          key: state.formKey,
          child: GlassContainer(
            heightFactor: null, // Ajustar al contenido, no altura fija
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LogoRedondoUno(
                  blurRadius: 10,
                  spreadRadius: 2,
                  paddingEdgeInsets: 8,
                  marginBottom: 12,
                  size: 112, // 25% más pequeño (150 * 0.75)
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: const Text(
                    'Ingresar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DefaultTextField(
                  label: 'Username',
                  icon: Icons.email,
                  keyboardType: TextInputType.text,
                  onChanged: (text) {
                    bloc?.add(EmailChanged(email: BlocForItem(value: text)));
                  },
                  validator: (value) {
                    return state.email.error;
                  },
                ),
                const SizedBox(height: 10),
                DefaultTextField(
                  label: 'Contraseña',
                  icon: Icons.lock,
                  obscureText: true,
                  onChanged: (text) {
                    bloc?.add(
                      PasswordChanged(password: BlocForItem(value: text)),
                    );
                  },
                  validator: (value) {
                    return state.password.error;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, // Ocupa el ancho disponible dentro del contenedor
                  child: PrimaryElevatedButton(
                    text: 'Iniciar Sesión',
                    onPressed: () {
                      if (bloc?.state.formKey?.currentState?.validate() ??
                          false) {
                        bloc?.add(const LoginSubmitted());
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            icon: Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(ctx).colorScheme.error,
                              size: 48,
                            ),
                            title: const Text('Campos incompletos'),
                            content: const Text(
                              'Por favor, completa todos los campos para continuar.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Aceptar'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                // Enlace de recuperación de contraseña
                TextButton(
                  onPressed: () {
                    final bloc = BlocProvider.of<LoginBloc>(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: const RecuperarContrasenaPage(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                const NoTienesCuentaAun(
                  color: Color.fromARGB(111, 65, 34, 5),
                  mensaje:
                      'Ponte en contacto con tu colegio para que te proporcionen tu cuenta.',
                  titulo: '¿No tienes una cuenta?',
                  icono: Icons.school,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
