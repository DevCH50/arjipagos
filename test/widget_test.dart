/// Archivo principal de tests para ArjiPagos.
///
/// Este archivo importa y ejecuta todos los tests unitarios del proyecto.
/// Para ejecutar todos los tests: flutter test
/// Para ejecutar con coverage: flutter test --coverage
library;

// Tests de modelos
import 'unit/models/user_test.dart' as user_test;
import 'unit/models/alumno_test.dart' as alumno_test;
import 'unit/models/auth_response_test.dart' as auth_response_test;
import 'unit/models/alumno_response_test.dart' as alumno_response_test;

// Tests de use cases
import 'unit/usecases/login_usecase_test.dart' as login_usecase_test;
import 'unit/usecases/get_user_session_usecase_test.dart' as get_user_session_test;
import 'unit/usecases/logout_usecase_test.dart' as logout_usecase_test;
import 'unit/usecases/get_alumnos_usecase_test.dart' as get_alumnos_usecase_test;

// Tests de BLoCs
import 'unit/blocs/login_bloc_test.dart' as login_bloc_test;
import 'unit/blocs/home_bloc_test.dart' as home_bloc_test;

void main() {
  // Modelos
  user_test.main();
  alumno_test.main();
  auth_response_test.main();
  alumno_response_test.main();

  // Use Cases
  login_usecase_test.main();
  get_user_session_test.main();
  logout_usecase_test.main();
  get_alumnos_usecase_test.main();

  // BLoCs
  login_bloc_test.main();
  home_bloc_test.main();
}
