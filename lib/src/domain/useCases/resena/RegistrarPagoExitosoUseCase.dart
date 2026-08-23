import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/repository/ResenaRepository.dart';

/// Anota un pago completado con éxito para la política de reseñas.
///
/// Se llama en cuanto el WebView confirma el pago, antes de que el usuario
/// cierre el diálogo de éxito, para que el contador ya esté al día cuando
/// `SolicitarResenaUseCase` decida si invita.
class RegistrarPagoExitosoUseCase {
  final ResenaRepository _repository;

  const RegistrarPagoExitosoUseCase(this._repository);

  /// Nunca lanza: llevar la cuenta de reseñas no puede romper un pago que ya
  /// se cobró.
  Future<void> run() async {
    try {
      await _repository.registrarPagoExitoso();
    } catch (e) {
      AppLogger.warning('No se pudo registrar el pago para reseñas: $e',
          tag: 'Resena');
    }
  }
}
