import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Drawer principal de la aplicación que muestra información del usuario,
/// versiones de la app/API y opción de cerrar sesión.
///
/// Compatible con tema claro y oscuro.
class HomeDrawer extends StatelessWidget {
  final AuthUseCases authUseCases;
  final VoidCallback onLogout;

  const HomeDrawer({
    super.key,
    required this.authUseCases,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: FutureBuilder<AuthResponse?>(
        future: authUseCases.getUserSession.run(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final authResponse = snapshot.data;
          final user = authResponse?.user;

          return Column(
            children: [
              // Header del Drawer con información del usuario
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface,
                  child: user?.pathImageProfile != null &&
                          user!.pathImageProfile.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.pathImageProfile,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.person, size: 40, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Icon(Icons.person, size: 40, color: theme.colorScheme.onSurfaceVariant),
                ),
                accountName: Text(
                  user?.fullName ?? 'Usuario',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),

              // Contenido del Drawer
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Sección de información
                    const _SectionHeader(title: 'Información'),

                    // App Version
                    ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: const Text('App Version'),
                      subtitle: Text(authResponse?.appVersion ?? 'N/A'),
                    ),

                    // API Version
                    ListTile(
                      leading: const Icon(Icons.cloud),
                      title: const Text('API Version'),
                      subtitle: Text(authResponse?.apiVersion ?? 'N/A'),
                    ),

                    const Divider(),

                    // Información adicional del usuario
                    if (user != null) ...[
                      const _SectionHeader(title: 'Cuenta'),

                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('CURP'),
                        subtitle: Text(user.curp.isNotEmpty ? user.curp : 'N/A'),
                      ),

                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Usuario'),
                        subtitle: Text(user.username),
                      ),

                      const Divider(),
                    ],
                  ],
                ),
              ),

              // Botón de cerrar sesión al final
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Cerrar el drawer
                        onLogout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget para encabezados de sección en el drawer.
/// Compatible con tema claro y oscuro.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
