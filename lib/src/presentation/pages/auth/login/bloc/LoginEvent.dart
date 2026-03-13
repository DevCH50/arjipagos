import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object?> get props => [];
}

class LoginInitialEvent extends LoginEvent {
  const LoginInitialEvent();
}

class LoginFormReset extends LoginEvent {
  const LoginFormReset();
}

class EmailChanged extends LoginEvent {
  final BlocForItem email;
  const EmailChanged({required this.email});
  @override
  List<Object?> get props => [email];
}

class PasswordChanged extends LoginEvent {
  final BlocForItem password;
  const PasswordChanged({required this.password});
  @override
  List<Object?> get props => [password];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}


class LoginSaveUserSession extends LoginEvent {
  final AuthResponse authResponse;
  const LoginSaveUserSession({required this.authResponse});
  @override
  List<Object?> get props => [authResponse];
}

// Agrega este nuevo evento
class CheckSession extends LoginEvent {
  const CheckSession();
}

// En LoginEvent.dart
class Logout extends LoginEvent {
  const Logout();
}
