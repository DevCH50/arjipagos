import 'package:arjipagos/src/data/dataSource/remote/services/FacturaService.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/repository/FacturaRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de facturas.
///
/// Delega las operaciones al servicio HTTP [FacturaService].
class FacturaRepositoryImpl implements FacturaRepository {
  final FacturaService facturaService;

  FacturaRepositoryImpl(this.facturaService);

  @override
  Future<Resource<FacturaResponse>> getFacturas() async {
    try {
      return await facturaService.getFacturas();
    } catch (e) {
      return Error<FacturaResponse>('Error al obtener facturas: $e');
    }
  }
}
