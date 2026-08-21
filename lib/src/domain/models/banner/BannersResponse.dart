import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';

/// Respuesta del endpoint `/api/v1/banners`.
///
/// El backend responde `{ success, message, banners: [...] }`. Se conserva
/// [message] porque es el texto que el servidor usa para explicar un fallo
/// lógico con status 200.
class BannersResponse {
  final bool success;
  final String message;
  final List<BannerInfo> banners;

  const BannersResponse({
    required this.success,
    required this.message,
    required this.banners,
  });

  factory BannersResponse.fromJson(Map<String, dynamic> json) =>
      BannersResponse(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        // Una respuesta sin la clave `banners`, o con algo que no es lista, se
        // trata como "no hay banners": la tirilla simplemente no se muestra.
        banners: json['banners'] is List
            ? (json['banners'] as List)
                .whereType<Map<String, dynamic>>()
                .map(BannerInfo.fromJson)
                .toList()
            : <BannerInfo>[],
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'banners': banners.map((b) => b.toJson()).toList(),
      };
}
