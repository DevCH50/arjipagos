import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pie del drawer con enlace al Aviso de Privacidad y versión de la app.
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
