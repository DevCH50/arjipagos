import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoCobroOpenpay.dart';

/// Qué se le dice al tutor, y a dónde se le lleva, según en qué quedó un cobro
/// de OpenPay que se cerró sin retorno —o uno de Adquira rechazado con el
/// código 5, ver [AvisoCierreCobro.referenciaYaCobrada]—.
///
/// Es la tabla acordada con el backend el 2026-09-28, sin nada de Flutter para
/// poder probarla sola. El caso `pagado` no está aquí: usa el diálogo de éxito
/// de siempre, el mismo que cuando llega el retorno.
///
/// | Estado | Aviso | Después |
/// | --- | --- | --- |
/// | rechazado | «Pago rechazado» con el `message` | Al carrito, con su selección |
/// | pendiente | «No se completó el pago» | Al carrito, con su selección |
/// | sin confirmar | «No pudimos confirmar tu pago» | Vacía el carrito y va a la lista |
///
/// **Por qué «sin confirmar» vacía el carrito.** Puede que el dinero sí
/// saliera. Devolver al tutor a un carrito lleno, con el botón «Pagar»
/// delante, es invitarle a pagar dos veces. La lista recargada del emisor le
/// dice la verdad: si los cargos siguen ahí, no se cobraron.
enum TipoAvisoCierre {
  /// Hubo un rechazo: se pinta como error.
  rechazo,

  /// No pasó nada malo, solo que no se pagó.
  informativo,

  /// Puede que se cobrara: se pinta como advertencia.
  advertencia,
}

/// Aviso que se muestra al cerrar un cobro de OpenPay que no se pagó, o del
/// que no se sabe si se pagó.
class AvisoCierreCobro {
  final TipoAvisoCierre tipo;
  final String titulo;
  final String mensaje;

  /// `true`: vaciar el carrito y volver a la lista del emisor, recargándola.
  /// `false`: volver al carrito con la selección intacta.
  final bool vaciarCarrito;

  const AvisoCierreCobro._({
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.vaciarCarrito,
  });

  /// Adquira rechazó con código 5: la referencia ya se había usado.
  ///
  /// Es el mismo caso que «sin confirmar»: puede que el dinero ya saliera,
  /// así que se vacía el carrito y se vuelve a la lista recargada, sin
  /// «Reintentar». Adquira no tiene consulta de estado, así que aquí no hay
  /// `message` del backend que valga más que el texto propio.
  static const AvisoCierreCobro referenciaYaCobrada = AvisoCierreCobro._(
    tipo: TipoAvisoCierre.advertencia,
    titulo: AppStrings.adquiraReferenciaUsadaTitle,
    mensaje: AppStrings.adquiraReferenciaUsadaMsg,
    vaciarCarrito: true,
  );

  /// El aviso de [resultado], o `null` si el cobro está pagado.
  ///
  /// Se prefiere el `message` del backend cuando lo hay, porque distingue
  /// casos que desde aquí no se ven —el motivo exacto del rechazo, o el «NO
  /// vuelvas a pagar» cuando no pudo confirmar—. Solo en `pendiente` manda el
  /// texto propio: el del backend es un escueto «El pago no se completó.» y al
  /// tutor le sirve más saber que sus pagos siguen en el carrito.
  static AvisoCierreCobro? para(EstadoCobroOpenpay resultado) {
    final String delBackend = resultado.mensaje;

    return switch (resultado.estado) {
      EstadoCobro.pagado => null,
      EstadoCobro.rechazado => AvisoCierreCobro._(
        tipo: TipoAvisoCierre.rechazo,
        titulo: AppStrings.openpayRechazadoTitle,
        mensaje: delBackend.isNotEmpty
            ? delBackend
            : AppStrings.openpayRechazadoMsg,
        vaciarCarrito: false,
      ),
      EstadoCobro.pendiente => const AvisoCierreCobro._(
        tipo: TipoAvisoCierre.informativo,
        titulo: AppStrings.openpayNoCompletadoTitle,
        mensaje: AppStrings.openpayNoCompletadoMsg,
        vaciarCarrito: false,
      ),
      EstadoCobro.sinConfirmar => AvisoCierreCobro._(
        tipo: TipoAvisoCierre.advertencia,
        titulo: AppStrings.openpaySinConfirmarTitle,
        mensaje: delBackend.isNotEmpty
            ? delBackend
            : AppStrings.openpaySinConfirmarMsg,
        vaciarCarrito: true,
      ),
    };
  }
}
