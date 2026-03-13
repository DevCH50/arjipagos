import 'package:arjipagos/src/domain/useCases/edocta/GetEstadosDeCuentaUseCase.dart';

/// Agrupador de casos de uso relacionados con estados de cuenta.
///
/// Facilita la inyección de dependencias al tener un solo
/// objeto que contiene todos los casos de uso de EdoCta.
class EdoCtaUseCases {
  final GetEstadosDeCuentaUseCase getEstadosDeCuenta;

  EdoCtaUseCases({required this.getEstadosDeCuenta});
}
