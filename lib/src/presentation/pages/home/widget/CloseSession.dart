import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget reutilizable para diálogos de confirmación
class CloseSession extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String confirmText;
  final String cancelText;
  final Color? confirmButtonColor;
  final Color? confirmTextColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CloseSession({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.confirmText = AppStrings.confirm,
    this.cancelText = AppStrings.cancel,
    this.confirmButtonColor,
    this.confirmTextColor,
    this.onConfirm,
    this.onCancel,
  });

  /// Método estático para mostrar el diálogo y obtener resultado
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String confirmText = AppStrings.confirm,
    String cancelText = AppStrings.cancel,
    Color? confirmButtonColor,
    Color? confirmTextColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CloseSession(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmButtonColor: confirmButtonColor,
        confirmTextColor: confirmTextColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
            Navigator.pop(context, false);
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmButtonColor ?? Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              color: confirmTextColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
