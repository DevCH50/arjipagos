import 'package:arjipagos/src/domain/models/EstatodosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio para estados de cuenta.
///
/// Define el contrato para obtener estados de cuenta sin pagar.
abstract class EdoCtaRepository {
  /// Obtiene los estados de cuenta sin pagar de todos los alumnos.
  Future<Resource<EstatodosDeCuentaResponse>> getEstadosDeCuenta();
}
