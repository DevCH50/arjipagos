import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Botón de campana con badge que muestra el conteo de notificaciones no leídas.
///
/// Diseñado para usarse como acción en el AppBar del menú principal.
/// Lee el [NotificacionBloc] directamente desde el árbol de widgets global.
///
/// Al presionar, navega a la pantalla de notificaciones y al regresar
/// refresca únicamente el conteo mediante [ActualizarContadorEvent].
class NotificacionBadgeButton extends StatelessWidget {
  const NotificacionBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificacionBloc, NotificacionState>(
      // Solo reconstruir cuando cambia el conteo de no leídas.
      buildWhen: (prev, curr) => prev.noLeidas != curr.noLeidas,
      builder: (context, state) {
        if (state.noLeidas > 0) {
          return _buildConBadge(context, state.noLeidas);
        }
        return _buildSinBadge(context);
      },
    );
  }

  /// Construye el botón con badge cuando hay notificaciones no leídas.
  Widget _buildConBadge(BuildContext context, int cantidad) {
    return badges.Badge(
      badgeContent: Text(
        '$cantidad',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      badgeAnimation: const badges.BadgeAnimation.scale(),
      badgeStyle: badges.BadgeStyle(
        badgeColor: Theme.of(context).colorScheme.error,
        padding: const EdgeInsets.all(4),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications),
        tooltip: 'Notificaciones',
        onPressed: () => _navegarANotificaciones(context),
      ),
    );
  }

  /// Construye el botón simple sin badge cuando no hay notificaciones sin leer.
  Widget _buildSinBadge(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Notificaciones',
      onPressed: () => _navegarANotificaciones(context),
    );
  }

  /// Navega a la pantalla de notificaciones y refresca el contador al volver.
  void _navegarANotificaciones(BuildContext context) {
    Navigator.pushNamed(context, 'notificaciones').then((_) {
      if (context.mounted) {
        context.read<NotificacionBloc>().add(const ActualizarContadorEvent());
      }
    });
  }
}
