import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/repository/AuthRepository.dart';

class GetUserSessionUseCase {
  final AuthRepository authRepository;

  GetUserSessionUseCase(this.authRepository);

  Future<AuthResponse?> run() => authRepository.getUserSession();

}
