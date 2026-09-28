import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/ErrorCobroOpenpay.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/utils/CierreDeSesion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lo que hace el carrito al cerrar el diálogo de un cobro de OpenPay que no
/// se pudo crear, según el [motivo].
///
/// Lo pide el documento del backend («App del cobro OpenPay», 2026-09-28):
///
/// | Motivo | Después del diálogo |
/// | --- | --- |
/// | `401` sesión vencida | Cierre de sesión completo y al login |
/// | `422` cargos desactualizados | Vacía el carrito, recarga la lista del emisor y vuelve a ella |
/// | cualquier otro, o `null` | Nada: el tutor sigue en el carrito y puede reintentar |
///
/// El 422 no se reintenta desde el carrito porque los cargos que tiene ya no
/// se pueden cobrar así (pagados, fuera de orden…): volver a pulsar «Pagar»
/// daría el mismo error. La lista recargada enseña lo que sí queda pendiente.
///
/// [cerrarSesion] es `cerrarSesionCompleta` salvo en los tests: la de verdad
/// necesita los BLoC de toda la app montados.
Future<void> actuarTrasFalloCobro(
  BuildContext context, {
  required MotivoFalloCobro? motivo,
  required int emisorFiscalId,
  Future<void> Function(BuildContext) cerrarSesion = cerrarSesionCompleta,
}) async {
  switch (motivo) {
    case MotivoFalloCobro.sesionExpirada:
      // El Navigator raíz: su contexto sigue valiendo tras el `await` y cuelga
      // por debajo de los BLoC que `cerrarSesionCompleta` vacía. Mismo patrón
      // que el cierre de sesión del drawer.
      final NavigatorState navigator = Navigator.of(
        context,
        rootNavigator: true,
      );
      await cerrarSesion(navigator.context);
      // `restorable*` y la ruta 'login': nunca un `MyApp` nuevo (CLAUDE.md).
      navigator.restorablePushNamedAndRemoveUntil('login', (_) => false);
    case MotivoFalloCobro.cargosDesactualizados:
      context.read<CarritoBloc>().add(const CarritoLimpiarEvent());
      locator<EdoCtaListBlocPorEmisor>()
          .de(emisorFiscalId)
          .add(const EdoCtaListRefreshEvent());
      final String ruta = ConfiguracionAdquira.para(emisorFiscalId).ruta;
      Navigator.of(context).popUntil((route) => route.settings.name == ruta);
    case MotivoFalloCobro.otro || null:
      break;
  }
}
