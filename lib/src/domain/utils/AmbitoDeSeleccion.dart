import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';

/// El **ámbito de selección**: dónde empieza y dónde acaba la regla de pagar en
/// orden.
///
/// La regla del colegio es que las parcialidades de un cargo se liquiden de la
/// más antigua a la más reciente. Eso solo tiene sentido **dentro de un mismo
/// cargo**: que un alumno deba `COLEGIATURA` no puede impedirle pagar
/// `EXTENSION DE HORARIO`, que es otro concepto con su propia fila de
/// parcialidades.
///
/// El ámbito lo forman cuatro datos del renglón, y hay un motivo distinto para
/// cada uno:
///
/// | Pieza | Por qué |
/// | --- | --- |
/// | `cicloId` | Los pagos de un ciclo nunca condicionan los de otro |
/// | `emisorFiscalId` | Cada emisor es otra pantalla y otro carrito: pedir los del emisor 1 para marcar el primero del 2 dejaría un renglón bloqueado sin explicación posible |
/// | `pagoId` | **El concepto.** Es la clave con la que el backend agrupa las parcialidades y de la que saca `num_pago_activo` |
/// | `deudaAnterior` | Una deuda arrastrada puede vivir en el ciclo en curso con el mismo cargo que la deuda viva; son dos filas independientes y el backend no las separa |
///
/// El **alumno** no entra en la clave: ese ámbito ya lo da la estructura
/// `{cicloId: {alumnoId: [pagoId]}}` con la que se guarda la selección.
///
/// Todo lo que evalúe la regla —el orden ascendente al seleccionar, el arrastre
/// al deseleccionar y el poder quitar del carrito— tiene que acotarse con esto
/// y con nada menos. Cada vez que se ha recortado la clave ha salido un fallo:
/// primero al mezclar ciclos, después al mezclar emisores, y el 08-sep-2026 al
/// mezclar conceptos, con IVANA sin poder pagar su extensión de horario.
String ambitoDeSeleccion(EstadoDeCuenta pago) =>
    '${pago.cicloId}-${pago.emisorFiscalId}-${pago.pagoId}-${pago.deudaAnterior}';

/// Utilidades de lista para no repetir el filtro del ámbito en cada pantalla.
extension PagosDelMismoAmbito on Iterable<EstadoDeCuenta> {
  /// Los pagos que comparten ámbito con [pago], **ordenados por id**.
  ///
  /// Incluye al propio [pago] cuando está en la lista. El orden es el mismo que
  /// usa la regla: de la parcialidad más antigua a la más reciente.
  List<EstadoDeCuenta> delMismoAmbitoQue(EstadoDeCuenta pago) {
    final String ambito = ambitoDeSeleccion(pago);
    final List<EstadoDeCuenta> resultado = where(
      (otro) => ambitoDeSeleccion(otro) == ambito,
    ).toList()..sort((a, b) => a.id.compareTo(b.id));
    return resultado;
  }

  /// Ids de los pagos del mismo ámbito que [pago], de menor a mayor.
  List<int> idsDelMismoAmbitoQue(EstadoDeCuenta pago) =>
      delMismoAmbitoQue(pago).map((e) => e.id).toList();
}
