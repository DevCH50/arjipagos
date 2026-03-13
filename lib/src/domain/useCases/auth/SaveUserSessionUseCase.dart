import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/repository/AuthRepository.dart';

class SaveUserSessionUseCase {

  final AuthRepository authRepository;

  SaveUserSessionUseCase(this.authRepository);

  Future<void> run(AuthResponse authResponse) => authRepository.saveUserSession(authResponse);

}
