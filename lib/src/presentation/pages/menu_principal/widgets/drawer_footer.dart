import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Pie del drawer con la versión de la app e indicación de copia.
///
/// Obtiene la versión en tiempo de ejecución con [PackageInfo] y detecta
/// la plataforma (Android / iOS) con [Platform].
/// Compatible con tema claro y oscuro.
class DrawerFooter extends StatefulWidget {
  const DrawerFooter({super.key});

  @override
  State<DrawerFooter> createState() => _DrawerFooterState();
}

class _DrawerFooterState extends State<DrawerFooter> {
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
            // Versión de la app con etiqueta de plataforma
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
