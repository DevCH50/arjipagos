import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:equatable/equatable.dart';

/// Eventos del BLoC de registro.
abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

/// Evento inicial para resetear el formulario.
class RegisterInitialEvent extends RegisterEvent {
  const RegisterInitialEvent();
}

/// Evento cuando cambia el campo nombre.
class NombreChanged extends RegisterEvent {
  final BlocForItem nombre;
  const NombreChanged({required this.nombre});

  @override
  List<Object?> get props => [nombre];
}

/// Evento cuando cambia el campo apellido paterno.
class ApPaternoChanged extends RegisterEvent {
  final BlocForItem apPaterno;
  const ApPaternoChanged({required this.apPaterno});

  @override
  List<Object?> get props => [apPaterno];
}

/// Evento cuando cambia el campo apellido materno.
class ApMaternoChanged extends RegisterEvent {
  final BlocForItem apMaterno;
  const ApMaternoChanged({required this.apMaterno});

  @override
  List<Object?> get props => [apMaterno];
}

/// Evento cuando cambia el campo celular.
class CelularChanged extends RegisterEvent {
  final BlocForItem celular;
  const CelularChanged({required this.celular});

  @override
  List<Object?> get props => [celular];
}

/// Evento cuando cambia el campo email.
class EmailRegisterChanged extends RegisterEvent {
  final BlocForItem email;
  const EmailRegisterChanged({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Evento cuando cambia el campo contraseña.
class PasswordRegisterChanged extends RegisterEvent {
  final BlocForItem password;
  const PasswordRegisterChanged({required this.password});

  @override
  List<Object?> get props => [password];
}

/// Evento cuando cambia el campo confirmar contraseña.
class ConfirmPasswordChanged extends RegisterEvent {
  final BlocForItem confirmPassword;
  const ConfirmPasswordChanged({required this.confirmPassword});

  @override
  List<Object?> get props => [confirmPassword];
}

/// Evento cuando se envía el formulario de registro.
class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted();
}

/// Evento para resetear el formulario.
class RegisterFormReset extends RegisterEvent {
  const RegisterFormReset();
}
