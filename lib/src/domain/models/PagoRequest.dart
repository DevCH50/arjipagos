/// Modelo que representa los datos necesarios para procesar un pago.
///
/// Contiene todos los parámetros requeridos por Adquira México.
class PagoRequest {
  final String token;
  final int userId;
  final double importe;
  final String urlRetorno;
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
    this.idExpress = '928',
    this.financiamiento = '0',
    this.moneda = 'MXN',
    this.tipo = '1',
    this.tipoPago = '1',
    this.plazos = '',
    this.mediosPago = '111000',
    required this.referencia,
  });

  /// Convierte el request a un Map para enviar como form-data o JSON.
  Map<String, String> toMap() {
    return {
      'user_id': userId.toString(),
      'importe': importe.toStringAsFixed(2),
      'urlretorno': urlRetorno,
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
    return estadosCuentaIds.join('D');
  }
}
