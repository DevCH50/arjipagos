import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/bloc/RegisterState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado del registro de usuarios.
///
/// Maneja la validación de campos en tiempo real y el envío
/// del formulario de registro al servidor.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthUseCases authUseCases;

  RegisterBloc(this.authUseCases) : super(const RegisterState()) {
    on<RegisterInitialEvent>(_onRegisterInitialEvent);
    on<NombreChanged>(_onNombreChanged);
    on<ApPaternoChanged>(_onApPaternoChanged);
    on<ApMaternoChanged>(_onApMaternoChanged);
    on<CelularChanged>(_onCelularChanged);
    on<EmailRegisterChanged>(_onEmailChanged);
    on<PasswordRegisterChanged>(_onPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<RegisterFormReset>(_onRegisterFormReset);
  }

  final formKey = GlobalKey<FormState>();

  /// Evento inicial - configura el formKey.
  Future<void> _onRegisterInitialEvent(
    RegisterInitialEvent event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(formKey: formKey));
  }

  /// Valida el campo nombre.
  Future<void> _onNombreChanged(
    NombreChanged event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(
      nombre: BlocForItem(
        value: event.nombre.value,
        error: event.nombre.value.isEmpty ? 'Ingresa tu nombre' : null,
      ),
      formKey: formKey,
    ));
  }

  /// Valida el campo apellido paterno.
  Future<void> _onApPaternoChanged(
    ApPaternoChanged event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(
      apPaterno: BlocForItem(
        value: event.apPaterno.value,
        error:
            event.apPaterno.value.isEmpty ? 'Ingresa tu apellido paterno' : null,
      ),
      formKey: formKey,
    ));
  }

  /// Valida el campo apellido materno (opcional).
  Future<void> _onApMaternoChanged(
    ApMaternoChanged event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(
      apMaterno: BlocForItem(
        value: event.apMaterno.value,
        error: null, // Apellido materno es opcional
      ),
      formKey: formKey,
    ));
  }

  /// Valida el campo celular (10 dígitos).
  Future<void> _onCelularChanged(
    CelularChanged event,
    Emitter<RegisterState> emit,
  ) async {
    String? error;
    final value = event.celular.value;

    if (value.isEmpty) {
      error = 'Ingresa tu celular';
    } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      error = 'El celular debe tener 10 dígitos';
    }

    emit(state.copyWith(
      celular: BlocForItem(value: value, error: error),
      formKey: formKey,
    ));
  }

  /// Valida el campo email con formato correcto.
  Future<void> _onEmailChanged(
    EmailRegisterChanged event,
    Emitter<RegisterState> emit,
  ) async {
    String? error;
    final value = event.email.value;

    if (value.isEmpty) {
      error = 'Ingresa tu email';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      error = 'Ingresa un email válido';
    }

    emit(state.copyWith(
      email: BlocForItem(value: value, error: error),
      formKey: formKey,
    ));
  }

  /// Valida el campo contraseña (mínimo 6 caracteres).
  Future<void> _onPasswordChanged(
    PasswordRegisterChanged event,
    Emitter<RegisterState> emit,
  ) async {
    String? error;
    final value = event.password.value;

    if (value.isEmpty) {
      error = 'Ingresa tu contraseña';
    } else if (value.length < 6) {
      error = 'Mínimo 6 caracteres';
    }

    // También verificar si coincide con confirmación actual
    String? confirmError = state.confirmPassword.error;
    if (state.confirmPassword.value.isNotEmpty &&
        state.confirmPassword.value != value) {
      confirmError = 'Las contraseñas no coinciden';
    } else if (state.confirmPassword.value.isNotEmpty &&
        state.confirmPassword.value == value) {
      confirmError = null;
    }

    emit(state.copyWith(
      password: BlocForItem(value: value, error: error),
      confirmPassword: BlocForItem(
        value: state.confirmPassword.value,
        error: confirmError,
      ),
      formKey: formKey,
    ));
  }

  /// Valida que la confirmación coincida con la contraseña.
  Future<void> _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<RegisterState> emit,
  ) async {
    String? error;
    final value = event.confirmPassword.value;

    if (value.isEmpty) {
      error = 'Confirma tu contraseña';
    } else if (value != state.password.value) {
      error = 'Las contraseñas no coinciden';
    }

    emit(state.copyWith(
      confirmPassword: BlocForItem(value: value, error: error),
      formKey: formKey,
    ));
  }

  /// Procesa el envío del formulario de registro.
  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // Validar formulario antes de enviar
    if (!state.isFormValid) {
      emit(state.copyWith(
        response: Error('Por favor, completa todos los campos correctamente'),
        formKey: formKey,
      ));
      return;
    }

    emit(state.copyWith(response: Loading(), formKey: formKey));

    final Resource response = await authUseCases.register.run(
      nombre: state.nombre.value,
      apPaterno: state.apPaterno.value,
      apMaterno: state.apMaterno.value,
      celular: state.celular.value,
      email: state.email.value,
      password: state.password.value,
    );

    emit(state.copyWith(response: response, formKey: formKey));
  }

  /// Resetea el formulario.
  Future<void> _onRegisterFormReset(
    RegisterFormReset event,
    Emitter<RegisterState> emit,
  ) async {
    state.formKey?.currentState?.reset();
    emit(const RegisterState());
  }
}
