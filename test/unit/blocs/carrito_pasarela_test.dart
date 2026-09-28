/// Tests de **por qué pasarela cobra cada emisor fiscal**.
///
/// Desde el 2026-09-24 no todos los emisores cobran igual: el 1 («Pagos
/// Pendientes») sigue con Adquira y el 2 («Otros pagos») pasó a OpenPay. Los
/// dos acaban abriendo el mismo WebView, así que la diferencia vive entera en
/// `CarritoBloc._onPagar` y es la que se blinda aquí.
///
/// Lo que estos tests no dejan romper:
///
/// 1. **El emisor 1 no se ha tocado.** Sigue mandando el formulario de Adquira
///    al endpoint del contrato, con su `idexpress` y su `referencia`, y **sin
///    pasar por OpenPay ni una sola vez**.
/// 2. **El emisor 2 pide la URL y la pone en `pagoData`**, con `params` vacío
///    —que es la señal de que el WebView debe cargar con GET— y sin rastro de
///    los parámetros de Adquira.
/// 3. **Un fallo al crear el cobro se queda en el carrito**, con el mensaje que
///    manda el backend y sin `pagoData`: si hubiera `pagoData`, la pantalla
///    navegaría al WebView de un cobro que no existe.
library;

import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/data/api/pasarela_pago.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/OpenpayCheckout.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

const String _urlOpenpay = 'https://sandbox-api.openpay.mx/ck/Cb0EJHFIp2aG';

const OpenpayCheckout _checkout = OpenpayCheckout(
  url: _urlOpenpay,
  orderId: '10A11-N1758700000000',
  importe: 2000.0,
);

void main() {
  late MockSharedPref mockSharedPref;
  late MockGetUserSessionUseCase mockGetUserSession;
  late MockOpenpayService mockOpenpay;

  setUp(() {
    mockSharedPref = MockSharedPref();
    mockGetUserSession = MockGetUserSessionUseCase();
    mockOpenpay = MockOpenpayService();

    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
    when(
      () => mockGetUserSession.run(),
    ).thenAnswer((_) async => TestAuthResponse.valid);
  });

  CarritoBloc crearBloc(int emisorFiscalId) => CarritoBloc(
    seleccionStorage: SeleccionPagosStorage(
      mockSharedPref,
      claveSeleccion: ConfiguracionAdquira.para(emisorFiscalId).claveSeleccion,
    ),
    authUseCases: createMockAuthUseCases(getUserSession: mockGetUserSession),
    edoCtaUseCases: createMockEdoCtaUseCases(),
    emisorFiscalId: emisorFiscalId,
    openpayService: mockOpenpay,
  );

  /// Carrito con dos cargos del emisor [emisorFiscalId], listos para pagar.
  CarritoState conDosCargos(int emisorFiscalId) => CarritoState(
    emisorFiscalActivo: emisorFiscalId,
    alumnos: [
      alumnoConPagos(1, [
        pagoDePrueba(id: 10, emisorFiscalId: emisorFiscalId, total: 1000),
        pagoDePrueba(id: 11, emisorFiscalId: emisorFiscalId, total: 1000),
      ]),
    ],
    pagosSeleccionados: const {
      TestEstadoDeCuenta.cicloActual: {
        1: [10, 11],
      },
    },
  );

  group('La configuración dice por dónde cobra cada emisor', () {
    test('el emisor 1 cobra por Adquira', () {
      expect(ConfiguracionAdquira.ef1.pasarela, PasarelaPago.adquira);
    });

    test('el emisor 2 cobra por OpenPay', () {
      expect(ConfiguracionAdquira.ef2.pasarela, PasarelaPago.openpay);
    });

    test('un emisor desconocido cae en Adquira, como siempre', () {
      // El fallback es `ef1`: se prefiere cobrar en la cuenta principal —donde
      // el dinero se puede reasignar— a dejar al usuario sin poder pagar.
      expect(ConfiguracionAdquira.para(99).pasarela, PasarelaPago.adquira);
    });
  });

  group('Emisor 1 — Adquira, intacto', () {
    blocTest<CarritoBloc, CarritoState>(
      'manda el formulario al endpoint de Adquira con sus parámetros',
      build: () => crearBloc(1),
      seed: () => conDosCargos(1),
      act: (bloc) => bloc.add(const CarritoPagarEvent()),
      verify: (bloc) {
        final pagoData = bloc.state.pagoData!;

        expect(pagoData['url'], ConfiguracionAdquira.ef1.endpoint);

        final params = pagoData['params'] as Map<String, String>;
        expect(params['idexpress'], ConfiguracionAdquira.ef1.idExpress);
        expect(params['emisorfiscal_id'], '1');
        expect(params['importe'], '2000.00');
        expect(params['referencia'], bloc.state.referenciaPago);

        // 🔴 Lo importante de este test: Adquira no pasa por OpenPay.
        verifyNever(() => mockOpenpay.crearCargo(any()));
      },
    );
  });

  group('Emisor 2 — OpenPay', () {
    blocTest<CarritoBloc, CarritoState>(
      'pide el cobro con la referencia y abre la URL que le devuelven',
      build: () {
        when(
          () => mockOpenpay.crearCargo(any()),
        ).thenAnswer((_) async => Success<OpenpayCheckout>(_checkout));
        return crearBloc(2);
      },
      seed: () => conDosCargos(2),
      act: (bloc) => bloc.add(const CarritoPagarEvent()),
      verify: (bloc) {
        final referencia = bloc.state.referenciaPago;
        verify(() => mockOpenpay.crearCargo(referencia)).called(1);

        final pagoData = bloc.state.pagoData!;
        expect(pagoData['url'], _urlOpenpay);

        // `params` vacío = el WebView carga con GET. Ver
        // `PagoWebViewPage._cargarPagina`.
        expect(pagoData['params'], isEmpty);

        // Y ni rastro del endpoint de Adquira: si apareciera, el emisor 2
        // estaría cobrando en la cuenta del 1 otra vez.
        expect(pagoData['url'], isNot(ConfiguracionAdquira.ef2.endpoint));
      },
    );

    blocTest<CarritoBloc, CarritoState>(
      'no le manda el importe al backend: lo calcula el servidor',
      build: () {
        when(
          () => mockOpenpay.crearCargo(any()),
        ).thenAnswer((_) async => Success<OpenpayCheckout>(_checkout));
        return crearBloc(2);
      },
      seed: () => conDosCargos(2),
      act: (bloc) => bloc.add(const CarritoPagarEvent()),
      verify: (_) {
        // `crearCargo` recibe un único argumento, la referencia. Si algún día
        // se le añadiera el importe, esta firma dejaría de compilar y habría
        // que leer por qué no debe hacerse.
        final capturada =
            verify(() => mockOpenpay.crearCargo(captureAny())).captured.single;
        expect(capturada, isA<String>());
        expect(capturada as String, isNot(contains('2000')));
      },
    );

    blocTest<CarritoBloc, CarritoState>(
      'si el cobro no se puede crear, enseña el mensaje y NO navega',
      build: () {
        when(() => mockOpenpay.crearCargo(any())).thenAnswer(
          (_) async => Error<OpenpayCheckout>(
            'Estos cargos ya no están pendientes. Verifica tu estado de cuenta.',
          ),
        );
        return crearBloc(2);
      },
      seed: () => conDosCargos(2),
      act: (bloc) => bloc.add(const CarritoPagarEvent()),
      verify: (bloc) {
        expect(
          bloc.state.errorMessage,
          'Estos cargos ya no están pendientes. Verifica tu estado de cuenta.',
        );
        // Sin esto, `carrito_body` navegaría al WebView de un cobro que no
        // existe y el usuario vería una pantalla en blanco.
        expect(bloc.state.pagoData, isNull);
        expect(bloc.state.isProcesandoPago, isFalse);
      },
    );

    blocTest<CarritoBloc, CarritoState>(
      'con el carrito vacío ni llega a pedir el cobro',
      build: () => crearBloc(2),
      seed: () => const CarritoState(emisorFiscalActivo: 2),
      act: (bloc) => bloc.add(const CarritoPagarEvent()),
      verify: (_) => verifyNever(() => mockOpenpay.crearCargo(any())),
    );
  });

  // El separador de la referencia lo decide la plataforma: `A` en Android e
  // `I` en iOS (`PoliticaEmisor.separador`), y es lo que le dice al backend por
  // qué canal entró el pago —`ReferenciaOpenpay::canalDesde` lo traduce a 5
  // (Android) o 4 (iOS)—. La pasarela nueva **no** puede romper eso: si a
  // OpenPay le llegara siempre la referencia de Android, todos los cobros
  // hechos desde iPhone quedarían registrados como Android.
  group('La referencia respeta la plataforma también con OpenPay', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final (TargetPlatform plataforma, String separador) in [
      (TargetPlatform.iOS, 'I'),
      (TargetPlatform.android, 'A'),
    ]) {
      blocTest<CarritoBloc, CarritoState>(
        'en $plataforma manda la referencia con "$separador"',
        setUp: () {
          debugDefaultTargetPlatformOverride = plataforma;
          when(
            () => mockOpenpay.crearCargo(any()),
          ).thenAnswer((_) async => Success<OpenpayCheckout>(_checkout));
        },
        build: () => crearBloc(2),
        seed: () => conDosCargos(2),
        act: (bloc) => bloc.add(const CarritoPagarEvent()),
        verify: (_) {
          final capturada =
              verify(() => mockOpenpay.crearCargo(captureAny())).captured.single
                  as String;
          expect(capturada, '10${separador}11');
        },
      );
    }
  });

  // El diálogo de error lo dispara `carrito_body` mirando `state.errorMessage`
  // en CADA estado, no solo en el que lo trajo. Visto en el Oppo el 2026-09-24:
  // el cobro falló, el usuario cerró el aviso, vació el carrito y el aviso
  // volvió a salir encima del carrito ya vacío.
  group('El error se descarta cuando el usuario lo cierra', () {
    blocTest<CarritoBloc, CarritoState>(
      'CarritoLimpiarErrorEvent borra el mensaje',
      build: () => crearBloc(2),
      seed: () => const CarritoState(
        emisorFiscalActivo: 2,
        errorMessage: 'No pudimos iniciar el pago',
      ),
      act: (bloc) => bloc.add(const CarritoLimpiarErrorEvent()),
      expect: () => [
        isA<CarritoState>().having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<CarritoBloc, CarritoState>(
      'sin error que borrar no emite nada',
      build: () => crearBloc(2),
      seed: () => const CarritoState(emisorFiscalActivo: 2),
      act: (bloc) => bloc.add(const CarritoLimpiarErrorEvent()),
      expect: () => <CarritoState>[],
    );

    blocTest<CarritoBloc, CarritoState>(
      'tras descartarlo, vaciar el carrito ya no lo resucita',
      build: () {
        when(() => mockOpenpay.crearCargo(any())).thenAnswer(
          (_) async => Error<OpenpayCheckout>('Estos cargos ya no están pendientes.'),
        );
        return crearBloc(2);
      },
      seed: () => conDosCargos(2),
      act: (bloc) async {
        bloc.add(const CarritoPagarEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CarritoLimpiarErrorEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CarritoLimpiarEvent());
      },
      verify: (bloc) => expect(bloc.state.errorMessage, isNull),
    );
  });
}
