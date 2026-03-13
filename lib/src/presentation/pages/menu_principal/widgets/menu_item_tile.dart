import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tile individual de un item del menú.
///
/// Compatible con tema claro y oscuro.
/// Al tocar, emite un evento al BLoC para navegación.
class MenuItemTile extends StatelessWidget {
  /// Item del menú a mostrar.
  final MenuItem item;

  const MenuItemTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores adaptables al tema
    final iconBackgroundColor = colorScheme.primaryContainer.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.3 : 0.5,
    );
    final iconColor = colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.icono,
          color: iconColor,
          size: 28,
        ),
      ),
      title: Text(
        item.titulo,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        context.read<MenuPrincipalBloc>().add(
          MenuItemSelected(itemId: item.id),
        );
      },
    );
  }
}
