import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/repository/BannerRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

/// Caso de uso para obtener los banners informativos del usuario.
class GetBannersUseCase {
  final BannerRepository repository;

  GetBannersUseCase(this.repository);

  /// Ejecuta el caso de uso.
  ///
  /// Retorna [Success] con [BannersResponse] o [Error].
  Future<Resource<BannersResponse>> run() async {
    return await repository.getBanners();
  }
}
