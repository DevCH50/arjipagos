import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_item_model.dart';
import 'package:arjipagos/src/presentation/widgets/IconoDeMenu.dart';
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 8,
      ),
      leading: IconoDeMenu(icono: item.icono),
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
