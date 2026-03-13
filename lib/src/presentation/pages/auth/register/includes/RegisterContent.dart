import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:arjipagos/src/presentation/widgets/DefaultTextField.dart';
import 'package:arjipagos/src/presentation/widgets/GlassContainer.dart';
import 'package:arjipagos/src/presentation/widgets/PrimaryElevatedButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que contiene el formulario de registro.
///
/// Muestra los campos necesarios para crear una nueva cuenta
/// con validación en tiempo real.
class RegisterContent extends StatelessWidget {
  final RegisterBloc? bloc;

  const RegisterContent(this.bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        return Form(
          key: state.formKey,
          child: GlassContainer(
            heightFactor: null, // Ajustar al contenido, no altura fija
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.white), // 25% más pequeño
                const SizedBox(height: 8),
                const Text(
                  'REGISTRO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                DefaultTextField(
                  label: 'Nombre',
                  icon: Icons.person,
                  onChanged: (text) {
                    bloc?.add(NombreChanged(nombre: BlocForItem(value: text)));
                  },
                  validator: (value) => state.nombre.error,
                ),
                const SizedBox(height: 8),
                DefaultTextField(
                  label: 'Apellido Paterno',
                  icon: Icons.person_outline,
                  onChanged: (text) {
                    bloc?.add(ApPaternoChanged(apPaterno: BlocForItem(value: text)));
                  },
                  validator: (value) => state.apPaterno.error,
                ),
                const SizedBox(height: 8),
                DefaultTextField(
                  label: 'Apellido Materno (opcional)',
                  icon: Icons.person_outline,
                  onChanged: (text) {
                    bloc?.add(ApMaternoChanged(apMaterno: BlocForItem(value: text)));
                  },
                  validator: (value) => state.apMaterno.error,
                ),
                const SizedBox(height: 8),
                DefaultTextField(
                  label: 'Celular',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (text) {
                    bloc?.add(CelularChanged(celular: BlocForItem(value: text)));
                  },
                  validator: (value) => state.celular.error,
                ),
                const SizedBox(height: 8),
                DefaultTextField(
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) {
                    bloc?.add(EmailRegisterChanged(email: BlocForItem(value: text)));
                  },
                  validator: (value) => state.email.error,
                ),
                const SizedBox(height: 8),
                DefaultTextField(
                  label: 'Contraseña',
                  icon: Icons.lock,
                  obscureText: true,
                  onChanged: (text) {
                    bloc?.add(PasswordRegisterChanged(password: BlocForItem(value: text)));
                  },
                  validator: (value) => state.password.error,
                ),
                const SizedBox(height: 8),
                DefaultTextField(
                  label: 'Confirmar Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  onChanged: (text) {
                    bloc?.add(ConfirmPasswordChanged(confirmPassword: BlocForItem(value: text)));
                  },
                  validator: (value) => state.confirmPassword.error,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, // Ocupa el ancho disponible dentro del contenedor
                  child: PrimaryElevatedButton(
                    text: 'Registrarse',
                    onPressed: () {
                      if (bloc?.state.formKey?.currentState?.validate() ?? false) {
                        bloc?.add(const RegisterSubmitted());
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
                              'Por favor, completa todos los campos correctamente.',
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
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
