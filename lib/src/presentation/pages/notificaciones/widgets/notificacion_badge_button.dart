import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Botón de campana con indicador visual de notificaciones no leídas.
///
/// Diseñado para usarse como acción en el AppBar del menú principal.
/// Lee el [NotificacionBloc] directamente desde el árbol de widgets global.
///
/// Comportamiento visual:
/// - Sin notificaciones: campana outline simple.
/// - Con no leídas: campana sólida [Icons.notifications].
/// - Nueva notificación en foreground ([hayNueva]): punto rojo pulsante en la
///   esquina inferior derecha + icono sólido [Icons.notifications_active].
///   El pulso se detiene en cuanto el usuario toca la campana.
class NotificacionBadgeButton extends StatefulWidget {
  const NotificacionBadgeButton({super.key});

  @override
  State<NotificacionBadgeButton> createState() =>
      _NotificacionBadgeButtonState();
}

class _NotificacionBadgeButtonState extends State<NotificacionBadgeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificacionBloc, NotificacionState>(
      // Reaccionar a cambios de hayNueva para controlar la animación.
      listenWhen: (prev, curr) => prev.hayNueva != curr.hayNueva,
      listener: (context, state) {
        if (state.hayNueva) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      },
      // Reconstruir cuando cambia el conteo o el indicador de nueva notificación.
      buildWhen: (prev, curr) =>
          prev.noLeidas != curr.noLeidas || prev.hayNueva != curr.hayNueva,
      builder: (context, state) {
        final errorColor = Theme.of(context).colorScheme.error;

        // Ícono base: sólido si hay no leídas o nueva, outline si todo leído.
        final iconData = state.hayNueva
            ? Icons.notifications_active
            : (state.noLeidas > 0
                ? Icons.notifications
                : Icons.notifications_outlined);

        final iconButton = IconButton(
          icon: Icon(iconData),
          tooltip: AppStrings.notificacionesTitle,
          onPressed: () => _navegarANotificaciones(context),
        );

        // Construir de adentro hacia afuera.
        // 1. Ícono base (sin badge numérico).
        Widget result = iconButton;

        // 2. Punto rojo pulsante (bottom-right) cuando hay nueva notificación.
        if (state.hayNueva) {
          result = Stack(
            clipBehavior: Clip.none,
            children: [
              result,
              Positioned(
                right: 6,
                bottom: 6,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context2, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withValues(alpha: 0.55),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return result;
      },
    );
  }

  /// Navega a la pantalla de notificaciones.
  ///
  /// Antes de navegar limpia el indicador [hayNueva] para detener el pulso.
  /// Al volver, refresca únicamente el contador del badge.
  void _navegarANotificaciones(BuildContext context) {
    context.read<NotificacionBloc>().add(const ResetNuevaNotificacionEvent());
    // Ruta NO restaurable a propósito: aquí se espera el regreso para
    // refrescar el contador, y `restorablePushNamed` no devuelve un Future.
    // Solo se pierde esta pantalla si el sistema recicla el proceso estando
    // en ella; el resto de la pila sí se restaura.
    Navigator.pushNamed(context, 'notificaciones').then((_) {
      if (context.mounted) {
        context.read<NotificacionBloc>().add(const ActualizarContadorEvent());
      }
    });
  }
}
