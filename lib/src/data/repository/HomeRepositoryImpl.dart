import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/HomeService.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/repository/HomeRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeService homeService;

  HomeRepositoryImpl(this.homeService);

  @override
  Future<Resource<AlumnoResponse>> getAlumnos() async {
    try {
      final result = await homeService.getAlumnos();
      return result;
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error al obtener alumnos: $e', tag: 'Home');
      return Error<AlumnoResponse>(mensajeErrorRed(e));
    }
  }
}
