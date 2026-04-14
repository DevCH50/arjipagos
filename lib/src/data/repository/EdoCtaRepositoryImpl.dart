import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de estados de cuenta.
///
/// Delega las operaciones al servicio HTTP [EdoCtaService].
class EdoCtaRepositoryImpl implements EdoCtaRepository {
  final EdoCtaService edoCtaService;

  EdoCtaRepositoryImpl(this.edoCtaService);

  @override
  Future<Resource<EstadosDeCuentaResponse>> getEstadosDeCuenta() async {
    try {
      final result = await edoCtaService.getEstadosDeCuenta();
      return result;
    } catch (e) {
      return Error<EstadosDeCuentaResponse>('Error al obtener estados de cuenta: $e');
    }
  }
}
