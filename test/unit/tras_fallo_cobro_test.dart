/// Tests de `actuarTrasFalloCobro`: qué pasa al cerrar el diálogo de un cobro
/// de OpenPay que no se pudo crear.
///
/// Lo pide el documento del backend (2026-09-28): un `401` lleva al login y un
/// `422` recarga los cargos. Se monta una pila como la real —lista del emisor
/// → carrito— para comprobar **a qué pantalla** acaba el tutor.
library;

import 'dart:io';

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/ErrorCobroOpenpay.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/tras_fallo_cobro.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCarrito extends Mock implements CarritoBloc {}

class _MockListaPorEmisor extends Mock implements EdoCtaListBlocPorEmisor {}

class _MockLista extends Mock implements EdoCtaListBloc {}

/// Ruta de la lista de «Otros pagos» (emisor 2).
const String _rutaLista = 'edo_cta_otros';

void main() {
  late _MockCarrito carrito;
  late _MockLista lista;
  late int cierresDeSesion;

  setUpAll(() {
    registerFallbackValue(const CarritoInitialEvent());
    registerFallbackValue(const EdoCtaListRefreshEvent());
  });

  setUp(() {
    carrito = _MockCarrito();
    // `BlocProvider` escucha el stream del BLoC en cuanto alguien lo lee.
    when(() => carrito.stream).thenAnswer((_) => const Stream.empty());
    lista = _MockLista();
    cierresDeSesion = 0;
    final listas = _MockListaPorEmisor();
    when(() => listas.de(any())).thenReturn(lista);
    locator.registerSingleton<EdoCtaListBlocPorEmisor>(listas);
  });

  tearDown(() => locator.reset());

  /// Lista → carrito, con un botón en el carrito que hace lo mismo que el
  /// «Aceptar» del diálogo de error.
  Future<void> montarYAceptar(
    WidgetTester tester,
    MotivoFalloCobro? motivo,
  ) async {
    final navegador = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegador,
        initialRoute: _rutaLista,
        onGenerateRoute: (ajustes) => MaterialPageRoute<void>(
          settings: ajustes,
          builder: (_) => ajustes.name == 'carrito'
              ? BlocProvider<CarritoBloc>.value(
                  value: carrito,
                  child: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => actuarTrasFalloCobro(
                        context,
                        motivo: motivo,
                        emisorFiscalId: 2,
                        cerrarSesion: (_) async => cierresDeSesion++,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                )
              : Scaffold(body: Text(ajustes.name!)),
        ),
      ),
    );
    navegador.currentState!.pushNamed('carrito');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
  }

  testWidgets('401: cierra la sesión entera y va al login', (tester) async {
    await montarYAceptar(tester, MotivoFalloCobro.sesionExpirada);

    expect(cierresDeSesion, 1);
    expect(find.text('login'), findsOneWidget);
    // Sin nada detrás: el botón atrás no puede volver a un carrito sin sesión.
    expect(find.text(_rutaLista, skipOffstage: false), findsNothing);
  });

  testWidgets('422: vacía el carrito, recarga la lista y vuelve a ella', (
    tester,
  ) async {
    await montarYAceptar(tester, MotivoFalloCobro.cargosDesactualizados);

    verify(() => carrito.add(const CarritoLimpiarEvent())).called(1);
    verify(() => lista.add(const EdoCtaListRefreshEvent())).called(1);
    expect(find.text(_rutaLista), findsOneWidget);
    expect(cierresDeSesion, 0);
  });

  for (final motivo in [MotivoFalloCobro.otro, null]) {
    testWidgets('${motivo?.name ?? 'sin motivo'}: se queda en el carrito', (
      tester,
    ) async {
      await montarYAceptar(tester, motivo);

      expect(find.text('Aceptar'), findsOneWidget);
      verifyNever(() => carrito.add(any()));
      verifyNever(() => lista.add(any()));
      expect(cierresDeSesion, 0);
    });
  }

  test('el «Aceptar» del error del carrito pasa el motivo y el emisor', () {
    // Montar `CarritoBody` con un error concreto exige media app; basta con
    // fijar que el diálogo sigue llamando aquí con el motivo del estado.
    final String fuente = File(
      'lib/src/presentation/pages/carrito/widgets/carrito_body.dart',
    ).readAsStringSync();

    expect(fuente, contains('actuarTrasFalloCobro('));
    expect(fuente, contains('motivo: state.motivoFallo'));
    expect(fuente, contains('emisorFiscalId: state.emisorFiscalActivo'));
  });
}
