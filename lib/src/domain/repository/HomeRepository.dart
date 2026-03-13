import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';

abstract class HomeRepository {
  Future<Resource<AlumnoResponse>> getAlumnos();
}
