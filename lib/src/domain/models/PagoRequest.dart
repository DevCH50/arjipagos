import 'package:arjipagos/src/core/constants/app_constants.dart';

/// Modelo que representa los datos necesarios para procesar un pago.
///
/// Contiene todos los parámetros requeridos por Adquira México.
///
/// **Ningún parámetro de comercio tiene valor por defecto, y es deliberado.**
/// Hasta que los pagos se partieron por emisor fiscal, esta clase traía
/// cableados los del emisor 1 (`idExpress: '928'`, `mediosPago: '111000'`…).
/// Con dos contratos y dos cuentas bancarias, un default es una trampa: quien
/// construyera un `PagoRequest` sin pensar cobraría en la cuenta del emisor 1
/// sin que nada fallara ni avisara. Ahora hay que decir explícitamente de qué
/// contrato es, y lo normal es tomarlos de `ConfiguracionAdquira.para(...)`.
class PagoRequest {
  final String token;
  final int userId;
  final double importe;
  final String urlRetorno;

  /// Emisor fiscal cuyo contrato se está usando: **1** desde "Pagos
  /// Pendientes" y **2** desde "Otros pagos".
  ///
  /// Viaja en el `toMap()` como `emisorfiscal_id`. Adquira sigue identificando
  /// el comercio por [idExpress] —no por este campo—, pero mandarlo permite
  /// saber de qué contrato salió cada cobro sin tener que deducirlo del
  /// `idexpress`, que hoy es el mismo en los dos emisores porque el contrato 2
  /// todavía va con datos prestados (ver `ConfiguracionAdquira.ef2`).
  final int emisorFiscalId;

  final String idExpress;
  final String financiamiento;
  final String moneda;
  final String tipo;
  final String tipoPago;
  final String plazos;
  final String mediosPago;
  final String referencia;

  const PagoRequest({
    required this.token,
    required this.userId,
    required this.importe,
    required this.urlRetorno,
    required this.emisorFiscalId,
    required this.idExpress,
    required this.financiamiento,
    required this.moneda,
    required this.tipo,
    required this.tipoPago,
    required this.plazos,
    required this.mediosPago,
    required this.referencia,
  });

  /// Convierte el request a un Map para enviar como form-data o JSON.
  Map<String, String> toMap() {
    return {
      'user_id': userId.toString(),
      'importe': importe.toStringAsFixed(2),
      'urlretorno': urlRetorno,
      // 1 desde "Pagos Pendientes", 2 desde "Otros pagos". No se deriva del
      // `idexpress`: mientras el contrato 2 use los datos prestados del 1, los
      // dos mandan el mismo, y este campo es lo único que los distingue.
      'emisorfiscal_id': emisorFiscalId.toString(),
      'idexpress': idExpress,
      'financiamiento': financiamiento,
      'moneda': moneda,
      'tipo': tipo,
      'tipoPago': tipoPago,
      'plazos': plazos,
      'mediospago': mediosPago,
      'referencia': referencia,
    };
  }

  /// Genera la referencia a partir de una lista de IDs de estados de cuenta.
  static String generarReferencia(List<int> estadosCuentaIds) {
    return AppConstants.generarReferencia(estadosCuentaIds);
  }
}
