import 'package:arjipagos/src/domain/models/OpenpayCheckout.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Por qué no se pudo crear un cobro de OpenPay, cuando eso cambia lo que la
/// app hace después de enseñar el mensaje.
///
/// Lo pide el documento del backend («App del cobro OpenPay», 2026-09-28):
/// un `401` lleva al login y un `422` obliga a recargar los cargos. El resto de
/// fallos solo enseñan el mensaje y dejan al tutor en el carrito.
enum MotivoFalloCobro {
  /// `401`: la sesión venció. Hay que volver a entrar.
  sesionExpirada,

  /// `422`: los cargos ya no se pueden cobrar así —ya pagados, fuera de
  /// orden, de otro emisor o no disponibles por esta vía—. El carrito está
  /// desactualizado y hay que recargar la lista.
  cargosDesactualizados,

  /// Cualquier otro: OpenPay rechazó crear el cargo, no está configurado, la
  /// red falló… Se enseña el mensaje y se puede reintentar.
  otro,
}

/// [Error] de `crear-cargo` que además dice el [motivo].
///
/// Extiende `Error<OpenpayCheckout>` para que quien solo mira el mensaje
/// —como hasta ahora— siga funcionando sin cambios.
class ErrorCobroOpenpay extends Error<OpenpayCheckout> {
  ErrorCobroOpenpay(super.msg, this.motivo);

  final MotivoFalloCobro motivo;
}
