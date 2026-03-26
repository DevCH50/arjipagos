import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/copyable_list_tile.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/drawer_header.dart' show UserDrawerHeader;
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drawer con información detallada del usuario.
///
/// Muestra datos personales, familia, alumnos y versiones.
/// Todos los campos son copiables al portapapeles.
/// Compatible con tema claro y oscuro, Android e iOS.
class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

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
                nombre: state.nombreUsuario ?? 'Usuario',
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
                      const SectionHeader(title: 'Datos personales'),
                      if (user != null) ...[
                        CopyableListTile(
                          icon: Icons.badge_outlined,
                          label: 'ID',
                          value: user.id.toString(),
                        ),
                        CopyableListTile(
                          icon: Icons.person_outline,
                          label: 'Usuario',
                          value: user.username,
                        ),
                        CopyableListTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        CopyableListTile(
                          icon: Icons.phone_android,
                          label: 'Celular',
                          value: user.celulares.isNotEmpty
                              ? user.celulares
                              : 'Sin registrar',
                        ),
                      ],
                      const Divider(),
                      // Sección: Cuenta
                      const SectionHeader(title: 'Mi cuenta'),
                      ListTile(
                        leading: Icon(
                          Icons.lock_reset,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Cambiar Contraseña'),
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
                    ],
                  ),
                ),
              ),
              // Pie con información
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Toca cualquier campo para copiar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
