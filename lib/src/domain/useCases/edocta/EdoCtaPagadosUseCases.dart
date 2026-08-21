import 'package:arjipagos/src/domain/useCases/edocta/GetEstadosDeCuentaPagadosUseCase.dart';

/// Agrupador de casos de uso relacionados con los pagos realizados.
///
/// Se mantiene separado de `EdoCtaUseCases` a propósito: así el flujo de pagos
/// pendientes (selección, carrito y Adquira) conserva su contrato intacto y no
/// hay que tocar sus BLoCs ni sus tests para añadir esta consulta.
class EdoCtaPagadosUseCases {
  final GetEstadosDeCuentaPagadosUseCase getEstadosDeCuentaPagados;

  EdoCtaPagadosUseCases({required this.getEstadosDeCuentaPagados});
}
