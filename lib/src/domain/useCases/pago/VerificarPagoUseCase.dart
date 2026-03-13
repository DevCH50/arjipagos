import 'package:arjipagos/src/domain/models/PagoResponse.dart';
import 'package:arjipagos/src/domain/repository/PagoRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para verificar el estado de un pago.
class VerificarPagoUseCase {
  final PagoRepository _repository;

  VerificarPagoUseCase(this._repository);

  /// Ejecuta la verificación del pago.
  ///
  /// [referencia] es el ID único del pago a verificar.
  /// [token] es el Bearer token de autenticación.
  Future<Resource<PagoResponse>> run({
    required String referencia,
    required String token,
  }) {
    return _repository.verificarPago(referencia: referencia, token: token);
  }
}
