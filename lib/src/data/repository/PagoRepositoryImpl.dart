import 'package:arjipagos/src/data/dataSource/remote/services/PagoService.dart';
import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:arjipagos/src/domain/models/PagoResponse.dart';
import 'package:arjipagos/src/domain/repository/PagoRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de pagos.
class PagoRepositoryImpl implements PagoRepository {
  final PagoService _pagoService;

  PagoRepositoryImpl(this._pagoService);

  @override
  Future<Resource<String>> iniciarPago(PagoRequest pagoRequest) {
    return _pagoService.iniciarPago(pagoRequest);
  }

  @override
  Future<Resource<PagoResponse>> verificarPago({
    required String referencia,
    required String token,
  }) {
    return _pagoService.verificarPago(referencia: referencia, token: token);
  }

  @override
  String buildPagoUrl(PagoRequest pagoRequest) {
    return _pagoService.buildPagoUrl(pagoRequest);
  }
}
