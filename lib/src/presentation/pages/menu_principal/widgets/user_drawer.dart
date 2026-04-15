import 'dart:io';

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/CloseSession.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/copyable_list_tile.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/drawer_header.dart' show UserDrawerHeader;
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
              const _DrawerFooter(),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// PIE DEL DRAWER — AVISO DE PRIVACIDAD + VERSIÓN
// ============================================================================

/// Pie del drawer con enlace al Aviso de Privacidad y versión de la app.
///
/// Obtiene la versión en tiempo de ejecución con [PackageInfo] y detecta
/// la plataforma (Android / iOS) con [Platform].
class _DrawerFooter extends StatefulWidget {
  const _DrawerFooter();

  @override
  State<_DrawerFooter> createState() => _DrawerFooterState();
}

class _DrawerFooterState extends State<_DrawerFooter> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  /// Carga la versión de la app desde [PackageInfo].
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  /// Abre el Aviso de Privacidad en el navegador externo.
  Future<void> _abrirAvisoPrivacidad() async {
    final uri = Uri.parse(Endpoints.avisodePrivacidad);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.drawerAvisoPrivacidadError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformLabel = Platform.isIOS
        ? AppStrings.drawerVersionIos
        : AppStrings.drawerVersionAndroid;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Aviso de Privacidad — enlace
            InkWell(
              onTap: _abrirAvisoPrivacidad,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  AppStrings.drawerAvisoPrivacidad,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Versión de la app
            if (_version != null)
              Text(
                'v$_version · $platformLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            // Indicación de copia
            Text(
              AppStrings.menuTocaCualquierCampo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
