/// Tests del cierre de un cobro de OpenPay sin retorno.
///
/// Origen: 2026-09-28. OpenPay no vuelve solo a la app: tras pagar enseña su
/// comprobante y espera a que el tutor pulse «Finalizar». Si cierra con la ✕,
/// el retorno no llega y la app no sabía qué había pasado. El backend expuso
/// `GET /api/v1/openpay/estado`, y la app lo consulta al cerrar.
///
/// Se monta `PagoWebViewPage` de verdad —con un WebView falso y dobles de los
/// servicios— dentro de una pila de navegación como la real
/// (lista del emisor → carrito → pago), para comprobar tanto el diálogo como
/// **a qué pantalla** vuelve el tutor, que es lo que decide si puede pagar dos
/// veces.
library;

import 'dart:async';

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/OpenpayService.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/EstadoCobroOpenpay.dart';
import 'package:arjipagos/src/domain/useCases/resena/AbrirFichaTiendaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/RegistrarPagoExitosoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/resena/SolicitarResenaUseCase.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/PagoWebViewPage.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/webview_scripts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../helpers/fake_webview_platform.dart';
import '../../helpers/mocks.dart';

class _MockCarritoPorEmisor extends Mock implements CarritoBlocPorEmisor {}

class _MockCarrito extends Mock implements CarritoBloc {}

class _MockListaPorEmisor extends Mock implements EdoCtaListBlocPorEmisor {}

class _MockLista extends Mock implements EdoCtaListBloc {}

class _MockRegistrarPago extends Mock implements RegistrarPagoExitosoUseCase {}

class _MockSolicitarResena extends Mock implements SolicitarResenaUseCase {}

class _MockAbrirFicha extends Mock implements AbrirFichaTiendaUseCase {}

/// Ruta de la lista de «Otros pagos» (emisor 2), a la que se vuelve cuando
/// el cobro terminó o puede que se cobrara.
const String _rutaLista = 'edo_cta_otros';
const String _rutaCarrito = 'carrito';
const String _orderId = '30543A0-N1790615526093';

void main() {
  late FakeWebViewPlatform webview;
  late MockOpenpayService openpay;
  late _MockCarrito carrito;
  late _MockLista lista;
  final navegador = GlobalKey<NavigatorState>();

  setUpAll(() {
    registerFallbackValue(const CarritoInitialEvent());
    registerFallbackValue(const EdoCtaListRefreshEvent());
  });

  setUp(() {
    webview = FakeWebViewPlatform();
    WebViewPlatform.instance = webview;

    openpay = MockOpenpayService();
    carrito = _MockCarrito();
    lista = _MockLista();

    final carritos = _MockCarritoPorEmisor();
    when(() => carritos.de(any())).thenReturn(carrito);
    final listas = _MockListaPorEmisor();
    when(() => listas.de(any())).thenReturn(lista);

    final registrar = _MockRegistrarPago();
    when(() => registrar.run()).thenAnswer((_) async {});
    final solicitar = _MockSolicitarResena();
    when(() => solicitar.run()).thenAnswer((_) async => false);

    locator
      ..registerSingleton<OpenpayService>(openpay)
      ..registerSingleton<CarritoBlocPorEmisor>(carritos)
      ..registerSingleton<EdoCtaListBlocPorEmisor>(listas)
      ..registerSingleton<ResenaUseCases>(
        ResenaUseCases(
          registrarPagoExitoso: registrar,
          solicitarResena: solicitar,
          abrirFichaTienda: _MockAbrirFicha(),
        ),
      );
  });

  tearDown(() => locator.reset());

  /// Deja pasar las animaciones de rutas y diálogos.
  ///
  /// **Nunca `pumpAndSettle`**: la página falsa no avisa de que terminó de
  /// cargar, así que el indicador de carga del WebView gira para siempre y
  /// `pumpAndSettle` no volvería nunca.
  Future<void> asentar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  void responde(EstadoCobroOpenpay estado) {
    when(() => openpay.verificarCobro(any())).thenAnswer((_) async => estado);
  }

  /// Lista del emisor 2 → carrito → pago, como en la app.
  ///
  /// [orderId] `null` es un cobro de Adquira: no hay estado que consultar.
  Future<void> abrirPago(WidgetTester tester, {String? orderId = _orderId}) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegador,
        initialRoute: _rutaLista,
        onGenerateRoute: (ajustes) => MaterialPageRoute<void>(
          settings: ajustes,
          builder: (_) => ajustes.name == 'pago_webview'
              ? const PagoWebViewPage()
              : Scaffold(body: Text(ajustes.name!)),
        ),
      ),
    );
    navegador.currentState!.pushNamed(_rutaCarrito);
    navegador.currentState!.pushNamed(
      'pago_webview',
      arguments: PagoWebViewArgs(
        url: 'https://sandbox-api.openpay.mx/checkout/abc',
        params: const {},
        token: 'token',
        emisorFiscalId: 2,
        orderId: orderId,
      ),
    );
    await asentar(tester);
  }

  Future<void> cerrarConLaX(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.close));
    await asentar(tester);
  }

  Future<void> aceptar(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.accept));
    await asentar(tester);
  }

  group('Cerrar con la ✕ un cobro de OpenPay', () {
    testWidgets('consulta el estado con su order_id y NO pregunta «¿cancelar?»', (
      tester,
    ) async {
      responde(const EstadoCobroOpenpay(EstadoCobro.pendiente));
      await abrirPago(tester);

      await cerrarConLaX(tester);

      verify(() => openpay.verificarCobro(_orderId)).called(1);
      expect(find.text(AppStrings.pagoCancelarTitle), findsNothing);
    });

    testWidgets('suelta el foco del formulario para que se vaya el teclado', (
      tester,
    ) async {
      // Visto en el Oppo: cerrando mientras se tecleaba la tarjeta, el teclado
      // se quedaba abierto encima de «Confirmando tu pago…» y del diálogo.
      responde(const EstadoCobroOpenpay(EstadoCobro.pendiente));
      final ocultados = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (llamada) async {
          ocultados.add(llamada.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          null,
        ),
      );
      await abrirPago(tester);

      await cerrarConLaX(tester);

      expect(webview.scripts, contains(WebViewScripts.soltarFoco));
      expect(ocultados, contains('TextInput.hide'));
    });

    testWidgets('pagado: diálogo de éxito, carrito vaciado y vuelta a la lista', (
      tester,
    ) async {
      responde(const EstadoCobroOpenpay(EstadoCobro.pagado));
      await abrirPago(tester);

      await cerrarConLaX(tester);
      expect(find.text(AppStrings.pagoExitosoTitle), findsOneWidget);
      await aceptar(tester);

      verify(() => carrito.add(const CarritoPagoExitosoEvent())).called(1);
      verify(() => lista.add(const EdoCtaListRefreshEvent())).called(1);
      expect(find.text(_rutaLista), findsOneWidget);
    });

    testWidgets('rechazado: enseña el motivo y vuelve al carrito con todo', (
      tester,
    ) async {
      responde(
        const EstadoCobroOpenpay(
          EstadoCobro.rechazado,
          mensaje: 'La tarjeta fue declinada.',
        ),
      );
      await abrirPago(tester);

      await cerrarConLaX(tester);
      expect(find.text(AppStrings.openpayRechazadoTitle), findsOneWidget);
      expect(find.text('La tarjeta fue declinada.'), findsOneWidget);
      // Sin «Reintentar»: se vuelve a pagar desde el carrito, con otro cobro.
      expect(find.text(AppStrings.retry), findsNothing);
      await aceptar(tester);

      expect(find.text(_rutaCarrito), findsOneWidget);
      verify(() => carrito.add(const CarritoCancelarPagoEvent())).called(1);
      verifyNever(() => carrito.add(const CarritoLimpiarEvent()));
    });

    testWidgets('pendiente: «No se completó» y vuelve al carrito con todo', (
      tester,
    ) async {
      responde(const EstadoCobroOpenpay(EstadoCobro.pendiente));
      await abrirPago(tester);

      await cerrarConLaX(tester);
      expect(find.text(AppStrings.openpayNoCompletadoTitle), findsOneWidget);
      await aceptar(tester);

      expect(find.text(_rutaCarrito), findsOneWidget);
      verifyNever(() => carrito.add(const CarritoLimpiarEvent()));
    });

    testWidgets(
      'sin confirmar: advierte, vacía el carrito y vuelve a la lista recargada',
      (tester) async {
        responde(
          const EstadoCobroOpenpay.sinConfirmar(
            mensaje: 'NO vuelvas a pagar; revisa en unos minutos.',
          ),
        );
        await abrirPago(tester);

        await cerrarConLaX(tester);
        expect(find.text(AppStrings.openpaySinConfirmarTitle), findsOneWidget);
        expect(
          find.text('NO vuelvas a pagar; revisa en unos minutos.'),
          findsOneWidget,
        );
        await aceptar(tester);

        // Sin un «Pagar» delante con los mismos cargos: no hay pago doble.
        verify(() => carrito.add(const CarritoLimpiarEvent())).called(1);
        verify(() => lista.add(const EdoCtaListRefreshEvent())).called(1);
        expect(find.text(_rutaLista), findsOneWidget);
      },
    );

    testWidgets('mientras consulta, tapa el WebView y no repite la consulta', (
      tester,
    ) async {
      final respuesta = Completer<EstadoCobroOpenpay>();
      when(
        () => openpay.verificarCobro(any()),
      ).thenAnswer((_) => respuesta.future);
      await abrirPago(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text(AppStrings.openpayVerificando), findsOneWidget);

      // Un segundo toque —impaciencia— no lanza otra consulta.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      verify(() => openpay.verificarCobro(any())).called(1);

      respuesta.complete(const EstadoCobroOpenpay(EstadoCobro.pendiente));
      await asentar(tester);
      expect(find.text(AppStrings.openpayNoCompletadoTitle), findsOneWidget);
    });

    testWidgets('el botón atrás del sistema hace lo mismo que la ✕', (
      tester,
    ) async {
      responde(const EstadoCobroOpenpay(EstadoCobro.pendiente));
      await abrirPago(tester);

      await tester.binding.handlePopRoute();
      await asentar(tester);

      verify(() => openpay.verificarCobro(_orderId)).called(1);
      expect(find.text(AppStrings.openpayNoCompletadoTitle), findsOneWidget);
    });
  });

  group('El retorno de OpenPay', () {
    testWidgets('con éxito no hace falta consultar nada', (tester) async {
      await abrirPago(tester);

      webview.enviarPorCanal(
        'PagoResultado',
        '{"success":true,"message":"Pagos agregados correctamente"}',
      );
      await asentar(tester);

      expect(find.text(AppStrings.pagoExitosoTitle), findsOneWidget);
      verifyNever(() => openpay.verificarCobro(any()));
    });

    testWidgets('fallido NO se cree: manda el estado del cobro', (tester) async {
      // «Pagaste pero no identificamos los cargos» llega con success: false,
      // y el dinero sí salió. Decir «Error en el pago» empujaría a pagar dos
      // veces; el estado dice la verdad.
      responde(const EstadoCobroOpenpay.sinConfirmar());
      await abrirPago(tester);

      webview.enviarPorCanal(
        'PagoResultado',
        '{"success":false,"message":"No identificamos los cargos"}',
      );
      await asentar(tester);

      verify(() => openpay.verificarCobro(_orderId)).called(1);
      expect(find.text(AppStrings.pagoErrorTitle), findsNothing);
      expect(find.text(AppStrings.openpaySinConfirmarTitle), findsOneWidget);
    });
  });

  group('Adquira no cambia', () {
    testWidgets('la ✕ sigue preguntando «¿cancelar?» y no consulta nada', (
      tester,
    ) async {
      await abrirPago(tester, orderId: null);

      await cerrarConLaX(tester);

      expect(find.text(AppStrings.pagoCancelarTitle), findsOneWidget);
      verifyNever(() => openpay.verificarCobro(any()));
    });

    testWidgets('un retorno fallido sigue ofreciendo «Reintentar»', (
      tester,
    ) async {
      await abrirPago(tester, orderId: null);

      webview.enviarPorCanal(
        'PagoResultado',
        '{"success":false,"message":"Tarjeta rechazada"}',
      );
      await asentar(tester);

      expect(find.text(AppStrings.pagoErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      verify(
        () => carrito.add(const CarritoPagoFallidoEvent('Tarjeta rechazada')),
      ).called(1);
      verifyNever(() => openpay.verificarCobro(any()));
    });

    testWidgets(
      'el código 5 no es un rechazo: sin «Reintentar», vacía y va a la lista',
      (tester) async {
        // «Ya se encuentra un pago con esa referencia»: lo más probable es que
        // se cobrara antes y el aviso no llegara. Con «Reintentar» delante, el
        // tutor seguiría intentando pagar algo que quizá ya pagó.
        await abrirPago(tester, orderId: null);

        webview.enviarPorCanal(
          'PagoResultado',
          '{"success":false,"codigo":5,'
              '"message":"Ya se encuentra un pago con esa referencia"}',
        );
        await asentar(tester);

        expect(find.text(AppStrings.adquiraReferenciaUsadaTitle), findsOneWidget);
        expect(find.text(AppStrings.adquiraReferenciaUsadaMsg), findsOneWidget);
        expect(find.text(AppStrings.pagoErrorTitle), findsNothing);
        expect(find.text(AppStrings.retry), findsNothing);

        await aceptar(tester);

        verify(() => carrito.add(const CarritoLimpiarEvent())).called(1);
        verify(() => lista.add(const EdoCtaListRefreshEvent())).called(1);
        expect(find.text(_rutaLista), findsOneWidget);
        verifyNever(() => openpay.verificarCobro(any()));
      },
    );
  });
}
