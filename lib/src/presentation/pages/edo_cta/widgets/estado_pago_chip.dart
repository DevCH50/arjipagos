import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:flutter/material.dart';

/// Chip que muestra el estado del pago (Pendiente/Vencido).
class EstadoPagoChip extends StatelessWidget {
  final EstadoPago estadoPago;

  const EstadoPagoChip({
    super.key,
    required this.estadoPago,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isVencido = estadoPago == EstadoPago.vencido;

    // Colores más claros para tema oscuro
    final bgColor = isVencido
        ? AppColors.error.withValues(alpha: isDark ? 0.3 : 0.15)
        : AppColors.warning.withValues(alpha: isDark ? 0.3 : 0.15);

    final textColor = isDark
        ? (isVencido ? AppColors.errorLight : AppColors.warningLight)
        : (isVencido ? AppColors.error : AppColors.warning);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isVencido ? AppStrings.edoCtaVencido : AppStrings.edoCtaPendiente,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
