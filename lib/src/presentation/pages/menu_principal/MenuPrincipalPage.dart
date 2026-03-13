import 'package:arjipagos/src/presentation/pages/home/widget/CloseSession.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_items_list.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_drawer.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../main.dart';

/// Página del Menú Principal.
///
/// Muestra las opciones principales de la aplicación después del login.
/// Incluye información del usuario y lista de módulos disponibles.
class MenuPrincipalPage extends StatelessWidget {
  const MenuPrincipalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Mi cuenta',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      drawer: const UserDrawer(),
      body: const _MenuPrincipalBody(),
    );
  }

  /// Maneja el cierre de sesión.
  void _handleLogout(BuildContext context) async {
    final bloc = context.read<MenuPrincipalBloc>();

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloseSession(
        title: 'Cerrar Sesión',
        message: '¿Estás seguro que deseas cerrar sesión?',
        icon: Icons.logout,
        iconColor: Colors.orange,
        confirmText: 'Cerrar Sesión',
        cancelText: 'Cancelar',
        confirmButtonColor: Colors.red,
        confirmTextColor: Colors.white,
        onConfirm: () {},
        onCancel: () {},
      ),
    );

    if (shouldLogout == true && context.mounted) {
      bloc.add(const MenuPrincipalLogout());
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    }
  }
}

/// Cuerpo del menú principal con información del usuario y lista de items.
class _MenuPrincipalBody extends StatelessWidget {
  const _MenuPrincipalBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MenuPrincipalBloc, MenuPrincipalState>(
      listenWhen: (previous, current) =>
          previous.selectedItemId != current.selectedItemId ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        // Mostrar diálogo de error si existe
        if (state.errorMessage != null) {
          _showErrorDialog(context, state.errorMessage!);
        }

        // Navegar si se seleccionó un item
        if (state.selectedItemId != null) {
          _handleNavigation(context, state);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Header con información del usuario
            UserHeader(
              nombre: state.nombreUsuario ?? 'Usuario',
              email: state.emailUsuario,
            ),
            const Divider(height: 1),
            // Lista de items del menú
            Expanded(
              child: MenuItemsList(items: state.menuItems),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de error.
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  /// Maneja la navegación según el item seleccionado.
  void _handleNavigation(BuildContext context, MenuPrincipalState state) {
    final item = state.menuItems.firstWhere(
      (i) => i.id == state.selectedItemId,
    );

    if (item.ruta == null) {
      return;
    }

    // Verificar si la ruta está implementada
    if (item.ruta == 'facturas') {
      _showComingSoonDialog(context);
    } else {
      Navigator.pushNamed(context, item.ruta!);
    }
  }

  /// Muestra diálogo "Próximamente".
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.construction,
          color: Theme.of(ctx).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Próximamente'),
        content: const Text(
          'La sección de Facturas estará disponible pronto.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
