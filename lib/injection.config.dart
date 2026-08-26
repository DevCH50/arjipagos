// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arjipagos/src/data/dataSource/local/AutenticadorBiometrico.dart'
    as _i1069;
import 'package:arjipagos/src/data/dataSource/local/BiometriaStorage.dart'
    as _i241;
import 'package:arjipagos/src/data/dataSource/local/ResenaNativa.dart' as _i667;
import 'package:arjipagos/src/data/dataSource/local/ResenaStorage.dart'
    as _i518;
import 'package:arjipagos/src/data/dataSource/local/SecureStorage.dart'
    as _i260;
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart' as _i64;
import 'package:arjipagos/src/data/dataSource/local/TicketArchivoStorage.dart'
    as _i543;
import 'package:arjipagos/src/data/dataSource/remote/services/AuthService.dart'
    as _i424;
import 'package:arjipagos/src/data/dataSource/remote/services/BannerService.dart'
    as _i299;
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaPagadosService.dart'
    as _i831;
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart'
    as _i276;
import 'package:arjipagos/src/data/dataSource/remote/services/FacturaService.dart'
    as _i908;
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart'
    as _i303;
import 'package:arjipagos/src/data/dataSource/remote/services/HomeService.dart'
    as _i167;
import 'package:arjipagos/src/data/dataSource/remote/services/NotificacionService.dart'
    as _i955;
import 'package:arjipagos/src/data/dataSource/remote/services/TicketService.dart'
    as _i965;
import 'package:arjipagos/src/data/dataSource/remote/services/VersionService.dart'
    as _i7;
import 'package:arjipagos/src/di/AppModule.dart' as _i21;
import 'package:arjipagos/src/di/RegistroEmisores.dart' as _i844;
import 'package:arjipagos/src/domain/repository/AuthRepository.dart' as _i1009;
import 'package:arjipagos/src/domain/repository/BannerRepository.dart' as _i374;
import 'package:arjipagos/src/domain/repository/BiometriaRepository.dart'
    as _i510;
import 'package:arjipagos/src/domain/repository/EdoCtaPagadosRepository.dart'
    as _i645;
import 'package:arjipagos/src/domain/repository/EdoCtaRepository.dart' as _i57;
import 'package:arjipagos/src/domain/repository/FacturaRepository.dart'
    as _i1073;
import 'package:arjipagos/src/domain/repository/HomeRepository.dart' as _i123;
import 'package:arjipagos/src/domain/repository/NotificacionRepository.dart'
    as _i775;
import 'package:arjipagos/src/domain/repository/ResenaRepository.dart' as _i434;
import 'package:arjipagos/src/domain/repository/TicketRepository.dart' as _i522;
import 'package:arjipagos/src/domain/repository/VersionRepository.dart'
    as _i943;
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart'
    as _i18;
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart' as _i887;
import 'package:arjipagos/src/domain/useCases/banners/BannerUseCases.dart'
    as _i557;
import 'package:arjipagos/src/domain/useCases/biometria/BiometriaUseCases.dart'
    as _i275;
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaPagadosUseCases.dart'
    as _i1053;
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart'
    as _i869;
import 'package:arjipagos/src/domain/useCases/facturas/FacturaUseCases.dart'
    as _i504;
import 'package:arjipagos/src/domain/useCases/notificaciones/NotificacionUseCases.dart'
    as _i274;
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart'
    as _i131;
import 'package:arjipagos/src/domain/useCases/ticket/TicketUseCases.dart'
    as _i60;
import 'package:arjipagos/src/domain/useCases/version/VersionUseCases.dart'
    as _i922;
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
    gh.factory<_i831.EdoCtaPagadosService>(
      () => appModule.edoCtaPagadosService,
    );
    gh.factory<_i645.EdoCtaPagadosRepository>(
      () => appModule.edoCtaPagadosRepository,
    );
    gh.factory<_i1053.EdoCtaPagadosUseCases>(
      () => appModule.edoCtaPagadosUseCases,
    );
    gh.factory<_i299.BannerService>(() => appModule.bannerService);
    gh.factory<_i374.BannerRepository>(() => appModule.bannerRepository);
    gh.factory<_i557.BannerUseCases>(() => appModule.bannerUseCases);
    gh.factory<_i965.TicketService>(() => appModule.ticketService);
    gh.factory<_i543.TicketArchivoStorage>(
      () => appModule.ticketArchivoStorage,
    );
    gh.factory<_i522.TicketRepository>(() => appModule.ticketRepository);
    gh.factory<_i60.TicketUseCases>(() => appModule.ticketUseCases);
    gh.factory<_i303.FcmService>(() => appModule.fcmService);
    gh.factory<_i955.NotificacionService>(() => appModule.notificacionService);
    gh.factory<_i775.NotificacionRepository>(
      () => appModule.notificacionRepository,
    );
    gh.factory<_i274.NotificacionUseCases>(
      () => appModule.notificacionUseCases,
    );
    gh.factory<_i908.FacturaService>(() => appModule.facturaService);
    gh.factory<_i1073.FacturaRepository>(() => appModule.facturaRepository);
    gh.factory<_i504.FacturaUseCases>(() => appModule.facturaUseCases);
    gh.factory<_i7.VersionService>(() => appModule.versionService);
    gh.factory<_i943.VersionRepository>(() => appModule.versionRepository);
    gh.factory<_i922.VersionUseCases>(() => appModule.versionUseCases);
    gh.factory<_i518.ResenaStorage>(() => appModule.resenaStorage);
    gh.factory<_i667.ResenaNativa>(() => appModule.resenaNativa);
    gh.factory<_i434.ResenaRepository>(() => appModule.resenaRepository);
    gh.factory<_i131.ResenaUseCases>(() => appModule.resenaUseCases);
    gh.factory<_i1069.AutenticadorBiometrico>(
      () => appModule.autenticadorBiometrico,
    );
    gh.factory<_i241.BiometriaStorage>(() => appModule.biometriaStorage);
    gh.factory<_i510.BiometriaRepository>(() => appModule.biometriaRepository);
    gh.factory<_i275.BiometriaUseCases>(() => appModule.biometriaUseCases);
    gh.lazySingleton<_i844.SeleccionPagosStoragePorEmisor>(
      () => appModule.seleccionPagosStoragePorEmisor,
    );
    gh.lazySingleton<_i844.EdoCtaListBlocPorEmisor>(
      () => appModule.edoCtaListBlocPorEmisor,
    );
    gh.lazySingleton<_i844.CarritoBlocPorEmisor>(
      () => appModule.carritoBlocPorEmisor,
    );
    return this;
  }
}

class _$AppModule extends _i21.AppModule {}
