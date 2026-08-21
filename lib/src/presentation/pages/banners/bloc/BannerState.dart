import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:equatable/equatable.dart';

/// Estado del BLoC de banners.
class BannerState extends Equatable {
  /// Banners listos para pintar en la tirilla.
  final List<BannerInfo> banners;

  /// Indica si la consulta está en curso.
  final bool isLoading;

  /// Mensaje de error, si la consulta falló.
  final String? errorMessage;

  /// Id del banner que hay que abrir en cuanto llegue, o `null`.
  ///
  /// Lo pone el toque en la notificación de un aviso nuevo. La pantalla lo
  /// atiende y avisa de vuelta para limpiarlo; si se quedara puesto, cualquier
  /// reconstrucción posterior reabriría el modal.
  final String? bannerIdAAbrir;

  const BannerState({
    this.banners = const [],
    this.isLoading = false,
    this.errorMessage,
    this.bannerIdAAbrir,
  });

  /// Estado inicial vacío.
  factory BannerState.initial() => const BannerState();

  /// Hay algo que mostrar en la tirilla.
  ///
  /// Un banner sin imagen no se pinta, así que la tirilla se considera vacía
  /// si ninguno tiene portada.
  bool get tieneBanners => banners.any((b) => b.tieneImagen);

  BannerState copyWith({
    List<BannerInfo>? banners,
    bool? isLoading,
    String? errorMessage,
    String? bannerIdAAbrir,
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      // Igual que en los demás estados del proyecto: el error no se arrastra,
      // se pasa explícitamente en cada emisión o se limpia.
      errorMessage: errorMessage,
      // La petición de apertura sí se arrastra: entre que llega el push y que
      // termina la recarga hay varias emisiones, y perderla por el camino
      // dejaría el modal sin abrir.
      bannerIdAAbrir: bannerIdAAbrir ?? this.bannerIdAAbrir,
    );
  }

  /// Copia soltando la petición de apertura, que `copyWith` conserva.
  BannerState sinBannerAAbrir() => BannerState(
        banners: banners,
        isLoading: isLoading,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [banners, isLoading, errorMessage, bannerIdAAbrir];
}
