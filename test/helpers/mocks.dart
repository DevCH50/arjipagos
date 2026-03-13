/// Mocks para los tests unitarios.
///
/// Define los mocks de repositorios y use cases utilizando mocktail.
library;

import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart';
import 'package:arjipagos/src/domain/repository/HomeRepository.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/auth/GetUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LoginUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LogoutUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/SaveUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/RegisterUseCase.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/GetAlumnosUseCase.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/GetEstadosDeCuentaUseCase.dart';
import 'package:mocktail/mocktail.dart';

// ============================================================================
// MOCKS DE REPOSITORIOS
// ============================================================================

/// Mock del repositorio de autenticación.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock del repositorio de alumnos.
class MockHomeRepository extends Mock implements HomeRepository {}

/// Mock del repositorio de estados de cuenta.
class MockEdoCtaRepository extends Mock implements EdoCtaRepository {}

/// Mock de SharedPreferences wrapper.
class MockSharedPref extends Mock implements SharedPref {}

// ============================================================================
// MOCKS DE USE CASES
// ============================================================================

/// Mock del caso de uso de login.
class MockLoginUseCase extends Mock implements LoginUseCase {}

/// Mock del caso de uso de guardar sesión.
class MockSaveUserSessionUseCase extends Mock
    implements SaveUserSessionUseCase {}

/// Mock del caso de uso de obtener sesión.
class MockGetUserSessionUseCase extends Mock implements GetUserSessionUseCase {}

/// Mock del caso de uso de logout.
class MockLogoutUseCase extends Mock implements LogoutUseCase {}

/// Mock del caso de uso de obtener alumnos.
class MockGetAlumnosUseCase extends Mock implements GetAlumnosUseCase {}

// ============================================================================
// FACTORIES DE USE CASES CON MOCKS
// ============================================================================

/// Crea un AuthUseCases con todos los use cases mockeados.
AuthUseCases createMockAuthUseCases({
  MockLoginUseCase? login,
  MockSaveUserSessionUseCase? saveUserSession,
  MockGetUserSessionUseCase? getUserSession,
  MockLogoutUseCase? logout,
  MockRegisterUseCase? register,
}) {
  return AuthUseCases(
    login: login ?? MockLoginUseCase(),
    saveUserSession: saveUserSession ?? MockSaveUserSessionUseCase(),
    getUserSession: getUserSession ?? MockGetUserSessionUseCase(),
    logout: logout ?? MockLogoutUseCase(),
    register: register ?? MockRegisterUseCase(),
  );
}

/// Mock del caso de uso de registro.
class MockRegisterUseCase extends Mock implements RegisterUseCase {}

/// Crea un HomeUseCases con todos los use cases mockeados.
HomeUseCases createMockHomeUseCases({MockGetAlumnosUseCase? getAlumnos}) {
  return HomeUseCases(getAlumnos: getAlumnos ?? MockGetAlumnosUseCase());
}

/// Mock del caso de uso de obtener estados de cuenta.
class MockGetEstadosDeCuentaUseCase extends Mock
    implements GetEstadosDeCuentaUseCase {}

/// Crea un EdoCtaUseCases con todos los use cases mockeados.
EdoCtaUseCases createMockEdoCtaUseCases({
  MockGetEstadosDeCuentaUseCase? getEstadosDeCuenta,
}) {
  return EdoCtaUseCases(
    getEstadosDeCuenta: getEstadosDeCuenta ?? MockGetEstadosDeCuentaUseCase(),
  );
}
