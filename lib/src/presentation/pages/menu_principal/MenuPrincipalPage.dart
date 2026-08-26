import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/presentation/pages/banners/widgets/banners_strip.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_items_list.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_drawer.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_header.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_badge_button.dart';
import 'package:arjipagos/src/presentation/utils/RutaActualObserver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página del Menú Principal.
///
/// Muestra las opciones principales de la aplicación después del login.
/// Incluye información del usuario y lista de módulos disponibles.
///
/// Detecta cuándo el usuario abrió la app desde una notificación de sistema
/// (background o app terminada) y navega a la pantalla que toque: Notificaciones
/// para el push corriente, y **Pagos Realizados** para el de pago exitoso.
///
/// La navegación vive aquí y no en los BLoCs porque estos cuelgan de la raíz de
/// la app y no tienen `Navigator`. Cada uno deja su `debeNavegar` en el estado y
/// esta página lo recoge.
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
      final notificacionBloc = context.read<NotificacionBloc>();
      if (notificacionBloc.state.debeNavegar) {
        notificacionBloc.add(const ResetDebeNavegarEvent());
        Navigator.of(context).restorablePushNamed('notificaciones');
        return;
      }

      // Lo mismo para el push de pago exitoso, que lleva a Pagos Realizados.
      // Un `return` arriba porque los dos no pueden darse a la vez: el push que
      // abrió la app es uno solo, y cada BLoC ya filtra por `campania`.
      _irAPagosRealizados(context);
    });
  }

  /// Abre Pagos Realizados si hay un push de pago esperando, con dos guardas.
  ///
  /// **No se navega encima de la pasarela de pago.** El push puede llegar con el
  /// usuario todavía en el WebView del banco —el backend lo manda al confirmar
  /// el cobro, no al salir de ahí—, y sacarlo de esa pantalla a media
  /// transacción es lo último que hay que hacer. Es la misma regla que ya sigue
  /// el cerrojo biométrico, y por eso se consulta el mismo `RutaActualObserver`.
  ///
  /// **Tampoco se apila una segunda copia** de la pantalla si ya está arriba:
  /// el usuario acabaría teniendo que darle dos veces al atrás.
  ///
  /// En los dos casos la señal se apaga igual. Lo que **no** se apaga es el
  /// alumno y el folio señalados: siguen en el estado, así que cuando el usuario
  /// entre a Pagos Realizados por su cuenta, la lista se irá igualmente hasta su
  /// pago. Y la recarga ya se hizo cuando llegó el push, así que lo verá al día.
  void _irAPagosRealizados(BuildContext context, [EdoCtaPagadosState? _]) {
    final bloc = context.read<EdoCtaPagadosBloc>();
    if (!bloc.state.debeNavegar) {
      return;
    }
    bloc.add(const EdoCtaPagadosNavegacionAtendidaEvent());

    final String? rutaArriba = rutaActualObserver.rutaActual;
    if (rutaArriba == RutaActualObserver.rutaPagoWebView ||
        rutaArriba == 'edo_cta_pagados') {
      return;
    }
    Navigator.of(context).restorablePushNamed('edo_cta_pagados');
  }

  @override
  Widget build(BuildContext context) {
    // `MultiBlocListener` y no dos `BlocListener` anidados: escuchar dos BLoCs
    // no debe costar un nivel más de anidación.
    return MultiBlocListener(
      listeners: [
        // Caso app en background: el usuario toca la notificación mientras
        // la app ya está corriendo; el BLoC transiciona debeNavegar a true.
        BlocListener<NotificacionBloc, NotificacionState>(
          listenWhen: (prev, curr) => curr.debeNavegar && !prev.debeNavegar,
          listener: (context, state) {
            context.read<NotificacionBloc>().add(const ResetDebeNavegarEvent());
            Navigator.of(context).restorablePushNamed('notificaciones');
          },
        ),
        // Lo mismo para el push de pago exitoso: a Pagos Realizados. La lista ya
        // viene recargada del servidor, porque el pago es de hace segundos.
        BlocListener<EdoCtaPagadosBloc, EdoCtaPagadosState>(
          listenWhen: (prev, curr) => curr.debeNavegar && !prev.debeNavegar,
          listener: _irAPagosRealizados,
        ),
      ],
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
            // Carrusel de avisos. Se encoge a cero cuando no hay contenido,
            // así que el menú se ve igual que antes si no llegan avisos. NO va
            // envuelto en SafeArea: el propio carrusel descuenta el inset con
            // MediaQuery.viewPaddingOf, que es el único valor fiable si un
            // widget padre ya consumió el padding.
            const BannersStrip(),
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

    // "Calificar la app" no navega: abre la ficha de la tienda. Se intercepta
    // antes del chequeo de ruta porque su MenuItem no tiene ninguna.
    if (item.id == kMenuCalificarAppId) {
      _abrirFichaTienda(context);
      return;
    }

    if (item.ruta == null) {
      return;
    }

    Navigator.restorablePushNamed(context, item.ruta!);
  }

  /// Abre Google Play o la App Store en la ficha de ArjiPagos.
  ///
  /// Se usa `openStoreListing` y no la hoja de reseña nativa porque Apple
  /// prohíbe disparar esa hoja desde un botón; además así no se consume la
  /// cuota de invitaciones automáticas del sistema.
  Future<void> _abrirFichaTienda(BuildContext context) async {
    try {
      await locator<ResenaUseCases>().abrirFichaTienda.run();
    } catch (e) {
      AppLogger.warning('No se pudo abrir la ficha de la tienda: $e',
          tag: 'Resena');
      if (context.mounted) {
        _showErrorDialog(context, AppStrings.resenaErrorAbrirTienda);
      }
    }
  }
}
