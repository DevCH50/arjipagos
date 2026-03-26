import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:equatable/equatable.dart';

/// Eventos del módulo de cambio de contraseña.
abstract class CambiarContrasenaEvent extends Equatable {
  const CambiarContrasenaEvent();

  @override
  List<Object?> get props => [];
}

/// Evento inicial: limpia el formulario al entrar a la pantalla.
class CambiarContrasenaInitialEvent extends CambiarContrasenaEvent {
  const CambiarContrasenaInitialEvent();
}

/// Cambio en el campo de contraseña actual.
class PasswordActualChanged extends CambiarContrasenaEvent {
  final BlocForItem passwordActual;
  const PasswordActualChanged({required this.passwordActual});

  @override
  List<Object?> get props => [passwordActual];
}

/// Cambio en el campo de contraseña nueva.
class PasswordNuevoChanged extends CambiarContrasenaEvent {
  final BlocForItem passwordNuevo;
  const PasswordNuevoChanged({required this.passwordNuevo});

  @override
  List<Object?> get props => [passwordNuevo];
}

/// Cambio en el campo de confirmación de contraseña nueva.
class PasswordConfirmarChanged extends CambiarContrasenaEvent {
  final BlocForItem passwordConfirmar;
  const PasswordConfirmarChanged({required this.passwordConfirmar});

  @override
  List<Object?> get props => [passwordConfirmar];
}

/// Envío del formulario para cambiar la contraseña.
class CambiarContrasenaSubmitted extends CambiarContrasenaEvent {
  const CambiarContrasenaSubmitted();
}

/// Resetea el formulario a su estado inicial.
class CambiarContrasenaFormReset extends CambiarContrasenaEvent {
  const CambiarContrasenaFormReset();
}
