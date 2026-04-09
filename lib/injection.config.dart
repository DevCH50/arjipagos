// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart'
    as _i260;
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart' as _i64;
import 'package:arjipagos/src/data/dataSource/remote/services/AuthService.dart'
    as _i424;
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart'
    as _i276;
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart'
    as _i303;
import 'package:arjipagos/src/data/dataSource/remote/services/HomeService.dart'
    as _i167;
import 'package:arjipagos/src/data/dataSource/remote/services/NotificacionService.dart'
    as _i955;
import 'package:arjipagos/src/data/dataSource/remote/services/PagoService.dart'
    as _i424;
import 'package:arjipagos/src/di/AppModule.dart' as _i21;
import 'package:arjipagos/src/domain/repository/AuthRepository.dart' as _i1009;
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart' as _i57;
import 'package:arjipagos/src/domain/repository/HomeRepository.dart' as _i123;
import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart'
    as _i775;
import 'package:arjipagos/src/domain/repository/PagoRepository.dart' as _i946;
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart'
    as _i18;
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart' as _i887;
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart'
    as _i869;
import 'package:arjipagos/src/domain/useCases/notificaciones/NotificacionUseCases.dart'
    as _i274;
import 'package:arjipagos/src/domain/useCases/pago/PagoUseCases.dart' as _i604;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.factory<_i64.SharedPref>(() => appModule.sharedPref);
    gh.factory<_i260.SecureStorage>(() => appModule.secureStorage);
    gh.factory<_i424.AuthService>(() => appModule.authService);
    gh.factory<_i1009.AuthRepository>(() => appModule.authRepository);
    gh.factory<_i887.AuthUseCases>(() => appModule.authUseCases);
    gh.factory<_i167.HomeService>(() => appModule.homeService);
    gh.factory<_i123.HomeRepository>(() => appModule.homeRepository);
    gh.factory<_i18.HomeUseCases>(() => appModule.homeUseCases);
    gh.factory<_i276.EdoCtaService>(() => appModule.edoCtaService);
    gh.factory<_i57.EdoCtaRepository>(() => appModule.edoCtaRepository);
    gh.factory<_i869.EdoCtaUseCases>(() => appModule.edoCtaUseCases);
    gh.factory<_i303.FcmService>(() => appModule.fcmService);
    gh.factory<_i955.NotificacionService>(() => appModule.notificacionService);
    gh.factory<_i775.NotificacionRepository>(
      () => appModule.notificacionRepository,
    );
    gh.factory<_i274.NotificacionUseCases>(
      () => appModule.notificacionUseCases,
    );
    gh.factory<_i424.PagoService>(() => appModule.pagoService);
    gh.factory<_i946.PagoRepository>(() => appModule.pagoRepository);
    gh.factory<_i604.PagoUseCases>(() => appModule.pagoUseCases);
    return this;
  }
}

class _$AppModule extends _i21.AppModule {}
