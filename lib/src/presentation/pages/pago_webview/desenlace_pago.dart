import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/aviso_cierre_cobro.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/widgets/pago_dialogs.dart';
import 'package:flutter/material.dart';

/// Lo que pasa cuando un pago termina: a quién se avisa, qué se le enseña al
/// tutor y a dónde se le lleva.
///
/// `PagoWebViewPage` decide **cuándo** termina —el retorno, la ✕, la consulta
/// de estado de OpenPay— y esta clase hace el **qué**. Está aparte para que la
/// página se quede en lo suyo, que es el WebView.
///
/// Todo va por el emisor que se está cobrando: su carrito, su lista y su
/// pantalla. El otro emisor no se entera de nada.
class DesenlacePago {
  DesenlacePago(this.emisorFiscalId);

  final int emisorFiscalId;

  /// Carrito del emisor que se está cobrando.
  ///
  /// Va por el registro y no por `context.read`: hay un carrito por emisor y
  /// hay que avisar exactamente al suyo.
  CarritoBloc get carrito => locator<CarritoBlocPorEmisor>().de(emisorFiscalId);

  /// Pago confirmado, llegue por el retorno o por la consulta de estado.
  void exito(BuildContext context) {
    carrito.add(const CarritoPagoExitosoEvent());
    // Suma el pago a la cuenta de la política de reseñas antes de mostrar el
    // diálogo, para que al cerrarlo el contador ya esté al día.
    locator<ResenaUseCases>().registrarPagoExitoso.run();
    PagoDialogs.mostrarExito(
      context: context,
      onAceptar: () {
        _volverALista(context);
        _invitarACalificar();
      },
    );
  }

  /// El retorno dijo que el pago falló (Adquira).
  ///
  /// «Volver» lleva al carrito; «Reintentar» vuelve a abrir la pasarela.
  void fallo(
    BuildContext context,
    String mensaje, {
    required VoidCallback onReintentar,
  }) {
    carrito.add(CarritoPagoFallidoEvent(mensaje));
    PagoDialogs.mostrarError(
      context: context,
      mensaje: mensaje,
      onVolver: () => Navigator.pop(context),
      onReintentar: onReintentar,
    );
  }

  /// Pregunta antes de abandonar la pasarela, y si confirma, vuelve al
  /// carrito con la selección intacta.
  void confirmarCancelar(BuildContext context) {
    PagoDialogs.confirmarCancelar(
      context: context,
      onCancelar: () {
        carrito.add(const CarritoCancelarPagoEvent());
        Navigator.pop(context);
      },
    );
  }

  /// Cobro de OpenPay que no se pagó, o del que no se sabe si se pagó.
  ///
  /// Qué aviso y a dónde se vuelve lo decide [AvisoCierreCobro]: al carrito
  /// con la selección intacta, o —si puede que se cobrara— a la lista del
  /// emisor con el carrito vacío, para que no haya un «Pagar» delante.
  void avisoDeCierre(BuildContext context, AvisoCierreCobro aviso) {
    PagoDialogs.mostrarAvisoCierre(
      context: context,
      aviso: aviso,
      onAceptar: () {
        carrito.add(const CarritoCancelarPagoEvent());
        if (!aviso.vaciarCarrito) {
          Navigator.pop(context);
          return;
        }
        carrito.add(const CarritoLimpiarEvent());
        _volverALista(context);
      },
    );
  }

  /// Recarga la lista del emisor cobrado y vuelve a SU pantalla.
  void _volverALista(BuildContext context) {
    locator<EdoCtaListBlocPorEmisor>()
        .de(emisorFiscalId)
        .add(const EdoCtaListRefreshEvent());
    final String ruta = ConfiguracionAdquira.para(emisorFiscalId).ruta;
    Navigator.of(context).popUntil((route) => route.settings.name == ruta);
  }

  /// Invita a calificar la app, si la política lo permite.
  ///
  /// Va después del `popUntil` y en un post-frame a propósito: la hoja de
  /// reseña la pinta el sistema encima de lo que haya, y debe salir sobre el
  /// estado de cuenta ya restaurado, no sobre el WebView que se está cerrando.
  ///
  /// No se espera el resultado ni se avisa de nada: el caso de uso decide si
  /// toca, y ni Apple ni Google informan de si la hoja llegó a mostrarse.
  void _invitarACalificar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator<ResenaUseCases>().solicitarResena.run();
    });
  }
}
