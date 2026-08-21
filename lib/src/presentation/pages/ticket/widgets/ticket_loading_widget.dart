import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Indicador de carga del ticket.
///
/// Cubre las dos esperas del flujo: la descarga del PDF desde el servidor y la
/// apertura del documento en el visor. El mensaje distingue una de otra para
/// que el usuario sepa qué está pasando.
class TicketLoadingWidget extends StatelessWidget {
  /// Texto bajo el indicador; por defecto, el de la descarga.
  final String mensaje;

  const TicketLoadingWidget({
    super.key,
    this.mensaje = AppStrings.ticketDescargando,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensaje),
        ],
      ),
    );
  }
}
