import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/HomeService.dart';
import 'package:arjipagos/src/data/repository/AuthRepositoryImpl.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/AuthService.dart';
import 'package:arjipagos/src/data/repository/EdoCtaRepositoryImpl.dart';
import 'package:arjipagos/src/data/repository/HomeRepositoryImpl.dart';
import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart';
import 'package:arjipagos/src/domain/repository/HomeRepository.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/GetAlumnosUseCase.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/auth/CambiarContrasenaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/GetUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LoginUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LogoutUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/RegisterUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/SaveUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/GetEstadosDeCuentaUseCase.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/PagoService.dart';
import 'package:arjipagos/src/data/repository/PagoRepositoryImpl.dart';
import 'package:arjipagos/src/domain/repository/PagoRepository.dart';
import 'package:arjipagos/src/domain/useCases/pago/IniciarPagoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/pago/PagoUseCases.dart';
import 'package:arjipagos/src/domain/useCases/pago/VerificarPagoUseCase.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  /// Almacenamiento de preferencias no sensibles.
  @injectable
  SharedPref get sharedPref => SharedPref();

  /// Almacenamiento seguro para tokens y datos sensibles.
  @injectable
  SecureStorage get secureStorage => SecureStorage();

  @injectable
  AuthService get authService => AuthService();

  @injectable
  AuthRepository get authRepository =>
      AuthRepositoryImpl(authService, secureStorage, sharedPref);

  @injectable
  AuthUseCases get authUseCases => AuthUseCases(
    login: LoginUseCase(authRepository),
    saveUserSession: SaveUserSessionUseCase(authRepository),
    getUserSession: GetUserSessionUseCase(authRepository),
    logout: LogoutUseCase(authRepository),
    register: RegisterUseCase(authRepository),
    cambiarContrasena: CambiarContrasenaUseCase(authRepository),
  );

  @injectable
  HomeService get homeService => HomeService(sharedPref, authUseCases);

  @injectable
  HomeRepository get homeRepository => HomeRepositoryImpl(homeService);

  @injectable
  HomeUseCases get homeUseCases =>
      HomeUseCases(getAlumnos: GetAlumnosUseCase(homeRepository));

  // ============================================================================
  // ESTADOS DE CUENTA (EDO CTA)
  // ============================================================================

  @injectable
  EdoCtaService get edoCtaService => EdoCtaService(authUseCases);

  @injectable
  EdoCtaRepository get edoCtaRepository => EdoCtaRepositoryImpl(edoCtaService);

  @injectable
  EdoCtaUseCases get edoCtaUseCases =>
      EdoCtaUseCases(getEstadosDeCuenta: GetEstadosDeCuentaUseCase(edoCtaRepository));

  // ============================================================================
  // PAGOS
  // ============================================================================

  @injectable
  PagoService get pagoService => PagoService();

  @injectable
  PagoRepository get pagoRepository => PagoRepositoryImpl(pagoService);

  @injectable
  PagoUseCases get pagoUseCases => PagoUseCases(
        iniciarPago: IniciarPagoUseCase(pagoRepository),
        verificarPago: VerificarPagoUseCase(pagoRepository),
      );
}
