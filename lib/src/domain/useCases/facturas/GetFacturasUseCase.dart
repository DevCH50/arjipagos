import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/repository/FacturaRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para obtener las facturas del usuario autenticado.
class GetFacturasUseCase {
  final FacturaRepository repository;

  GetFacturasUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Resource<FacturaResponse>] con las facturas o un error.
  Future<Resource<FacturaResponse>> run() => repository.getFacturas();
}
