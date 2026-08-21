import 'package:flutter/material.dart';

/// Puntos que indican cuántos avisos hay y en cuál está el usuario.
///
/// No son tocables a propósito: un punto de 6 px jamás alcanzaría el mínimo de
/// 44-48 px de área táctil, y un objetivo así de pequeño solo genera toques
/// fallidos. Para moverse está el arrastre del carrusel, que ocupa la tarjeta
/// entera.
class BannersIndicador extends StatelessWidget {
  const BannersIndicador({
    super.key,
    required this.total,
    required this.actual,
  });

  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          total,
          (i) => _buildPunto(colorScheme, activo: i == actual),
        ),
      ),
    );
  }

  /// Punto individual; el activo se alarga en vez de solo cambiar de color,
  /// para que también se distinga sin percibir el color.
  Widget _buildPunto(ColorScheme colorScheme, {required bool activo}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 6,
      width: activo ? 18 : 6,
      decoration: BoxDecoration(
        color: activo
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
