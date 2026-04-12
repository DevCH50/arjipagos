import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaEvent.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/bloc/CambiarContrasenaState.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado del módulo de cambio de contraseña.
///
/// Valida los campos del formulario en tiempo real y ejecuta
/// la operación de cambio de contraseña contra el servidor.
class CambiarContrasenaBloc
    extends Bloc<CambiarContrasenaEvent, CambiarContrasenaState> {
  final AuthUseCases authUseCases;

  CambiarContrasenaBloc(this.authUseCases) : super(const CambiarContrasenaState()) {
    on<CambiarContrasenaInitialEvent>(_onInitialEvent);
    on<PasswordActualChanged>(_onPasswordActualChanged);
    on<PasswordNuevoChanged>(_onPasswordNuevoChanged);
    on<PasswordConfirmarChanged>(_onPasswordConfirmarChanged);
    on<CambiarContrasenaSubmitted>(_onSubmitted);
    on<CambiarContrasenaFormReset>(_onFormReset);
  }

  final formKey = GlobalKey<FormState>();

  /// Inicializa el BLoC asignando el formKey al estado.
  Future<void> _onInitialEvent(
    CambiarContrasenaInitialEvent event,
    Emitter<CambiarContrasenaState> emit,
  ) async {
    emit(state.copyWith(formKey: formKey, clearResponse: true));
  }

  /// Resetea el formulario al estado inicial.
  Future<void> _onFormReset(
    CambiarContrasenaFormReset event,
    Emitter<CambiarContrasenaState> emit,
  ) async {
    state.formKey?.currentState?.reset();
    emit(CambiarContrasenaState(formKey: formKey));
  }

  /// Valida el campo de contraseña actual en tiempo real.
  Future<void> _onPasswordActualChanged(
    PasswordActualChanged event,
    Emitter<CambiarContrasenaState> emit,
  ) async {
    emit(state.copyWith(
      passwordActual: BlocForItem(
        value: event.passwordActual.value,
        error: event.passwordActual.value.isNotEmpty
            ? null
            : AppStrings.cambiarContrasenaIngresaActual,
      ),
      formKey: formKey,
    ));
  }

  /// Valida el campo de contraseña nueva en tiempo real.
  /// Requiere mínimo 6 caracteres.
  Future<void> _onPasswordNuevoChanged(
    PasswordNuevoChanged event,
    Emitter<CambiarContrasenaState> emit,
  ) async {
    final valor = event.passwordNuevo.value;
    String? error;
    if (valor.isEmpty) {
      error = AppStrings.cambiarContrasenaIngresaNueva;
    } else if (valor.length < 6) {
      error = 'Mínimo 6 caracteres';
    }

    emit(state.copyWith(
      passwordNuevo: BlocForItem(value: valor, error: error),
      formKey: formKey,
    ));
  }

  /// Valida que la confirmación coincida con la contraseña nueva.
  Future<void> _onPasswordConfirmarChanged(
    PasswordConfirmarChanged event,
    Emitter<CambiarContrasenaState> emit,
  ) async {
    final valor = event.passwordConfirmar.value;
    String? error;
    if (valor.isEmpty) {
      error = AppStrings.cambiarContrasenaConfirmaError;
    } else if (valor != state.passwordNuevo.value) {
      error = AppStrings.cambiarContrasenaNoCoinciden;
    }

    emit(state.copyWith(
      passwordConfirmar: BlocForItem(value: valor, error: error),
      formKey: formKey,
    ));
  }

  /// Procesa el envío del formulario.
  ///
  /// Valida que las contraseñas coincidan antes de llamar al servidor.
  Future<void> _onSubmitted(
    CambiarContrasenaSubmitted event,
    Emitter<CambiarContrasenaState> emit,
  ) async {
    // Validación extra: contraseñas deben coincidir
    if (state.passwordNuevo.value != state.passwordConfirmar.value) {
      emit(state.copyWith(
        passwordConfirmar: const BlocForItem(
          value: '',
          error: AppStrings.cambiarContrasenaNoCoinciden,
        ),
        formKey: formKey,
      ));
      return;
    }

    emit(state.copyWith(response: Loading(), formKey: formKey));

    final Resource response = await authUseCases.cambiarContrasena.run(
      state.passwordActual.value,
      state.passwordNuevo.value,
    );

    // Si el cambio fue exitoso, cerrar sesión antes de notificar a la UI
    if (response is Success) {
      await authUseCases.logout.run();
    }

    emit(state.copyWith(response: response, formKey: formKey));
  }
}
