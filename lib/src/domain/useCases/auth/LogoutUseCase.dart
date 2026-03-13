// En lib/src/domain/useCases/auth/LogoutUseCase.dart

import 'package:arjipagos/src/domain/repository/AuthRepository.dart';

class LogoutUseCase {
  AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<bool> run() => repository.logout();

}
