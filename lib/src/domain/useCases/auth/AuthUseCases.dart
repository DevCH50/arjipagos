import 'package:arjipagos/src/domain/useCases/auth/CambiarContrasenaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/GetUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LoginUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LogoutUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/RecuperarContrasenaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/RegisterUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/SaveUserSessionUseCase.dart';

/// Contenedor de casos de uso de autenticación.
class AuthUseCases {
  LoginUseCase login;
  SaveUserSessionUseCase saveUserSession;
  GetUserSessionUseCase getUserSession;
  LogoutUseCase logout;
  RegisterUseCase register;
  CambiarContrasenaUseCase cambiarContrasena;
  RecuperarContrasenaUseCase recuperarContrasena;

  AuthUseCases({
    required this.login,
    required this.saveUserSession,
    required this.getUserSession,
    required this.logout,
    required this.register,
    required this.cambiarContrasena,
    required this.recuperarContrasena,
  });
}
