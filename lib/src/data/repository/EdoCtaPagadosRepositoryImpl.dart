import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaPagadosService.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaPagadosRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de pagos realizados.
///
/// Delega las operaciones al servicio HTTP [EdoCtaPagadosService].
class EdoCtaPagadosRepositoryImpl implements EdoCtaPagadosRepository {
  final EdoCtaPagadosService edoCtaPagadosService;

  EdoCtaPagadosRepositoryImpl(this.edoCtaPagadosService);

  @override
  Future<Resource<EstadosDeCuentaResponse>> getEstadosDeCuentaPagados() async {
    try {
      final result = await edoCtaPagadosService.getEstadosDeCuentaPagados();
      return result;
    } catch (e) {
      // El mensaje que llega a la pantalla nunca es la excepción cruda.
      AppLogger.error('Error al obtener pagos realizados: $e', tag: 'EdoCtaPagados');
      return Error<EstadosDeCuentaResponse>(mensajeErrorRed(e));
    }
  }
}
