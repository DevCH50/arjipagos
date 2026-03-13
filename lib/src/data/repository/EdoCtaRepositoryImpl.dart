import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart';
import 'package:arjipagos/src/domain/models/EstatodosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de estados de cuenta.
///
/// Delega las operaciones al servicio HTTP [EdoCtaService].
class EdoCtaRepositoryImpl implements EdoCtaRepository {
  final EdoCtaService edoCtaService;

  EdoCtaRepositoryImpl(this.edoCtaService);

  @override
  Future<Resource<EstatodosDeCuentaResponse>> getEstadosDeCuenta() async {
    try {
      final result = await edoCtaService.getEstadosDeCuenta();
      return result;
    } catch (e) {
      return Error<EstatodosDeCuentaResponse>('Error al obtener estados de cuenta: $e');
    }
  }
}
