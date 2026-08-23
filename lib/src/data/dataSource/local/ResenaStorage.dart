import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/domain/models/resena/EstadoResena.dart';

/// Fecha del primer pago exitoso registrado. Ancla de la antigüedad mínima.
const String kResenaPrimerUsoKey = 'resena_primer_uso';

/// Pagos exitosos acumulados desde la instalación.
const String kResenaPagosExitososKey = 'resena_pagos_exitosos';

/// Fecha de la última invitación mostrada.
const String kResenaUltimaInvitacionKey = 'resena_ultima_invitacion';

/// Fechas de las invitaciones del último año, en ISO 8601.
///
/// Se guarda la lista completa y no un simple contador porque el tope de Apple
/// es deslizante (3 en 365 días): con un contador habría que decidir cuándo
/// reiniciarlo, y cualquier corte fijo se desincroniza con el del sistema.
const String kResenaHistorialKey = 'resena_historial';

/// Persistencia de la política de invitaciones a calificar la app.
///
/// Va sobre [SharedPref] como el resto de almacenes locales. Ante datos
/// corruptos devuelve el estado vacío en vez de propagar el error: como mucho
/// se retrasa una invitación, que es preferible a romper la pantalla de pago
/// desde la que se consulta.
class ResenaStorage {
  final SharedPref _sharedPref;

  ResenaStorage(this._sharedPref);

  /// Ventana deslizante del tope anual.
  static const Duration ventanaAnual = Duration(days: 365);

  /// Lee el estado persistido.
  Future<EstadoResena> cargar({DateTime? ahora}) async {
    try {
      final momento = ahora ?? DateTime.now();
      final primerUso = _aFecha(await _sharedPref.readString(kResenaPrimerUsoKey));
      final pagos = await _sharedPref.read(kResenaPagosExitososKey);
      final ultima =
          _aFecha(await _sharedPref.readString(kResenaUltimaInvitacionKey));
      final historial = await _leerHistorial();

      final recientes = historial
          .where((f) => momento.difference(f) < ventanaAnual)
          .length;

      return EstadoResena(
        primerUso: primerUso,
        pagosExitosos: pagos is int ? pagos : 0,
        ultimaInvitacion: ultima,
        invitacionesUltimoAnio: recientes,
      );
    } catch (e) {
      return EstadoResena.vacio;
    }
  }

  /// Suma un pago exitoso y, si es el primero, fija la fecha de primer uso.
  Future<void> registrarPagoExitoso({DateTime? ahora}) async {
    final momento = ahora ?? DateTime.now();

    if (await _sharedPref.readString(kResenaPrimerUsoKey) == null) {
      await _sharedPref.save(kResenaPrimerUsoKey, momento.toIso8601String());
    }

    final actual = await _sharedPref.read(kResenaPagosExitososKey);
    final total = (actual is int ? actual : 0) + 1;
    await _sharedPref.save(kResenaPagosExitososKey, total);
  }

  /// Anota una invitación mostrada, podando las que ya salieron de la ventana.
  Future<void> registrarInvitacion({DateTime? ahora}) async {
    final momento = ahora ?? DateTime.now();
    await _sharedPref.save(
        kResenaUltimaInvitacionKey, momento.toIso8601String());

    final historial = await _leerHistorial()
      ..removeWhere((f) => momento.difference(f) >= ventanaAnual);
    historial.add(momento);

    await _sharedPref.save(
      kResenaHistorialKey,
      historial.map((f) => f.toIso8601String()).toList(),
    );
  }

  /// Lee el historial descartando en silencio las entradas ilegibles.
  Future<List<DateTime>> _leerHistorial() async {
    final crudo = await _sharedPref.read(kResenaHistorialKey);
    if (crudo is! List) {
      return <DateTime>[];
    }
    return crudo
        .map((e) => _aFecha(e?.toString()))
        .whereType<DateTime>()
        .toList();
  }

  /// Convierte una fecha ISO, o `null` si viene vacía o mal formada.
  static DateTime? _aFecha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return null;
    }
    return DateTime.tryParse(valor);
  }
}
