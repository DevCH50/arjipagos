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
                          icon: Icons.person,
                          label: 'Nombre',
                          value: user.nombre,
                        ),
                        CopyableListTile(
                          icon: Icons.person,
                          label: 'Apellido Paterno',
                          value: user.apPaterno,
                        ),
                        CopyableListTile(
                          icon: Icons.person,
                          label: 'Apellido Materno',
                          value: user.apMaterno,
                        ),
                        CopyableListTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        if (user.emails.isNotEmpty)
                          CopyableListTile(
                            icon: Icons.alternate_email,
                            label: 'Otros emails',
                            value: user.emails,
                          ),
                        CopyableListTile(
                          icon: Icons.phone_android,
                          label: 'Celulares',
                          value: user.celulares.isNotEmpty
                              ? user.celulares
                              : 'Sin registrar',
                        ),
                        if (user.telefonos.isNotEmpty)
                          CopyableListTile(
                            icon: Icons.phone,
                            label: 'Teléfonos',
                            value: user.telefonos,
                          ),
                      ],
                      const Divider(),
                      // Sección: Familia y alumnos
                      const SectionHeader(title: 'Familia'),
                      CopyableListTile(
                        icon: Icons.family_restroom,
                        label: 'Familia',
                        value: state.familia ?? 'Sin información',
                      ),
                      CopyableListTile(
                        icon: Icons.school_outlined,
                        label: 'Alumnos',
                        value: state.resumenAlumnos,
                      ),
                      const Divider(),
                      // Sección: Versiones
                      const SectionHeader(title: 'Versiones'),
                      CopyableListTile(
                        icon: Icons.phone_iphone,
                        label: 'App',
                        value: state.appVersion ?? 'Desconocida',
                      ),
                      CopyableListTile(
                        icon: Icons.cloud_outlined,
                        label: 'API',
                        value: state.apiVersion ?? 'Desconocida',
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
