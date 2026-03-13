import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_item_model.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_item_tile.dart';
import 'package:flutter/material.dart';

/// Lista de items del menú principal.
///
/// Muestra los items del menú en un ListView separado por dividers.
class MenuItemsList extends StatelessWidget {
  /// Lista de items a mostrar.
  final List<MenuItem> items;

  const MenuItemsList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => MenuItemTile(item: items[index]),
    );
  }
}
