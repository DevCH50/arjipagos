import 'package:arjipagos/src/domain/useCases/pago/IniciarPagoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/pago/VerificarPagoUseCase.dart';

/// Agrupador de casos de uso relacionados con pagos.
class PagoUseCases {
  final IniciarPagoUseCase iniciarPago;
  final VerificarPagoUseCase verificarPago;

  PagoUseCases({
    required this.iniciarPago,
    required this.verificarPago,
  });
}
