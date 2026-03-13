import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:arjipagos/src/domain/models/PagoResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Repositorio para operaciones de pago.
abstract class PagoRepository {
  /// Inicia el proceso de pago.
  Future<Resource<String>> iniciarPago(PagoRequest pagoRequest);

  /// Verifica el estado de un pago.
  Future<Resource<PagoResponse>> verificarPago({
    required String referencia,
    required String token,
  });

  /// Construye la URL para el WebView de pago.
  String buildPagoUrl(PagoRequest pagoRequest);
}
