import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cómo se cerró el diálogo de actualización.
///
/// El diálogo **siempre** se cierra devolviendo uno de estos valores. Que la
/// ruta desaparezca con resultado `null` significa entonces una sola cosa: que
/// nadie la cerró, sino que una navegación se la llevó por delante. Es lo que
/// hace el splash al terminar, con un `removeUntil((route) => false)` que borra
/// todas las rutas. `ActualizacionObserver` usa esa señal para reabrirlo.
enum CierreActualizacion {
  /// El usuario lo descartó ("Ahora no" o el botón atrás).
  usuario,

  /// El usuario pidió volver a consultar al servidor.
  reintentar,
}

/// Diálogo que avisa de una actualización pendiente o del mantenimiento.
///
/// Cuando el veredicto bloquea (actualización obligatoria o mantenimiento) el
/// diálogo **no se puede descartar**: ni tocando fuera, ni con el botón atrás
/// de Android, ni con el gesto de retroceso de iOS. Esa es toda la razón de ser
/// de la pantalla.
///
/// El diálogo no toca el BLoC: solo informa de cómo se cerró. Quien traduce eso
/// a eventos es [ActualizacionObserver], que es también quien decide si hay que
/// volver a abrirlo.
class ActualizacionRequeridaDialog extends StatefulWidget {
  final ResultadoActualizacion resultado;

  const ActualizacionRequeridaDialog({super.key, required this.resultado});

  @override
  State<ActualizacionRequeridaDialog> createState() =>
      _ActualizacionRequeridaDialogState();
}

class _ActualizacionRequeridaDialogState
    extends State<ActualizacionRequeridaDialog> {
  /// Aviso de que la tienda no abrió. Se pinta dentro del propio diálogo: no
  /// se puede usar SnackBar (regla del proyecto) ni apilar otro diálogo encima
  /// de uno que bloquea.
  String? _errorTienda;

  ResultadoActualizacion get _resultado => widget.resultado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope<CierreActualizacion>(
      // Siempre `false`: el cierre lo decide `_alIntentarSalir`, que es lo que
      // permite devolver un resultado también cuando se sale con el atrás.
      canPop: false,
      onPopInvokedWithResult: _alIntentarSalir,
      child: AlertDialog(
        icon: Icon(_icono, size: 32, color: colorScheme.primary),
        title: Text(_titulo, textAlign: TextAlign.center),
        content: _contenido(colorScheme),
        actionsAlignment: MainAxisAlignment.center,
        actions: _acciones(),
      ),
    );
  }

  /// Atiende el botón atrás de Android y el gesto de retroceso de iOS.
  ///
  /// Si el aviso bloquea no se hace nada, y el diálogo se queda donde está. Si
  /// es descartable se cierra a mano, para poder devolver el motivo del cierre.
  void _alIntentarSalir(bool seCerro, CierreActualizacion? resultado) {
    if (seCerro || _resultado.bloquea) {
      return;
    }
    Navigator.pop(context, CierreActualizacion.usuario);
  }

  /// Mensaje del backend y, si tocó, el aviso de que la tienda no abrió.
  Widget _contenido(ColorScheme colorScheme) {
    final mensaje = Text(_resultado.mensaje, textAlign: TextAlign.center);

    if (_errorTienda == null) {
      return mensaje;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mensaje,
        const SizedBox(height: 12),
        Text(
          _errorTienda!,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.error),
        ),
      ],
    );
  }

  /// Botones según el veredicto.
  ///
  /// - Obligatoria: solo "Actualizar", y el diálogo sigue en pantalla al volver
  ///   de la tienda, porque la versión instalada sigue siendo la vieja.
  /// - Sugerida: "Ahora no" y "Actualizar", ambos cierran.
  /// - Mantenimiento: "Reintentar", sin enlace a tienda.
  List<Widget> _acciones() {
    if (_resultado.estado == EstadoActualizacion.mantenimiento) {
      return [
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, CierreActualizacion.reintentar),
          child: const Text(AppStrings.actualizacionBotonReintentar),
        ),
      ];
    }

    return [
      if (!_resultado.bloquea)
        TextButton(
          onPressed: () => Navigator.pop(context, CierreActualizacion.usuario),
          child: const Text(AppStrings.actualizacionBotonAhoraNo),
        ),
      // Sin enlace de tienda no se ofrece el botón: vale más un diálogo
      // incompleto que un botón que no lleva a ninguna parte.
      if (_resultado.urlTienda.isNotEmpty)
        FilledButton(
          onPressed: _abrirTienda,
          child: const Text(AppStrings.actualizacionBotonActualizar),
        ),
    ];
  }

  /// Abre la ficha de la tienda fuera de la app.
  Future<void> _abrirTienda() async {
    bool abierta = false;

    try {
      final uri = Uri.parse(_resultado.urlTienda);
      abierta = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // El detalle técnico va al log; al usuario solo el aviso legible.
      AppLogger.error('No se pudo abrir la tienda: $e', tag: 'Version');
    }

    if (!mounted) {
      return;
    }

    if (!abierta) {
      setState(() => _errorTienda = AppStrings.actualizacionErrorAbrirTienda);
      return;
    }

    // Un aviso descartable ya cumplió su función; el obligatorio se queda hasta
    // que el usuario vuelva con la versión nueva instalada.
    if (!_resultado.bloquea) {
      Navigator.pop(context, CierreActualizacion.usuario);
    }
  }

  IconData get _icono {
    switch (_resultado.estado) {
      case EstadoActualizacion.mantenimiento:
        return Icons.build_circle_outlined;
      case EstadoActualizacion.obligatoria:
        return Icons.system_update;
      case EstadoActualizacion.sugerida:
      case EstadoActualizacion.ninguna:
        return Icons.system_update_alt;
    }
  }

  String get _titulo {
    switch (_resultado.estado) {
      case EstadoActualizacion.mantenimiento:
        return AppStrings.actualizacionTituloMantenimiento;
      case EstadoActualizacion.obligatoria:
        return AppStrings.actualizacionTituloObligatoria;
      case EstadoActualizacion.sugerida:
      case EstadoActualizacion.ninguna:
        return AppStrings.actualizacionTituloSugerida;
    }
  }
}
