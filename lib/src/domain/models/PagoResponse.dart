import 'dart:convert';

PagoResponse pagoResponseFromJson(String str) => PagoResponse.fromJson(json.decode(str));

String pagoResponseToJson(PagoResponse data) => json.encode(data.toJson());

/// Respuesta del servidor después de procesar un pago.
class PagoResponse {
    bool success;
    String message;

    PagoResponse({
        required this.success,
        required this.message,
    });

    factory PagoResponse.fromJson(Map<String, dynamic> json) => PagoResponse(
        success: json['success'] ?? false,
        message: json['message']?.toString() ?? '',
    );

    Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
    };
}
