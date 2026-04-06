import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/models/AuthResponse.dart';

/// BLoC que gestiona el estado de autenticación.
///
/// Maneja el login, validación de campos, persistencia de sesión
/// y verificación de sesiones activas.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  AuthUseCases authUseCases;

  LoginBloc(this.authUseCases) : super(const LoginState()) {
    on<LoginInitialEvent>(_onLoginInitialEvent);
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginFormReset>(_onLoginFormReset);
    on<LoginSaveUserSession>(_onLoginSaveUserSession);
    on<CheckSession>(_onCheckSession);
    on<RecuperarContrasenaSubmitted>(_onRecuperarContrasenaSubmitted);
    on<RecuperarContrasenaReset>(_onRecuperarContrasenaReset);
  }

  final formKey = GlobalKey<FormState>();

  /// Maneja el evento inicial de login.
  /// Carga la sesión guardada si existe.
  Future<void> _onLoginInitialEvent(
    LoginInitialEvent event,
    Emitter<LoginState> emit,
  ) async {
    final AuthResponse? authResponse = await authUseCases.getUserSession.run();
    emit(state.copyWith(formKey: formKey));

    if (authResponse != null) {
      emit(state.copyWith(
        response: Success(authResponse),
        formKey: formKey,
      ));
    } else {
      emit(state.copyWith(
        response: null,
        formKey: formKey,
      ));
    }
  }

  /// Guarda la sesión del usuario en almacenamiento local.
  Future<void> _onLoginSaveUserSession(
    LoginSaveUserSession event,
    Emitter<LoginState> emit,
  ) async {
    await authUseCases.saveUserSession.run(event.authResponse);
  }

  /// Resetea el formulario de login.
  Future<void> _onLoginFormReset(
    LoginFormReset event,
    Emitter<LoginState> emit,
  ) async {
    state.formKey?.currentState?.reset();
  }

  /// Valida el campo de email/username en tiempo real.
  Future<void> _onEmailChanged(
    EmailChanged event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(
      email: BlocForItem(
        value: event.email.value,
        error: event.email.value.isNotEmpty
            ? null
            : 'Escribe el Nombre de Usuario',
      ),
      formKey: formKey,
    ));
  }

  /// Valida el campo de password en tiempo real.
  /// Requiere mínimo 6 caracteres.
  Future<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(
      password: BlocForItem(
        value: event.password.value,
        error: event.password.value.isNotEmpty &&
                event.password.value.length < 6
            ? 'Mínimo 6 caracteres'
            : null,
      ),
      formKey: formKey,
    ));
  }

  /// Procesa el envío del formulario de login.
  /// Realiza la autenticación contra el servidor.
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(response: Loading(), formKey: formKey));

    final Resource response = await authUseCases.login.run(
      state.email.value,
      state.password.value,
    );
    emit(state.copyWith(response: response, formKey: formKey));
  }

  /// Verifica si existe una sesión activa.
  Future<void> _onCheckSession(
    CheckSession event,
    Emitter<LoginState> emit,
  ) async {
    final AuthResponse? authResponse = await authUseCases.getUserSession.run();
    emit(state.copyWith(
      response: authResponse != null ? Success(authResponse) : null,
      formKey: formKey,
    ));
  }

  /// Procesa la solicitud de recuperación de contraseña.
  Future<void> _onRecuperarContrasenaSubmitted(
    RecuperarContrasenaSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(recuperarResponse: Loading(), formKey: formKey));

    final Resource result = await authUseCases.recuperarContrasena.run(
      username: event.username,
      email: event.email,
      deviceName: event.deviceName,
    );

    emit(state.copyWith(recuperarResponse: result, formKey: formKey));
  }

  /// Limpia el estado de recuperación de contraseña.
  Future<void> _onRecuperarContrasenaReset(
    RecuperarContrasenaReset event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(clearRecuperarResponse: true, formKey: formKey));
  }
}
