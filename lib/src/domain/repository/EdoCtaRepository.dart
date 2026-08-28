import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio para estados de cuenta.
///
/// Define el contrato para obtener estados de cuenta sin pagar.
abstract class EdoCtaRepository {
  /// Obtiene los estados de cuenta sin pagar de todos los alumnos.
  ///
  /// [emisorFiscalId] acota la consulta a un emisor (1 "Pagos Pendientes",
  /// 2 "Otros pagos"). Omitirlo trae los de todos, que es lo que necesita
  /// `MenuPrincipalBloc` para la familia y los alumnos.
  Future<Resource<EstadosDeCuentaResponse>> getEstadosDeCuenta({
    int? emisorFiscalId,
  });
}
