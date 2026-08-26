import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/edocta/EdoCtaUseCases.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';

/// Registros con **una instancia por emisor fiscal**.
///
/// Cada emisor es un contrato distinto con Adquira, con su propia cuenta
/// bancaria, sus propias reglas y su propio almacén. La consecuencia en el
/// código es que no puede haber un único BLoC ni un único almacén compartidos:
/// con ellos, vaciar un carrito o completar un pago alcanzaba al otro emisor.
///
/// Aquí no hay lógica de negocio, solo la fábrica: se crea una instancia por
/// cada emisor de `ConfiguracionAdquira.emisoresConocidos`, así que **añadir un
/// EF3 no obliga a tocar este archivo**.
///
/// Las instancias son perpetuas —viven lo que la app— igual que antes vivían
/// las de `blocProviders`. Por eso [EdoCtaListBlocPorEmisor.todos] existe: el
/// cierre de sesión tiene que vaciarlas todas, y el login recargarlas.

/// Almacenes de selección de pagos, uno por emisor.
class SeleccionPagosStoragePorEmisor {
  final Map<int, SeleccionPagosStorage> _porEmisor;

  SeleccionPagosStoragePorEmisor(SharedPref sharedPref)
    : _porEmisor = {
        for (final int emisor in ConfiguracionAdquira.emisoresConocidos)
          emisor: SeleccionPagosStorage(
            sharedPref,
            claveSeleccion: ConfiguracionAdquira.para(emisor).claveSeleccion,
          ),
      };

  /// Almacén de [emisorFiscalId].
  ///
  /// Un emisor desconocido cae en el predeterminado, igual que hace
  /// `ConfiguracionAdquira.para`: es preferible a dejar la pantalla sin
  /// almacén y sin poder seleccionar nada.
  SeleccionPagosStorage de(int emisorFiscalId) =>
      _porEmisor[emisorFiscalId] ??
      _porEmisor[ConfiguracionAdquira.emisorFiscalPredeterminado]!;
}

/// BLoCs de la lista de estados de cuenta, uno por emisor.
class EdoCtaListBlocPorEmisor {
  final Map<int, EdoCtaListBloc> _porEmisor;

  EdoCtaListBlocPorEmisor(
    EdoCtaUseCases edoCtaUseCases,
    SeleccionPagosStoragePorEmisor storages,
  ) : _porEmisor = {
        for (final int emisor in ConfiguracionAdquira.emisoresConocidos)
          emisor: EdoCtaListBloc(
            edoCtaUseCases,
            storages.de(emisor),
            emisorFiscalId: emisor,
          ),
      };

  EdoCtaListBloc de(int emisorFiscalId) =>
      _porEmisor[emisorFiscalId] ??
      _porEmisor[ConfiguracionAdquira.emisorFiscalPredeterminado]!;

  /// Todas las instancias. Solo para lo que es de la sesión y no de un emisor:
  /// vaciarlas al cerrar sesión y recargarlas al entrar.
  Iterable<EdoCtaListBloc> get todos => _porEmisor.values;
}

/// Carritos, uno por emisor.
class CarritoBlocPorEmisor {
  final Map<int, CarritoBloc> _porEmisor;

  CarritoBlocPorEmisor(
    AuthUseCases authUseCases,
    EdoCtaUseCases edoCtaUseCases,
    SeleccionPagosStoragePorEmisor storages,
  ) : _porEmisor = {
        for (final int emisor in ConfiguracionAdquira.emisoresConocidos)
          emisor: CarritoBloc(
            seleccionStorage: storages.de(emisor),
            authUseCases: authUseCases,
            edoCtaUseCases: edoCtaUseCases,
            emisorFiscalId: emisor,
          ),
      };

  CarritoBloc de(int emisorFiscalId) =>
      _porEmisor[emisorFiscalId] ??
      _porEmisor[ConfiguracionAdquira.emisorFiscalPredeterminado]!;

  Iterable<CarritoBloc> get todos => _porEmisor.values;
}
