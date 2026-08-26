/// Mocks para los tests unitarios.
///
/// Define los mocks de repositorios y use cases utilizando mocktail.
library;

import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/repository/AuthRepository.dart';
import 'package:arjipagos/src/domain/repository/BiometriaRepository.dart';
import 'package:arjipagos/src/domain/repository/ResenaRepository.dart';
import 'package:arjipagos/src/domain/repository/BannerRepository.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaPagadosRepository.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart';
import 'package:arjipagos/src/domain/repository/HomeRepository.dart';
import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart';
import 'package:arjipagos/src/domain/repository/TicketRepository.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/auth/CambiarContrasenaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/GetUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LoginUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/LogoutUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/RecuperarContrasenaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/SaveUserSessionUseCase.dart';
import 'package:arjipagos/src/domain/useCases/auth/RegisterUseCase.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/GetAlumnosUseCase.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
import 'package:arjipagos/src/domain/useCases/banners/BannerUseCases.dart';
import 'package:arjipagos/src/domain/useCases/banners/GetBannersUseCase.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaPagadosUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/GetEstadosDeCuentaPagadosUseCase.dart';
import 'package:arjipagos/src/domain/useCases/edocta/GetEstadosDeCuentaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/facturas/FacturaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/facturas/GetFacturasUseCase.dart';
import 'package:arjipagos/src/domain/useCases/ticket/DescargarTicketUseCase.dart';
import 'package:arjipagos/src/domain/useCases/ticket/TicketUseCases.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/GetCountNoLeidasUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/GetNotificacionesUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/MarcarLeidaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/MarcarTodasLeidasUseCase.dart';
import 'package:arjipagos/src/domain/useCases/notificaciones/NotificacionUseCases.dart';
import 'package:arjipagos/src/domain/repository/VersionRepository.dart';
import 'package:arjipagos/src/domain/useCases/version/VerificarActualizacionUseCase.dart';
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

/// Mock del repositorio de invitaciones a calificar la app.
class MockResenaRepository extends Mock implements ResenaRepository {}

/// Mock del servicio de Firebase Cloud Messaging.
class MockFcmService extends Mock implements FcmService {}

/// Mock del repositorio del bloqueo biométrico.
///
/// Se mockea el repositorio y no `AutenticadorBiometrico`: la frontera del
/// dominio está aquí, y así los tests no dependen de `local_auth`.
class MockBiometriaRepository extends Mock implements BiometriaRepository {}

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

/// Mock del caso de uso de registro.
class MockRegisterUseCase extends Mock implements RegisterUseCase {}

/// Mock del caso de uso de cambio de contraseña.
class MockCambiarContrasenaUseCase extends Mock
    implements CambiarContrasenaUseCase {}

/// Mock del caso de uso de recuperación de contraseña.
class MockRecuperarContrasenaUseCase extends Mock
    implements RecuperarContrasenaUseCase {}

/// Crea un AuthUseCases con todos los use cases mockeados.
AuthUseCases createMockAuthUseCases({
  MockLoginUseCase? login,
  MockSaveUserSessionUseCase? saveUserSession,
  MockGetUserSessionUseCase? getUserSession,
  MockLogoutUseCase? logout,
  MockRegisterUseCase? register,
  MockCambiarContrasenaUseCase? cambiarContrasena,
  MockRecuperarContrasenaUseCase? recuperarContrasena,
}) {
  return AuthUseCases(
    login: login ?? MockLoginUseCase(),
    saveUserSession: saveUserSession ?? MockSaveUserSessionUseCase(),
    getUserSession: getUserSession ?? MockGetUserSessionUseCase(),
    logout: logout ?? MockLogoutUseCase(),
    register: register ?? MockRegisterUseCase(),
    cambiarContrasena: cambiarContrasena ?? MockCambiarContrasenaUseCase(),
    recuperarContrasena:
        recuperarContrasena ?? MockRecuperarContrasenaUseCase(),
  );
}

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

/// Mock del repositorio de pagos realizados.
class MockEdoCtaPagadosRepository extends Mock
    implements EdoCtaPagadosRepository {}

/// Mock del caso de uso de obtener los pagos realizados.
class MockGetEstadosDeCuentaPagadosUseCase extends Mock
    implements GetEstadosDeCuentaPagadosUseCase {}

/// Crea un EdoCtaPagadosUseCases con todos los use cases mockeados.
EdoCtaPagadosUseCases createMockEdoCtaPagadosUseCases({
  MockGetEstadosDeCuentaPagadosUseCase? getEstadosDeCuentaPagados,
}) {
  return EdoCtaPagadosUseCases(
    getEstadosDeCuentaPagados:
        getEstadosDeCuentaPagados ?? MockGetEstadosDeCuentaPagadosUseCase(),
  );
}

/// Mock del repositorio de banners informativos.
class MockBannerRepository extends Mock implements BannerRepository {}

/// Mock del caso de uso de obtener banners.
class MockGetBannersUseCase extends Mock implements GetBannersUseCase {}

/// Crea un BannerUseCases con todos los use cases mockeados.
BannerUseCases createMockBannerUseCases({
  MockGetBannersUseCase? getBanners,
}) {
  return BannerUseCases(getBanners: getBanners ?? MockGetBannersUseCase());
}

/// Mock del repositorio del ticket de pago.
class MockTicketRepository extends Mock implements TicketRepository {}

/// Mock del caso de uso de descargar el ticket.
class MockDescargarTicketUseCase extends Mock
    implements DescargarTicketUseCase {}

/// Crea un TicketUseCases con todos los use cases mockeados.
TicketUseCases createMockTicketUseCases({
  MockDescargarTicketUseCase? descargarTicket,
}) {
  return TicketUseCases(
    descargarTicket: descargarTicket ?? MockDescargarTicketUseCase(),
  );
}

/// Mock del caso de uso de obtener facturas.
class MockGetFacturasUseCase extends Mock implements GetFacturasUseCase {}

/// Crea un FacturaUseCases con todos los use cases mockeados.
FacturaUseCases createMockFacturaUseCases({
  MockGetFacturasUseCase? getFacturas,
}) {
  return FacturaUseCases(
    getFacturas: getFacturas ?? MockGetFacturasUseCase(),
  );
}

// ============================================================================
// MOCKS DE NOTIFICACIONES
// ============================================================================

/// Mock del repositorio de notificaciones.
class MockNotificacionRepository extends Mock implements NotificacionRepository {}

/// Mock del caso de uso de obtener notificaciones paginadas.
class MockGetNotificacionesUseCase extends Mock implements GetNotificacionesUseCase {}

/// Mock del caso de uso de obtener conteo de no leídas.
class MockGetCountNoLeidasUseCase extends Mock implements GetCountNoLeidasUseCase {}

/// Mock del caso de uso de marcar una notificación como leída.
class MockMarcarLeidaUseCase extends Mock implements MarcarLeidaUseCase {}

/// Mock del caso de uso de marcar todas las notificaciones como leídas.
class MockMarcarTodasLeidasUseCase extends Mock implements MarcarTodasLeidasUseCase {}

/// Crea un NotificacionUseCases con todos los use cases mockeados.
NotificacionUseCases createMockNotificacionUseCases({
  MockGetNotificacionesUseCase? getNotificaciones,
  MockGetCountNoLeidasUseCase? getCountNoLeidas,
  MockMarcarLeidaUseCase? marcarLeida,
  MockMarcarTodasLeidasUseCase? marcarTodasLeidas,
}) {
  return NotificacionUseCases(
    getNotificaciones: getNotificaciones ?? MockGetNotificacionesUseCase(),
    getCountNoLeidas: getCountNoLeidas ?? MockGetCountNoLeidasUseCase(),
    marcarLeida: marcarLeida ?? MockMarcarLeidaUseCase(),
    marcarTodasLeidas: marcarTodasLeidas ?? MockMarcarTodasLeidasUseCase(),
  );
}

// ============================================================================
// VERSIÓN DE LA APP
// ============================================================================

/// Mock del repositorio de la política de versión.
class MockVersionRepository extends Mock implements VersionRepository {}

/// Mock del caso de uso que decide si hay que actualizar.
class MockVerificarActualizacionUseCase extends Mock
    implements VerificarActualizacionUseCase {}
