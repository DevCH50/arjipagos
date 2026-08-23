import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/repository/ResenaRepository.dart';

/// Invita al usuario a calificar la app, solo si toca.
///
/// La política es deliberadamente conservadora. Ni Apple ni Google avisan de si
/// la hoja llegó a mostrarse, así que cada llamada consume cuota a ciegas: si
/// se pide de más, el sistema deja de mostrarla y se pierde la oportunidad
/// buena. Por eso se exige que se cumplan **todas** las condiciones.
class SolicitarResenaUseCase {
  final ResenaRepository _repository;

  const SolicitarResenaUseCase(this._repository);

  /// Pagos exitosos que debe acumular el usuario antes de la primera invitación.
  static const int minimoPagosExitosos = 3;

  /// Días que deben pasar desde el primer uso.
  ///
  /// Evita invitar a alguien que acaba de instalar la app y todavía no puede
  /// tener una opinión formada.
  static const int minimoDiasDesdePrimerUso = 7;

  /// Días de espera entre una invitación y la siguiente.
  static const int minimoDiasEntreInvitaciones = 120;

  /// Tope de invitaciones en 365 días. Es el mismo límite que aplica Apple.
  static const int maximoInvitacionesPorAnio = 3;

  /// Ejecuta la invitación si se cumplen todas las condiciones.
  ///
  /// Devuelve `true` solo si se le pidió al sistema que mostrara la hoja — que
  /// no es lo mismo que el usuario la haya visto. Nunca lanza: fallar al
  /// invitar no puede romper el flujo de pago desde el que se llama.
  Future<bool> run({DateTime? ahora}) async {
    try {
      final momento = ahora ?? DateTime.now();
      final estado = await _repository.obtenerEstado();

      if (estado.primerUso == null) {
        return false;
      }

      if (estado.pagosExitosos < minimoPagosExitosos) {
        return false;
      }

      final diasDesdePrimerUso = momento.difference(estado.primerUso!).inDays;
      if (diasDesdePrimerUso < minimoDiasDesdePrimerUso) {
        return false;
      }

      if (estado.invitacionesUltimoAnio >= maximoInvitacionesPorAnio) {
        return false;
      }

      final ultima = estado.ultimaInvitacion;
      if (ultima != null &&
          momento.difference(ultima).inDays < minimoDiasEntreInvitaciones) {
        return false;
      }

      // La comprobación del sistema va al final a propósito: es la única que
      // cruza al canal nativo, y no tiene sentido pagarla si ya sabemos que no
      // toca invitar.
      if (!await _repository.invitacionDisponible()) {
        return false;
      }

      await _repository.mostrarInvitacion();
      await _repository.registrarInvitacion();
      AppLogger.info('Invitación a calificar solicitada', tag: 'Resena');
      return true;
    } catch (e) {
      AppLogger.warning('No se pudo invitar a calificar: $e', tag: 'Resena');
      return false;
    }
  }
}
