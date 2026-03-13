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
      return Error<AlumnoResponse>('Error al obtener Alumnos: $e');
    }
  }
}
