// Tests del carrito cuando no se pueden traer los cargos del servidor.
//
// Visto en el Oppo el 2026-10-01: con un pago seleccionado y sin red, el
// carrito sacaba el diálogo de error y debajo «Carrito vacío — Selecciona
// pagos desde Estados de Cuenta», sin forma de reintentar. La selección no se
// había perdido; lo que faltaba era recordar que la carga falló después de
// cerrar el diálogo, que es lo que hace `CarritoState.errorDeCarga`.

import 'dart:async';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_body.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockSharedPref mockSharedPref;
  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;

  const String mensajeSinRed = 'Sin conexión, intente más tarde';

  setUp(() {
    mockSharedPref = MockSharedPref();
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();

    // Hay un pago seleccionado —el 1 del alumno de prueba, en su ciclo—: el
    // carrito NO está vacío de verdad.
    when(() => mockSharedPref.readMap(any())).thenAnswer(
      (_) async => {
        '${TestEstadoDeCuenta.cicloActual}': {
          '1': [1],
        },
      },
    );
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  CarritoBloc createBloc() {
    return CarritoBloc(
      seleccionStorage: SeleccionPagosStorage(
        mockSharedPref,
        claveSeleccion: 'seleccion_pagos_ef1',
      ),
      authUseCases: createMockAuthUseCases(
        getUserSession: MockGetUserSessionUseCase(),
      ),
      edoCtaUseCases: createMockEdoCtaUseCases(
        getEstadosDeCuenta: mockGetEstadosDeCuenta,
      ),
      emisorFiscalId: 1,
    );
  }

  /// Hace que la petición de los cargos falle con [mensaje].
  void cargaFalla() {
    when(
      () => mockGetEstadosDeCuenta.run(
        emisorFiscalId: any(named: 'emisorFiscalId'),
      ),
    ).thenAnswer((_) async => Error(mensajeSinRed));
  }

  /// Hace que la petición de los cargos responda con el alumno de prueba.
  void cargaResponde() {
    when(
      () => mockGetEstadosDeCuenta.run(
        emisorFiscalId: any(named: 'emisorFiscalId'),
      ),
    ).thenAnswer(
      (_) async => Success(
        EstadosDeCuentaResponse(
          alumnos: [TestAlumno.activo],
          familia: 'Test',
          success: true,
          message: '',
        ),
      ),
    );
  }

  group('CarritoBloc — errorDeCarga', () {
    blocTest<CarritoBloc, CarritoState>(
      'si la carga falla, guarda el motivo además del aviso del diálogo',
      setUp: cargaFalla,
      build: createBloc,
      act: (bloc) => bloc.add(const CarritoInitialEvent()),
      expect: () => [
        isA<CarritoState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CarritoState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage', mensajeSinRed)
            .having((s) => s.errorDeCarga, 'errorDeCarga', mensajeSinRed),
      ],
    );

    blocTest<CarritoBloc, CarritoState>(
      'si la carga lanza una excepción, también guarda el motivo',
      setUp: () {
        when(
          () => mockGetEstadosDeCuenta.run(
            emisorFiscalId: any(named: 'emisorFiscalId'),
          ),
        ).thenThrow(Exception('Failed host lookup'));
      },
      build: createBloc,
      act: (bloc) => bloc.add(const CarritoInitialEvent()),
      verify: (bloc) {
        expect(bloc.state.errorDeCarga, isNotNull);
        // Nunca la excepción cruda (CLAUDE.md: mensajeErrorRed).
        expect(bloc.state.errorDeCarga, isNot(contains('Exception')));
      },
    );

    blocTest<CarritoBloc, CarritoState>(
      'cerrar el diálogo NO borra errorDeCarga',
      setUp: cargaFalla,
      build: createBloc,
      act: (bloc) async {
        bloc.add(const CarritoInitialEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CarritoLimpiarErrorEvent());
      },
      verify: (bloc) {
        expect(bloc.state.errorMessage, isNull);
        expect(bloc.state.errorDeCarga, mensajeSinRed);
      },
    );

    blocTest<CarritoBloc, CarritoState>(
      'reintentar con red lo borra y trae los pagos',
      setUp: cargaFalla,
      build: createBloc,
      act: (bloc) async {
        bloc.add(const CarritoInitialEvent());
        await Future<void>.delayed(Duration.zero);
        cargaResponde();
        bloc.add(const CarritoInitialEvent());
      },
      verify: (bloc) {
        expect(bloc.state.errorDeCarga, isNull);
        expect(bloc.state.itemsCarrito, isNotEmpty);
      },
    );
  });

  group('CarritoBody — carga fallida', () {
    /// Pulsos con reloj, como en `appbar_encuentra_su_bloc_test.dart`: los
    /// `Future` de la carga solo avanzan si avanza el reloj de FakeAsync.
    Future<void> asentar(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    /// Cierra el BLoC sin esperarlo: `await bloc.close()` dentro de FakeAsync
    /// no vuelve nunca, porque nadie mueve el reloj mientras espera.
    Future<void> cerrar(WidgetTester tester, CarritoBloc bloc) async {
      unawaited(bloc.close());
      await tester.pump();
    }

    /// Monta el cuerpo del carrito y lanza su carga. El BLoC se crea aquí,
    /// dentro del `testWidgets`: uno creado en `setUp` nace fuera de la zona
    /// FakeAsync y ningún `pump` resuelve sus `Future`.
    Future<CarritoBloc> montar(WidgetTester tester) async {
      final CarritoBloc bloc = createBloc();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<CarritoBloc>.value(
              value: bloc,
              child: const CarritoBody(),
            ),
          ),
        ),
      );
      bloc.add(const CarritoInitialEvent());
      await asentar(tester);
      return bloc;
    }

    testWidgets('pinta «Error al cargar» con Reintentar, no «Carrito vacío»', (
      tester,
    ) async {
      cargaFalla();
      final CarritoBloc bloc = await montar(tester);

      // Se cierra el diálogo, como haría el usuario.
      await tester.tap(find.text(AppStrings.accept));
      await asentar(tester);

      expect(find.text(AppStrings.errorAlCargar), findsOneWidget);
      expect(find.text(mensajeSinRed), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(find.text(AppStrings.carritoVacio), findsNothing);

      await cerrar(tester, bloc);
    });

    testWidgets('Reintentar vuelve a pedir los cargos', (tester) async {
      cargaFalla();
      final CarritoBloc bloc = await montar(tester);
      await tester.tap(find.text(AppStrings.accept));
      await asentar(tester);

      cargaResponde();
      await tester.tap(find.text(AppStrings.retry));
      await asentar(tester);

      verify(
        () => mockGetEstadosDeCuenta.run(
          emisorFiscalId: any(named: 'emisorFiscalId'),
        ),
      ).called(2);
      expect(find.text(AppStrings.errorAlCargar), findsNothing);
      expect(bloc.state.itemsCarrito, isNotEmpty);

      await cerrar(tester, bloc);
    });

    testWidgets('sin pagos seleccionados sigue diciendo «Carrito vacío»', (
      tester,
    ) async {
      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
      final CarritoBloc bloc = await montar(tester);

      expect(find.text(AppStrings.carritoVacio), findsOneWidget);
      expect(find.text(AppStrings.errorAlCargar), findsNothing);

      await cerrar(tester, bloc);
    });
  });
}
