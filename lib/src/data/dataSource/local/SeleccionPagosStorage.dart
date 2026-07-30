import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';

/// Clave única donde se persiste la selección de pagos.
///
/// Antes estaba declarada por duplicado en `EdoCtaListBloc` y `CarritoBloc`.
const String kSeleccionPagosKey = 'edo_cta_pagos_seleccionados';

/// Ciclo bajo el que se agrupan las selecciones migradas del formato anterior,
/// que no guardaba ciclo alguno.
const int kCicloDesconocido = 0;

/// Persistencia de la selección de pagos, con ámbito de ciclo escolar.
///
/// Estructura: `{cicloId: {alumnoId: [pagoId, ...]}}`.
///
/// Tanto Estados de Cuenta como el Carrito leen y escriben la misma clave, por
/// eso la (de)serialización vive aquí y no duplicada en cada BLoC.
class SeleccionPagosStorage {
  final SharedPref _sharedPref;

  SeleccionPagosStorage(this._sharedPref);

  /// Carga la selección persistida.
  ///
  /// Migra de forma transparente el formato anterior (`{alumnoId: [pagoId]}`,
  /// sin ciclo) agrupándolo bajo [kCicloDesconocido], para que un carrito
  /// guardado con una versión previa de la app no se pierda al actualizar.
  ///
  /// Ante cualquier dato corrupto devuelve un mapa vacío en lugar de propagar
  /// el error: perder la selección es preferible a dejar la pantalla inservible.
  Future<Map<int, Map<int, List<int>>>> cargar() async {
    try {
      final data = await _sharedPref.readMap(kSeleccionPagosKey);
      if (data == null || data.isEmpty) {
        return {};
      }

      // Formato anterior: los valores son listas de IDs en vez de mapas.
      final esFormatoPlano = data.values.every((v) => v is List);
      if (esFormatoPlano) {
        final migrado = _parsearAlumnos(data);
        return migrado.isEmpty ? {} : {kCicloDesconocido: migrado};
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
    await _sharedPref.save(kSeleccionPagosKey, json);
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
