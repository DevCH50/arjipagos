/// Tests unitarios para BannerBloc.
///
/// Verifican la carga de la tirilla y, sobre todo, que un fallo **no estorbe**:
/// los banners son contenido informativo y su error no debe vaciar la tirilla
/// ni llegar crudo a la pantalla.
library;

import 'dart:async';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerBloc.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockGetBannersUseCase mockGetBanners;
  late BannerBloc bloc;

  final respuesta = BannersResponse.fromJson(TestBanner.respuestaJson);

  setUp(() {
    mockGetBanners = MockGetBannersUseCase();
    // Los streams de FCM se inyectan vacíos: sin esto el BLoC pediría
    // `FirebaseMessaging.instance` y el test moriría con "No Firebase App".
    bloc = BannerBloc(
      createMockBannerUseCases(getBanners: mockGetBanners),
      fcmPrimerPlanoStream: const Stream.empty(),
      fcmToqueStream: const Stream.empty(),
      getInitialMessage: () async => null,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('BannerBloc — estado inicial', () {
    test('arranca vacío, sin carga y sin error', () {
      expect(bloc.state.banners, isEmpty);
      expect(bloc.state.tieneBanners, isFalse);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });
  });

  group('BannerBloc — BannerCargarEvent', () {
    blocTest<BannerBloc, BannerState>(
      'emite carga y luego los banners del servidor',
      build: () {
        when(() => mockGetBanners.run())
            .thenAnswer((_) async => utils.Success(respuesta));
        return bloc;
      },
      act: (b) => b.add(const BannerCargarEvent()),
      verify: (b) {
        expect(b.state.isLoading, isFalse);
        expect(b.state.banners, hasLength(2));
        expect(b.state.tieneBanners, isTrue);
        expect(b.state.errorMessage, isNull);
      },
    );

    blocTest<BannerBloc, BannerState>(
      'una respuesta sin banners deja la tirilla vacía, sin error',
      build: () {
        when(() => mockGetBanners.run()).thenAnswer((_) async =>
            utils.Success(BannersResponse.fromJson(
                TestBanner.respuestaVaciaJson)));
        return bloc;
      },
      act: (b) => b.add(const BannerCargarEvent()),
      verify: (b) {
        expect(b.state.tieneBanners, isFalse);
        expect(b.state.errorMessage, isNull);
      },
    );

    blocTest<BannerBloc, BannerState>(
      'banners sin imagen no cuentan como tirilla con contenido',
      build: () {
        final sinImagen = BannersResponse.fromJson({
          'success': true,
          'message': 'OK',
          'banners': [
            Map<String, dynamic>.from(TestBanner.anualidadJson)
              ..['imagen_url'] = '',
          ],
        });
        when(() => mockGetBanners.run())
            .thenAnswer((_) async => utils.Success(sinImagen));
        return bloc;
      },
      act: (b) => b.add(const BannerCargarEvent()),
      verify: (b) {
        expect(b.state.banners, hasLength(1));
        // Sin portada no hay nada que pintar en la tirilla.
        expect(b.state.tieneBanners, isFalse);
      },
    );

    blocTest<BannerBloc, BannerState>(
      'guarda el mensaje de error sin vaciar la tirilla ya cargada',
      build: () {
        when(() => mockGetBanners.run()).thenAnswer(
            (_) async => utils.Error<BannersResponse>(AppStrings.errorTimeout));
        return bloc;
      },
      seed: () => BannerState(banners: respuesta.banners),
      act: (b) => b.add(const BannerCargarEvent()),
      verify: (b) {
        expect(b.state.errorMessage, AppStrings.errorTimeout);
        // El contenido viejo le sirve más al usuario que una franja vacía.
        expect(b.state.banners, hasLength(2));
        expect(b.state.isLoading, isFalse);
      },
    );

    blocTest<BannerBloc, BannerState>(
      'una excepción inesperada nunca llega cruda al estado',
      build: () {
        when(() => mockGetBanners.run())
            .thenThrow(Exception('fallo interno del repositorio'));
        return bloc;
      },
      act: (b) => b.add(const BannerCargarEvent()),
      verify: (b) {
        expect(b.state.isLoading, isFalse);
        expect(b.state.errorMessage, isNotNull);
        expect(b.state.errorMessage, isNot(contains('Exception')));
      },
    );

    blocTest<BannerBloc, BannerState>(
      'una recarga exitosa limpia el error anterior',
      build: () {
        when(() => mockGetBanners.run())
            .thenAnswer((_) async => utils.Success(respuesta));
        return bloc;
      },
      seed: () => const BannerState(errorMessage: 'error anterior'),
      act: (b) => b.add(const BannerCargarEvent()),
      verify: (b) => expect(b.state.errorMessage, isNull),
    );
  });

  group('BannerState — tieneBanners', () {
    test('es falso con la lista vacía', () {
      expect(const BannerState().tieneBanners, isFalse);
    });

    test('es verdadero cuando al menos un banner trae imagen', () {
      final state = BannerState(banners: <BannerInfo>[
        BannerInfo.fromJson(TestBanner.anualidadJson),
      ]);

      expect(state.tieneBanners, isTrue);
    });
  });

  group('BannerBloc — refresco por push del servidor', () {
    /// Push tal como lo manda el backend para los banners.
    RemoteMessage pushBanner({String? bannerId}) => RemoteMessage(
          data: <String, dynamic>{
            'campania': 'banner',
            'accion': 'refrescar_banners',
            if (bannerId case final String id) 'banner_id': id,
          },
        );

    /// BLoC con un stream de primer plano controlado por el test.
    BannerBloc construir(Stream<RemoteMessage> primerPlano) => BannerBloc(
          createMockBannerUseCases(getBanners: mockGetBanners),
          fcmPrimerPlanoStream: primerPlano,
          fcmToqueStream: const Stream.empty(),
          getInitialMessage: () async => null,
        );

    test('un push de banners recarga la lista', () async {
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final controlador = StreamController<RemoteMessage>();
      final propio = construir(controlador.stream);
      addTearDown(() async {
        await controlador.close();
        await propio.close();
      });

      controlador.add(pushBanner());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockGetBanners.run()).called(1);
      expect(propio.state.banners, hasLength(2));
    });

    test('el refresco NO pasa por el esqueleto', () async {
      // La tirilla no debe parpadear: el usuario no ha pedido nada.
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final controlador = StreamController<RemoteMessage>();
      final propio = construir(controlador.stream);
      final emitidos = <bool>[];
      final sub = propio.stream.listen((s) => emitidos.add(s.isLoading));
      addTearDown(() async {
        await sub.cancel();
        await controlador.close();
        await propio.close();
      });

      controlador.add(pushBanner());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitidos, isNot(contains(true)));
    });

    test('un push de otra campaña no toca la tirilla', () async {
      // Es la garantía de que las notificaciones normales no disparan
      // peticiones de banners a cada mensaje que llegue.
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final controlador = StreamController<RemoteMessage>();
      final propio = construir(controlador.stream);
      addTearDown(() async {
        await controlador.close();
        await propio.close();
      });

      controlador.add(const RemoteMessage(data: <String, dynamic>{
        'campania': 'estado_cuenta',
        'accion': 'refrescar_banners',
      }));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockGetBanners.run());
    });

    test('sin las dos claves no se refresca', () async {
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final controlador = StreamController<RemoteMessage>();
      final propio = construir(controlador.stream);
      addTearDown(() async {
        await controlador.close();
        await propio.close();
      });

      // Campaña correcta pero sin acción: no basta.
      controlador.add(const RemoteMessage(
        data: <String, dynamic>{'campania': 'banner'},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockGetBanners.run());
    });

    test('con banner_id queda anotada la nota a abrir', () async {
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final controlador = StreamController<RemoteMessage>();
      final propio = construir(controlador.stream);
      addTearDown(() async {
        await controlador.close();
        await propio.close();
      });

      controlador.add(pushBanner(bannerId: '7'));
      final estado =
          await propio.stream.firstWhere((s) => s.bannerIdAAbrir != null);

      expect(estado.bannerIdAAbrir, '7');
    });

    test('sin banner_id —aviso eliminado— solo se recarga', () async {
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final controlador = StreamController<RemoteMessage>();
      final propio = construir(controlador.stream);
      addTearDown(() async {
        await controlador.close();
        await propio.close();
      });

      controlador.add(pushBanner());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(propio.state.bannerIdAAbrir, isNull);
      verify(() => mockGetBanners.run()).called(1);
    });

    test('la nota a abrir se suelta cuando la pantalla la atiende', () async {
      when(() => mockGetBanners.run())
          .thenAnswer((_) async => utils.Success(respuesta));

      final propio = construir(const Stream.empty());
      addTearDown(propio.close);

      propio.add(const BannerAbrirDetalleEvent('7'));
      await propio.stream.firstWhere((s) => s.bannerIdAAbrir == '7');

      propio.add(const BannerDetalleAtendidoEvent());
      final estado =
          await propio.stream.firstWhere((s) => s.bannerIdAAbrir == null);

      // Sin esto, cualquier reconstrucción posterior reabriría el modal.
      expect(estado.bannerIdAAbrir, isNull);
    });
  });
}
