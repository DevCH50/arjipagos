import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/BannerService.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/repository/BannerRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Implementación del repositorio de banners.
///
/// Delega las operaciones al servicio HTTP [BannerService].
class BannerRepositoryImpl implements BannerRepository {
  final BannerService bannerService;

  BannerRepositoryImpl(this.bannerService);

  @override
  Future<Resource<BannersResponse>> getBanners() async {
    try {
      final result = await bannerService.getBanners();
      return result;
    } catch (e) {
      // El mensaje que llega a la pantalla nunca es la excepción cruda.
      AppLogger.error('Error al obtener banners: $e', tag: 'Banners');
      return Error<BannersResponse>(mensajeErrorRed(e));
    }
  }
}
