import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/presentation/pages/biometria/widgets/InterruptorBiometria.dart';
import 'package:arjipagos/src/presentation/widgets/IconoDeMenu.dart';
import 'package:flutter/material.dart';

/// Pantalla de Configuraciones.
///
/// Reúne los ajustes de la app con el mismo aspecto que el Menú Principal:
/// opciones a todo lo ancho, con [IconoDeMenu] y separadas por divisores.
/// Se abre desde el drawer.
///
/// Hoy tiene dos opciones:
/// - **Bloqueo al abrir la app** (Face ID / huella), que antes vivía en el
///   drawer. El `BiometriaBloc` cuelga de la raíz, así que el interruptor
///   funciona igual aquí, y los avisos que emite los pinta `CerrojoBiometrico`
///   sobre cualquier pantalla.
/// - **Calificar la app**, que antes era una opción del Menú Principal.
class ConfiguracionesPage extends StatelessWidget {
  const ConfiguracionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.configuracionesTitulo)),
      body: ListView(
        // Edge-to-edge (Android 15+): la lista pasa por debajo de la barra de
        // navegación del sistema; se suma su alto, como en `MenuItemsList`.
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          8 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: const [
          InterruptorBiometria(),
          Divider(height: 1),
          _OpcionCalificarApp(),
        ],
      ),
    );
  }
}

/// Opción que abre la ficha de ArjiPagos en Google Play o la App Store.
///
/// Se usa `openStoreListing` y no la hoja de reseña nativa porque Apple
/// prohíbe disparar esa hoja desde un botón; además así no se consume la
/// cuota de invitaciones automáticas del sistema.
class _OpcionCalificarApp extends StatelessWidget {
  const _OpcionCalificarApp();

  Future<void> _abrirFichaTienda(BuildContext context) async {
    try {
      await locator<ResenaUseCases>().abrirFichaTienda.run();
    } catch (e) {
      AppLogger.warning(
        'No se pudo abrir la ficha de la tienda: $e',
        tag: 'Resena',
      );
      if (context.mounted) {
        _mostrarError(context);
      }
    }
  }

  /// Avisa de que la tienda no se pudo abrir. Sin el detalle técnico.
  void _mostrarError(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: const Text(AppStrings.resenaErrorAbrirTienda),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: const IconoDeMenu(icono: Icons.star_outline),
      title: Text(
        AppStrings.configuracionesCalificarApp,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      // Sale de la app, así que se marca con el icono de enlace externo y no
      // con el chevron de "entrar a otra pantalla".
      trailing: Icon(
        Icons.open_in_new,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => _abrirFichaTienda(context),
    );
  }
}
