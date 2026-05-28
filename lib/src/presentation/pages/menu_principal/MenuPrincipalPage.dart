import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_items_list.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_drawer.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_header.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_badge_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página del Menú Principal.
///
/// Muestra las opciones principales de la aplicación después del login.
/// Incluye información del usuario y lista de módulos disponibles.
///
/// Detecta cuándo el usuario abrió la app desde una notificación de sistema
/// (background o app terminada) y navega automáticamente a [NotificacionesPage].
class MenuPrincipalPage extends StatefulWidget {
  const MenuPrincipalPage({super.key});

  @override
  State<MenuPrincipalPage> createState() => _MenuPrincipalPageState();
}

class _MenuPrincipalPageState extends State<MenuPrincipalPage> {
  @override
  void initState() {
    super.initState();
    // Caso app terminada: getInitialMessage puede haber disparado
    // NotificacionAbiertaDesdeBackgroundEvent antes de que esta página
    // se montara; verificar el estado inicial del BLoC tras el primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bloc = context.read<NotificacionBloc>();
      if (bloc.state.debeNavegar) {
        bloc.add(const ResetDebeNavegarEvent());
        Navigator.of(context).pushNamed('notificaciones');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificacionBloc, NotificacionState>(
      // Caso app en background: el usuario toca la notificación mientras
      // la app ya está corriendo; el BLoC transiciona debeNavegar a true.
      listenWhen: (prev, curr) => curr.debeNavegar && !prev.debeNavegar,
      listener: (context, state) {
        context.read<NotificacionBloc>().add(const ResetDebeNavegarEvent());
        Navigator.of(context).pushNamed('notificaciones');
      },
      child: Scaffold(
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
      ),
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
