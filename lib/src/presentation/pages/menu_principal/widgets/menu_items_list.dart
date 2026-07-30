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
      // Edge-to-edge (Android 15+): la lista se dibuja debajo de la barra de
      // navegacion del sistema, asi que sumamos su alto al padding inferior
      // para que el ultimo item del menu siga siendo alcanzable.
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        8 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => MenuItemTile(item: items[index]),
    );
  }
}
