import 'dart:convert';

import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';

NotificacionResponse notificacionResponseFromJson(String str) =>
    NotificacionResponse.fromJson(json.decode(str));

String notificacionResponseToJson(NotificacionResponse data) =>
    json.encode(data.toJson());

/// Respuesta del endpoint GET /api/v1/notificaciones.
///
/// Estructura del backend:
/// ```json
/// {
///   "data": [ { "id": 9, "title": "...", ... } ],
///   "no_leidas": 9
/// }
/// ```
class NotificacionResponse {
  /// Lista de notificaciones de la página solicitada.
  final List<Notificacion> data;

  /// Cantidad total de notificaciones no leídas del usuario.
  final int noLeidas;

  NotificacionResponse({
    required this.data,
    required this.noLeidas,
  });

  factory NotificacionResponse.fromJson(Map<String, dynamic> json) =>
      NotificacionResponse(
        data: List<Notificacion>.from(
          (json['data'] as List<dynamic>? ?? [])
              .map((item) => Notificacion.fromJson(item as Map<String, dynamic>)),
        ),
        noLeidas: json['no_leidas'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'data': List<dynamic>.from(data.map((n) => n.toJson())),
        'no_leidas': noLeidas,
      };
}
