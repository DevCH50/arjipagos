/// Tests unitarios para BannerBloc.
///
/// Verifican la carga de la tirilla y, sobre todo, que un fallo **no estorbe**:
/// los banners son contenido informativo y su error no debe vaciar la tirilla
/// ni llegar crudo a la pantalla.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerBloc.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerState.dart';
import 'package:bloc_test/bloc_test.dart';
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
    bloc = BannerBloc(createMockBannerUseCases(getBanners: mockGetBanners));
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
}
