import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio para los estados de cuenta ya pagados.
///
/// Se mantiene aparte de `EdoCtaRepository` (pagos pendientes) para que el
/// flujo de pago —selección, carrito y Adquira— no dependa de esta consulta.
abstract class EdoCtaPagadosRepository {
  /// Obtiene los pagos ya realizados de todos los alumnos de la familia.
  Future<Resource<EstadosDeCuentaResponse>> getEstadosDeCuentaPagados();
}
