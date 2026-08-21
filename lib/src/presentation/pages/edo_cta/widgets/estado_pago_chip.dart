import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:flutter/material.dart';

/// Píldora con el estado del pago (Pendiente/Vencido/Pagado).
///
/// Lleva un **punto de color** además del texto: el estado se distingue de un
/// vistazo por la posición y el color del punto, pero sigue siendo legible para
/// quien no percibe el color, porque la palabra está escrita.
///
/// El fondo depende de si el renglón está teñido. Sobre un renglón seleccionado
/// o vencido —que ya traen su propio tinte— la píldora se pinta en `surface`
/// para que se despegue del fondo; sobre un renglón normal usa el contenedor
/// más alto del tema, que es el mismo tono del que sale el tinte.
///
/// No se estira: es una píldora, así que vive en su tamaño natural. Quien la
/// coloque dentro de un `Expanded` debe envolverla en un `Align`.
class EstadoPagoChip extends StatelessWidget {
  const EstadoPagoChip({
    super.key,
    required this.estadoPago,
    this.sobreTinte = false,
  });

  final EstadoPago estadoPago;

  /// `true` cuando el renglón que la contiene ya tiene un tinte de fondo.
  final bool sobreTinte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: sobreTinte
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPunto(colorScheme),
          const SizedBox(width: 6),
          Text(
            _etiqueta(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: _colorTexto(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  /// Punto de color del estado.
  Widget _buildPunto(ColorScheme colorScheme) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _colorPunto(colorScheme),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Color del punto.
  ///
  /// El vencido sale del tema —así se adapta solo a claro y oscuro—; el verde y
  /// el ámbar no tienen equivalente en el esquema Material 3 y se toman de
  /// `AppColors`. Los dos leen bien sobre las dos superficies, por eso no
  /// cambian con el tema: como relleno pequeño no necesitan la variante clara,
  /// que sí hace falta cuando el color se usa en texto.
  Color _colorPunto(ColorScheme colorScheme) {
    switch (estadoPago) {
      case EstadoPago.vencido:
        return colorScheme.error;
      case EstadoPago.pagado:
        return AppColors.success;
      case EstadoPago.pendiente:
        return AppColors.warning;
    }
  }

  /// Color del texto; solo el vencido se sale del gris de apoyo.
  Color _colorTexto(ColorScheme colorScheme) {
    return estadoPago == EstadoPago.vencido
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
  }

  /// Texto visible de la píldora.
  String _etiqueta() {
    switch (estadoPago) {
      case EstadoPago.vencido:
        return AppStrings.edoCtaVencido;
      case EstadoPago.pagado:
        return AppStrings.edoCtaPagado;
      case EstadoPago.pendiente:
        return AppStrings.edoCtaPendiente;
    }
  }
}
