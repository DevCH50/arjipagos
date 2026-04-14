import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_items_list.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_drawer.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_header.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_badge_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        title: const Text(AppStrings.menuPrincipalTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: AppStrings.menuMiCuenta,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Botón de notificaciones con badge de no leídas
          const NotificacionBadgeButton(),
        ],
      ),
      drawer: const UserDrawer(),
      body: const _MenuPrincipalBody(),
    );
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
              nombre: state.nombreUsuario ?? AppStrings.loginUsername,
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
        title: const Text(AppStrings.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.accept),
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

    Navigator.pushNamed(context, item.ruta!);
  }
}
