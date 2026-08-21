import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Acciones del ticket, al alcance del pulgar y bajo el documento.
///
/// Ahora que el PDF se ve dentro de la app, salir a otra aplicación pasa a ser
/// una elección explícita del usuario y no el camino por defecto: *Compartir*
/// es la acción principal (enviarlo o guardarlo) y *Abrir en otra app* queda
/// como salida secundaria para quien prefiera su propio visor.
class TicketAccionesBar extends StatelessWidget {
  /// Entrega el PDF a la hoja del sistema para enviarlo o guardarlo.
  final VoidCallback onCompartir;

  /// Lo abre con el visor que el usuario elija.
  final VoidCallback onAbrirFuera;

  const TicketAccionesBar({
    super.key,
    required this.onCompartir,
    required this.onAbrirFuera,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Container(
      // Separa visualmente las acciones del documento en ambos temas, sin
      // recurrir a una sombra que en oscuro no se ve.
      decoration: BoxDecoration(
        color: colores.surface,
        border: Border(top: BorderSide(color: colores.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // Apiladas, no en fila: los dos botones con texto no caben en una fila de
      // 360 dp —desbordaba por 2 px— y con el tamaño de fuente del sistema
      // aumentado el margen sería aún menor. Así entran en cualquier ancho.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onCompartir,
              icon: const Icon(Icons.share_outlined),
              label: const Text(AppStrings.ticketCompartir),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onAbrirFuera,
            icon: const Icon(Icons.open_in_new),
            label: const Text(AppStrings.ticketAbrirEnOtraApp),
          ),
        ],
      ),
    );
  }
}
