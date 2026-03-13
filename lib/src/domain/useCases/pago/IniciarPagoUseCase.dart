import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:arjipagos/src/domain/repository/PagoRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para iniciar el proceso de pago.
class IniciarPagoUseCase {
  final PagoRepository _repository;

  IniciarPagoUseCase(this._repository);

  Future<Resource<String>> run(PagoRequest pagoRequest) {
    return _repository.iniciarPago(pagoRequest);
  }
}
