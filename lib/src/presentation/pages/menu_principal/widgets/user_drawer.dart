import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/CloseSession.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/copyable_list_tile.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/drawer_footer.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/drawer_header.dart' show UserDrawerHeader;
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../main.dart';

/// Drawer con información detallada del usuario.
///
/// Muestra datos personales, familia, alumnos y versiones.
/// Todos los campos son copiables al portapapeles.
/// Compatible con tema claro y oscuro, Android e iOS.
class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  /// Muestra el diálogo de confirmación y ejecuta el cierre de sesión.
  ///
  /// El logout se realiza de forma DIRECTA y awaitable usando el locator,
  /// no a través del bloc, para garantizar que la sesión esté limpia
  /// ANTES de que el navigator cambie de ruta.
  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    // Mostrar el diálogo CON el drawer aún abierto (contexto válido).
    final shouldLogout = await CloseSession.show(
      context: context,
      title: AppStrings.logoutTitle,
      message: AppStrings.logoutMessage,
      icon: Icons.logout,
      iconColor: Colors.orange,
      confirmText: AppStrings.logoutConfirm,
      cancelText: AppStrings.cancel,
      confirmButtonColor: Colors.red,
      confirmTextColor: Colors.white,
    );

    if (!shouldLogout) {
      return;
    }

    // Mostrar preloader mientras se cierra la sesión.
    _mostrarCargando(navigator);

    final authUseCases = locator<AuthUseCases>();
    final fcmService = locator<FcmService>();

    // Obtener sesión ANTES de limpiarla (el token se necesita para el DELETE de FCM).
    final authResponse = await authUseCases.getUserSession.run();

    // Eliminar token FCM del backend (best-effort, no bloquea el logout).
    if (authResponse != null) {
      fcmService.obtenerToken().then((fcmToken) {
        if (fcmToken != null) {
          fcmService.eliminarToken(
            authToken: authResponse.accessToken,
            fcmToken: fcmToken,
          );
        }
      });
    }

    // Limpiar sesión local (AWAITED — crítico antes de navegar).
    await authUseCases.logout.run();

    // Navegar usando el NavigatorState pre-capturado (el contexto del drawer
    // ya no es válido después del await, pero NavigatorState sí lo es).
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyApp()),
      (route) => false,
    );
  }

  /// Muestra un diálogo de carga animado mientras se procesa el cierre de sesión.
  ///
  /// Usa [NavigatorState] en lugar de [BuildContext] para que sea seguro
  /// llamarlo después de un `await`.
  void _mostrarCargando(NavigatorState navigator) {
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const _LogoutLoadingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: BlocBuilder<MenuPrincipalBloc, MenuPrincipalState>(
        builder: (context, state) {
          final user = state.user;

          return Column(
            children: [
              // Header del drawer (incluye SafeArea top)
              UserDrawerHeader(
                nombre: state.nombreUsuario ?? AppStrings.loginUsername,
                email: state.emailUsuario,
              ),
              // Lista de datos del usuario
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Sección: Datos personales
                      const SectionHeader(title: AppStrings.drawerDatosPersonales),
                      if (user != null) ...[
                        CopyableListTile(
                          icon: Icons.badge_outlined,
                          label: AppStrings.drawerIdLabel,
                          value: user.id.toString(),
                        ),
                        CopyableListTile(
                          icon: Icons.person_outline,
                          label: AppStrings.loginUsername,
                          value: user.username,
                        ),
                        CopyableListTile(
                          icon: Icons.email_outlined,
                          label: AppStrings.drawerEmail,
                          value: user.email,
                        ),
                        CopyableListTile(
                          icon: Icons.phone_android,
                          label: AppStrings.drawerCelular,
                          value: user.celulares.isNotEmpty
                              ? user.celulares
                              : AppStrings.drawerSinRegistrar,
                        ),
                        CopyableListTile(
                          icon: Icons.family_restroom,
                          label: AppStrings.drawerFamilia,
                          value: state.familia?.isNotEmpty == true
                              ? state.familia!
                              : AppStrings.drawerSinRegistrar,
                        ),
                      ],
                      const Divider(),
                      // Sección: Cuenta
                      const SectionHeader(title: AppStrings.drawerMiCuenta),
                      ListTile(
                        leading: Icon(
                          Icons.lock_reset,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text(AppStrings.menuCambiarContrasena),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onTap: () {
                          // Cerrar el drawer antes de navegar
                          Navigator.pop(context);
                          Navigator.pushNamed(context, 'cambiar_contrasena');
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          AppStrings.logoutTitle,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Pie con Aviso de Privacidad, versión e indicación de copia
              const DrawerFooter(),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// DIÁLOGO DE CARGA DURANTE EL LOGOUT
// ============================================================================

/// Diálogo animado que se muestra mientras se procesa el cierre de sesión.
///
/// No puede ser descartado por el usuario. Se elimina automáticamente
/// cuando el navigator ejecuta [pushAndRemoveUntil].
class _LogoutLoadingDialog extends StatefulWidget {
  const _LogoutLoadingDialog();

  @override
  State<_LogoutLoadingDialog> createState() => _LogoutLoadingDialogState();
}

class _LogoutLoadingDialogState extends State<_LogoutLoadingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono animado
            FadeTransition(
              opacity: _fadeAnim,
              child: Icon(
                Icons.logout,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            // Spinner
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            // Texto
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                AppStrings.menuCerrando,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
