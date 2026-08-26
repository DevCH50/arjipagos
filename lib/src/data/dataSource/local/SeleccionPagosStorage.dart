import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';

/// Clave de la selección **compartida** que usó la app hasta que los pagos se
/// separaron por emisor fiscal.
///
/// Ya no se lee ni se escribe: se borra la primera vez que arranca esta
/// versión. Guardaba junta la selección de todos los emisores, y repartirla no
/// se puede hacer aquí —haría falta saber el emisor de cada pago, que solo
/// viene con los datos del servidor—. Meterla entera en un emisor pondría
/// pagos ajenos en su carrito, así que se descarta: volver a marcar unos
/// cuantos renglones cuesta menos que un cobro en la cuenta equivocada.
const String kSeleccionPagosKeyLegado = 'edo_cta_pagos_seleccionados';

/// Ciclo bajo el que se agrupan las selecciones sin ciclo.
const int kCicloDesconocido = 0;

/// Persistencia de la selección de pagos **de un emisor fiscal**, con ámbito de
/// ciclo escolar.
///
/// Estructura: `{cicloId: {alumnoId: [pagoId, ...]}}`.
///
/// Hay **una instancia por emisor**, cada una con su propia [claveSeleccion].
/// Es lo que garantiza que las operaciones destructivas —vaciar el carrito,
/// recargar la lista, completar un pago— no salgan del emisor que las provoca.
/// Con la clave compartida que había antes, pagar en un emisor vaciaba el
/// carrito del otro.
class SeleccionPagosStorage {
  final SharedPref _sharedPref;

  /// Clave propia de este emisor. Viene de `ConfiguracionAdquira.claveSeleccion`.
  final String claveSeleccion;

  SeleccionPagosStorage(this._sharedPref, {required this.claveSeleccion});

  /// Carga la selección persistida de este emisor.
  ///
  /// Ante cualquier dato corrupto devuelve un mapa vacío en lugar de propagar
  /// el error: perder la selección es preferible a dejar la pantalla inservible.
  Future<Map<int, Map<int, List<int>>>> cargar() async {
    try {
      final data = await _sharedPref.readMap(claveSeleccion);
      if (data == null || data.isEmpty) {
        return {};
      }

      final Map<int, Map<int, List<int>>> resultado = {};
      data.forEach((claveCiclo, valor) {
        final cicloId = int.tryParse(claveCiclo);
        if (cicloId == null || valor is! Map) {
          return;
        }
        final alumnos = _parsearAlumnos(Map<String, dynamic>.from(valor));
        if (alumnos.isNotEmpty) {
          resultado[cicloId] = alumnos;
        }
      });
      return resultado;
    } catch (e) {
      return {};
    }
  }

  /// Guarda la selección. Los ciclos y alumnos sin pagos no se persisten.
  Future<void> guardar(Map<int, Map<int, List<int>>> seleccion) async {
    final Map<String, dynamic> json = {};
    seleccion.forEach((cicloId, alumnos) {
      final Map<String, dynamic> alumnosJson = {};
      alumnos.forEach((alumnoId, pagos) {
        if (pagos.isNotEmpty) {
          alumnosJson[alumnoId.toString()] = pagos;
        }
      });
      if (alumnosJson.isNotEmpty) {
        json[cicloId.toString()] = alumnosJson;
      }
    });
    await _sharedPref.save(claveSeleccion, json);
  }

  /// Borra la selección compartida que dejó la versión anterior de la app.
  ///
  /// Se llama una sola vez al arrancar. Es idempotente: si la clave ya no
  /// existe, no hace nada. Ver [kSeleccionPagosKeyLegado] para el porqué de
  /// descartarla en vez de repartirla.
  static Future<void> descartarSeleccionCompartidaAntigua(
    SharedPref sharedPref,
  ) async {
    try {
      final existente = await sharedPref.readMap(kSeleccionPagosKeyLegado);
      if (existente == null) {
        return;
      }
      await sharedPref.remove(kSeleccionPagosKeyLegado);
    } catch (_) {
      // Que no se pueda limpiar no debe impedir que la app arranque: la clave
      // vieja ya no la lee nadie, solo ocupa sitio.
    }
  }

  /// Convierte `{"alumnoId": [pagoId, ...]}` a `{alumnoId: [pagoId, ...]}`,
  /// descartando entradas con claves o valores inesperados.
  Map<int, List<int>> _parsearAlumnos(Map<String, dynamic> data) {
    final Map<int, List<int>> resultado = {};
    data.forEach((clave, valor) {
      final alumnoId = int.tryParse(clave);
      if (alumnoId == null || valor is! List) {
        return;
      }
      final pagos = valor.whereType<int>().toList();
      if (pagos.isNotEmpty) {
        resultado[alumnoId] = pagos;
      }
    });
    return resultado;
  }
}
