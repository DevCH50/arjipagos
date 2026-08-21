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

  const BannerState({
    this.banners = const [],
    this.isLoading = false,
    this.errorMessage,
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
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      // Igual que en los demás estados del proyecto: el error no se arrastra,
      // se pasa explícitamente en cada emisión o se limpia.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [banners, isLoading, errorMessage];
}
