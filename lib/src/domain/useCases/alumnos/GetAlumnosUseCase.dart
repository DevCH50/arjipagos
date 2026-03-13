import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/repository/HomeRepository.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

class GetAlumnosUseCase {
  final HomeRepository repository;

  GetAlumnosUseCase(this.repository);

  Future<Resource<AlumnoResponse>> run() async {
    return await repository.getAlumnos();
  }
}
