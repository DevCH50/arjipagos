/// Los botones del `AppBar` de las pantallas con **un BLoC por emisor** tienen
/// que encontrar su BLoC.
///
/// **El fallo que este test existe para que no vuelva (08-sep-2026).** El botón
/// de recargar de Estados de Cuenta tiraba la pantalla entera en cuanto se
/// tocaba, en las dos entradas del menú:
///
/// ```
/// ProviderNotFoundException: Error: Could not find the correct Provider<EdoCtaListBloc>
///   #3 _EdoCtaPageState._buildAppBar.<anonymous closure> (EdoCtaPage.dart:132)
/// ```
///
/// **La causa.** `_buildAppBar()` es un método del `State`, así que el `context`
/// que ve dentro es el del `State`, y ése está **por encima** del
/// `BlocProvider.value` que monta el propio `build`. Buscar el BLoC desde ahí
/// no encuentra nada. El `BlocBuilder` de al lado sí funcionaba —un widget se
/// coloca donde se usa, no donde se construye—, y eso hacía el fallo aún más
/// desconcertante: el botón de limpiar selección aparecía y desaparecía bien.
///
/// **Por qué no se vio venir.** Mientras `EdoCtaListBloc` colgaba de
/// `blocProviders`, en la raíz de la app, la búsqueda desde el `State`
/// encontraba el de la raíz y todo funcionaba. Se rompió al pasar a haber una
/// instancia por emisor, que ya no cuelga de la raíz sino del registro. El
/// carrito comparte esa forma exacta, así que se blinda igual.
///
/// **Por qué se monta la pantalla en vez de leer el código fuente.** Un test
/// que buscara `context.read` en el archivo pasaría por alto la siguiente
/// variante del mismo error. Aquí se pulsa el botón: si el BLoC no aparece, el
/// test cae con la excepción de verdad.
library;

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/carrito/CarritoPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/EdoCtaPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

void main() {
  const int alumnoId = 1;
  const int ciclo = TestEstadoDeCuenta.cicloActual;

  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;
  late MockSharedPref mockSharedPref;

  /// Cuántas veces se ha pedido la lista al servidor.
  ///
  /// Es lo que distingue «el botón no reventó» de «el botón hizo su trabajo»:
  /// la carga inicial deja el contador en 1, y recargar tiene que subirlo a 2.
  int llamadasAlServidor = 0;

  setUp(() {
    llamadasAlServidor = 0;
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();
    mockSharedPref = MockSharedPref();
    // Un `SharedPref` con memoria de verdad, no un stub mudo: el carrito lee la
    // selección que dejó escrita Estados de Cuenta, así que si `readMap`
    // devolviera siempre `null` el carrito llegaría vacío y no habría botón que
    // pulsar.
    final Map<String, Map<String, dynamic>> almacen = {};
    when(() => mockSharedPref.readMap(any())).thenAnswer(
      (invocacion) async => almacen[invocacion.positionalArguments.first],
    );
    when(() => mockSharedPref.save(any(), any())).thenAnswer((invocacion) async {
      // `SeleccionPagosStorage` entrega el mapa ya armado; el `jsonEncode` lo
      // hace `SharedPref` por dentro, y aquí eso no existe.
      almacen[invocacion.positionalArguments[0] as String] =
          invocacion.positionalArguments[1] as Map<String, dynamic>;
    });

    final List<EstadoDeCuenta> pagos = [
      pagoDePrueba(id: 10, pagoId: 900, numPago: 1, numPagoActivo: true),
      pagoDePrueba(id: 11, pagoId: 900, numPago: 2),
    ];
    final Alumno alumno = alumnoConPagos(alumnoId, pagos);

    when(
      () => mockGetEstadosDeCuenta.run(
        emisorFiscalId: any(named: 'emisorFiscalId'),
      ),
    ).thenAnswer((_) async {
      llamadasAlServidor++;
      return Success(
        EstadosDeCuentaResponse(
          alumnos: [alumno],
          cicloPredeterminadoId: '$ciclo',
          familiaId: '1',
          familia: 'Familia Test',
          success: true,
          message: '',
        ),
      );
    });

  });

  tearDown(() => locator.reset());

  /// Registra el registro por emisor, tal como lo arma `AppModule` pero con
  /// mocks. Las pantallas lo toman del `locator`, así que aquí va igual.
  ///
  /// **Se llama desde dentro del test, no desde `setUp`, y es obligatorio.**
  /// El cuerpo de un `testWidgets` corre en una zona `FakeAsync`: el reloj lo
  /// mueve `tester.pump`. Un BLoC creado en `setUp` nace fuera de esa zona, así
  /// que los `Future` que encadena su primer evento quedan colgados de la zona
  /// real y ningún `pump` los resuelve. El síntoma es desconcertante: la
  /// pantalla monta sin error, pero la carga inicial nunca llega y la lista se
  /// queda vacía para siempre.
  void registrarEmisores() {
    final storages = SeleccionPagosStoragePorEmisor(mockSharedPref);
    locator.registerSingleton<SharedPref>(mockSharedPref);
    locator.registerSingleton<SeleccionPagosStoragePorEmisor>(storages);
    locator.registerSingleton<EdoCtaListBlocPorEmisor>(
      EdoCtaListBlocPorEmisor(
        createMockEdoCtaUseCases(getEstadosDeCuenta: mockGetEstadosDeCuenta),
        storages,
      ),
    );
    locator.registerSingleton<CarritoBlocPorEmisor>(
      CarritoBlocPorEmisor(
        createMockAuthUseCases(),
        createMockEdoCtaUseCases(getEstadosDeCuenta: mockGetEstadosDeCuenta),
        storages,
      ),
    );
  }

  /// Monta [pantalla] dentro de un `MaterialApp` mínimo y deja que se asienten
  /// la carga inicial y sus animaciones.
  ///
  /// **Pulsos con reloj, y nunca `pumpAndSettle`.** Dos motivos distintos:
  /// la carga arranca en `didChangeDependencies` y acaba en un `Future`, que
  /// solo avanza si el reloj avanza; y la pantalla tiene animación perpetua
  /// —el punto del alumno—, así que `pumpAndSettle` no vuelve nunca y el test
  /// muere por tiempo agotado en vez de decir qué falla.
  Future<void> asentar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> montar(WidgetTester tester, Widget pantalla) async {
    if (!locator.isRegistered<EdoCtaListBlocPorEmisor>()) {
      registrarEmisores();
    }
    await tester.pumpWidget(MaterialApp(home: pantalla));
    await asentar(tester);
  }

  /// Pulsa [boton] y deja que se asiente, igual que [montar].
  Future<void> pulsar(WidgetTester tester, Finder boton) async {
    await tester.tap(boton);
    await asentar(tester);
  }

  group('Estados de Cuenta — botones del AppBar', () {
    testWidgets('el de recargar vuelve a pedir la lista, sin reventar', (
      tester,
    ) async {
      await montar(tester, const EdoCtaPage());
      expect(llamadasAlServidor, 1, reason: 'no se hizo la carga inicial');

      await pulsar(tester, find.byIcon(Icons.refresh));

      // `takeException` devuelve la excepción que el framework capturó al
      // pulsar. Con el fallo original aquí salía la `ProviderNotFoundException`.
      expect(tester.takeException(), isNull);
      expect(
        llamadasAlServidor,
        2,
        reason: 'el botón de recargar no volvió a pedir la lista',
      );
    });

    testWidgets(
      '"Otros pagos" —el emisor 2— tiene DOS botones de recargar y los dos '
      'funcionan',
      (tester) async {
        // Los pagos de prueba son del emisor 1, así que esta pantalla sale
        // vacía. No es un descuido: es lo que pone en pantalla el segundo
        // botón de recargar, el del estado vacío, que ahí es la única salida
        // que le queda al usuario.
        await montar(
          tester,
          const EdoCtaPage(emisorFiscalId: 2, titulo: 'Otros pagos'),
        );

        final Finder enLaBarra = find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.refresh),
        );
        final Finder enElVacio = find.descendant(
          of: find.byType(EdoCtaEmptyWidget),
          matching: find.byIcon(Icons.refresh),
        );
        expect(enLaBarra, findsOneWidget);
        expect(enElVacio, findsOneWidget, reason: 'no salió el estado vacío');

        await pulsar(tester, enLaBarra);
        expect(tester.takeException(), isNull);
        expect(llamadasAlServidor, 2, reason: 'el de la barra no recargó');

        await pulsar(tester, enElVacio);
        expect(tester.takeException(), isNull);
        expect(llamadasAlServidor, 3, reason: 'el del estado vacío no recargó');
      },
    );

    testWidgets('el de limpiar selección tampoco depende del provider', (
      tester,
    ) async {
      await montar(tester, const EdoCtaPage());

      // Marcar un pago para que aparezca el botón: solo se enseña cuando hay
      // algo seleccionado, que es cuando significa algo.
      await pulsar(tester, find.byType(Checkbox).first);

      final Finder limpiar = find.byIcon(Icons.clear_all);
      expect(limpiar, findsOneWidget, reason: 'no apareció al seleccionar');

      await pulsar(tester, limpiar);

      expect(tester.takeException(), isNull);
      expect(limpiar, findsNothing, reason: 'la selección no se vació');
    });
  });

  group('Carrito — botón del AppBar', () {
    testWidgets('el de vaciar abre su diálogo y vacía, sin reventar', (
      tester,
    ) async {
      // El carrito se llena desde Estados de Cuenta: se marca un pago ahí y se
      // monta el carrito, que lee la misma selección persistida.
      await montar(tester, const EdoCtaPage());
      await pulsar(tester, find.byType(Checkbox).first);

      await montar(tester, const CarritoPage());

      final Finder vaciar = find.byIcon(Icons.delete_sweep);
      expect(vaciar, findsOneWidget, reason: 'el carrito llegó vacío');

      await pulsar(tester, vaciar);
      expect(tester.takeException(), isNull);

      // Confirmar en el diálogo: es ahí donde se manda el evento al BLoC.
      await pulsar(tester, find.widgetWithText(TextButton, 'Vaciar').last);

      expect(tester.takeException(), isNull);
      expect(vaciar, findsNothing, reason: 'el carrito no se vació');
    });
  });
}
