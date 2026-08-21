import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Interfaz del repositorio de banners informativos.
abstract class BannerRepository {
  /// Obtiene los banners del usuario de la sesión.
  Future<Resource<BannersResponse>> getBanners();
}
