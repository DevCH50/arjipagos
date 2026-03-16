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

// Tests de widgets comunes
import 'widgets/common/primary_elevated_button_test.dart' as primary_elevated_button_test;
import 'widgets/common/glass_container_test.dart' as glass_container_test;
import 'widgets/common/default_text_field_test.dart' as default_text_field_test;

// Tests de widgets de EdoCta
import 'widgets/edo_cta/estado_pago_chip_test.dart' as estado_pago_chip_test;
import 'widgets/edo_cta/loading_widget_test.dart' as loading_widget_test;

// Tests de widgets de Carrito
import 'widgets/carrito/carrito_empty_widget_test.dart' as carrito_empty_widget_test;

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

  // Widgets comunes
  primary_elevated_button_test.main();
  glass_container_test.main();
  default_text_field_test.main();

  // Widgets de EdoCta
  estado_pago_chip_test.main();
  loading_widget_test.main();

  // Widgets de Carrito
  carrito_empty_widget_test.main();
}
