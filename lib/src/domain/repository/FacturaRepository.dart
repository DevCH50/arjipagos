import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio de facturas.
///
/// Define el contrato para obtener las facturas del usuario autenticado.
abstract class FacturaRepository {
  /// Obtiene las facturas del usuario con los archivos ZIP en base64.
  Future<Resource<FacturaResponse>> getFacturas();
}
