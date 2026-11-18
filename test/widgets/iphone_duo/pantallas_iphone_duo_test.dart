/// Las pantallas de la app, montadas a los dos tamaños del **iPhone Duo**.
///
/// **Por qué existe.** Desde abril de 2027 App Store Connect exige capturas del
/// Duo, y al compilar con el SDK de iOS 27.1 la app ocupará su pantalla entera:
/// la exterior (~466 pt de ancho) y la interior (~669 pt, casi cuadrada). Esta
/// Mac no puede correr Xcode 27, así que no hay simulador; lo que sí se puede
/// comprobar desde ya es que ninguna pantalla se desborda a esos tamaños.
///
/// Cada pantalla se monta en las dos pantallas del Duo, en tema claro y oscuro,
/// y con la letra del sistema al 100 % y al 130 %. Un `RenderFlex overflowed`
/// hace fallar el caso con `takeException`. Además se busca lo esencial de la
/// pantalla, para que una que se pinte en blanco no pase por buena.
///
/// **Lo que NO prueba:** cómo trata iOS 27.1 a una app fija en vertical en el
/// Duo, el redimensionado en vivo al plegar, ni que se vea bien estirada. Eso
/// queda para el simulador, en una Mac con Apple silicon.
///
/// Los BLoC de datos van con `MockBloc` y un estado ya cargado, salvo Estados de
/// Cuenta y Carrito, que usan los de verdad con el registro por emisor —como en
/// `test/unit/appbar_encuentra_su_bloc_test.dart`—, porque su contenido depende
/// de la selección persistida.
library;

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/models/Factura.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/useCases/resena/AbrirFichaTiendaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/RegistrarPagoExitosoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/resena/SolicitarResenaUseCase.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/LoginPage.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginEvent.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerBloc.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerState.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaBloc.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaEvent.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaState.dart';
import 'package:arjipagos/src/presentation/pages/carrito/CarritoPage.dart';
import 'package:arjipagos/src/presentation/pages/configuraciones/ConfiguracionesPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/EdoCtaPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/EdoCtaPagadosPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:arjipagos/src/presentation/pages/facturas/FacturasPage.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/MenuPrincipalPage.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/NotificacionesPage.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pantallas_iphone_duo.dart';
import '../../helpers/test_data.dart';

class _MockMenuBloc extends MockBloc<MenuPrincipalEvent, MenuPrincipalState>
    implements MenuPrincipalBloc {}

class _MockPagadosBloc extends MockBloc<EdoCtaPagadosEvent, EdoCtaPagadosState>
    implements EdoCtaPagadosBloc {}

class _MockNotificacionBloc
    extends MockBloc<NotificacionEvent, NotificacionState>
    implements NotificacionBloc {}

class _MockBannerBloc extends MockBloc<BannerEvent, BannerState>
    implements BannerBloc {}

class _MockFacturaBloc extends MockBloc<FacturaEvent, FacturaState>
    implements FacturaBloc {}

class _MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class _MockBiometriaBloc extends MockBloc<BiometriaEvent, BiometriaState>
    implements BiometriaBloc {}

class _MockAbrirFicha extends Mock implements AbrirFichaTiendaUseCase {}

class _MockRegistrarPago extends Mock implements RegistrarPagoExitosoUseCase {}

class _MockSolicitarResena extends Mock implements SolicitarResenaUseCase {}

/// Concepto largo, como los que manda el backend: es lo que más fácil desborda.
const String _conceptoLargo =
    'REINSCRIPCION SECUNDARIA 26 / 27 EXTENSION DE HORARIO';

/// Un pago ya liquidado, para Pagos Realizados.
EstadoDeCuenta _pagoRealizado(int id) => EstadoDeCuenta(
  id: id,
  cicloId: TestEstadoDeCuenta.cicloActual,
  emisorFiscalId: 1,
  descripcionCorta: _conceptoLargo,
  total: 9770.0,
  totalFormatted: r'$9,770.00',
  fechaVencimiento: '2026-06-30',
  estadoPago: EstadoPago.pagado,
  numPago: 1,
  aceptaPagosDiversos: false,
  estaDisponibleEnInternet: true,
  fechaDePago: '2026-06-15',
  ticketFolio: 'T$id',
);

void main() {
  late MockSharedPref sharedPref;
  late MockGetEstadosDeCuentaUseCase getEstadosDeCuenta;

  setUp(() {
    // `SharedPref` con memoria: el carrito lee la selección que deja escrita
    // Estados de Cuenta.
    sharedPref = MockSharedPref();
    final Map<String, Map<String, dynamic>> almacen = {};
    when(
      () => sharedPref.readMap(any()),
    ).thenAnswer((i) async => almacen[i.positionalArguments.first]);
    when(() => sharedPref.save(any(), any())).thenAnswer((i) async {
      almacen[i.positionalArguments[0] as String] =
          i.positionalArguments[1] as Map<String, dynamic>;
    });

    getEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();
    final Alumno alumno = alumnoConPagos(1, [
      pagoDePrueba(id: 10, pagoId: 900, descripcionCorta: _conceptoLargo),
      pagoDePrueba(id: 11, pagoId: 900, numPago: 2),
    ]);
    when(
      () =>
          getEstadosDeCuenta.run(emisorFiscalId: any(named: 'emisorFiscalId')),
    ).thenAnswer(
      (_) async => Success(
        EstadosDeCuentaResponse(
          alumnos: [alumno],
          familia: 'Familia Hidalgo Ruiz',
          success: true,
          message: '',
        ),
      ),
    );
  });

  tearDown(() => locator.reset());

  /// Registra el registro por emisor con mocks, como lo arma `AppModule`.
  ///
  /// Se llama **dentro** del `testWidgets`: un BLoC creado en `setUp` nace
  /// fuera de la zona `FakeAsync` y su carga inicial no se resuelve nunca.
  void registrarEmisores() {
    final storages = SeleccionPagosStoragePorEmisor(sharedPref);
    locator.registerSingleton<SharedPref>(sharedPref);
    locator.registerSingleton<SeleccionPagosStoragePorEmisor>(storages);
    locator.registerSingleton<EdoCtaListBlocPorEmisor>(
      EdoCtaListBlocPorEmisor(
        createMockEdoCtaUseCases(getEstadosDeCuenta: getEstadosDeCuenta),
        storages,
      ),
    );
    locator.registerSingleton<CarritoBlocPorEmisor>(
      CarritoBlocPorEmisor(
        createMockAuthUseCases(),
        createMockEdoCtaUseCases(getEstadosDeCuenta: getEstadosDeCuenta),
        storages,
        MockOpenpayService(),
      ),
    );
  }

  /// Los BLoC de la raíz, ya cargados, para las pantallas que los leen con
  /// `context.read`.
  List<BlocProvider> blocsDeLaRaiz({bool conAvisos = false}) {
    final menu = _MockMenuBloc();
    whenListen(
      menu,
      const Stream<MenuPrincipalState>.empty(),
      initialState: MenuPrincipalState(
        nombreUsuario: 'Carlos Manuel Hidalgo Ruiz',
        emailUsuario: 'tutor.de.prueba@colegio.edu.mx',
        user: TestUser.valid,
        menuItems: MenuPrincipalState.defaultMenuItems,
      ),
    );

    final pagados = _MockPagadosBloc();
    whenListen(
      pagados,
      const Stream<EdoCtaPagadosState>.empty(),
      initialState: EdoCtaPagadosState(
        alumnos: [
          TestAlumno.activo.conEstadoDeCuenta([
            _pagoRealizado(20),
            _pagoRealizado(21),
          ]),
        ],
      ),
    );

    final notificaciones = _MockNotificacionBloc();
    whenListen(
      notificaciones,
      const Stream<NotificacionState>.empty(),
      initialState: NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        noLeidas: 1,
        hayMas: false,
      ),
    );

    final banners = _MockBannerBloc();
    whenListen(
      banners,
      const Stream<BannerState>.empty(),
      // Con avisos el carrusel ocupa su alto real y le quita sitio al menú,
      // que es justo lo que hay que medir en pantalla pequeña.
      initialState: conAvisos
          ? BannerState(banners: [BannerInfo.fromJson(TestBanner.anualidadJson)])
          : const BannerState(),
    );

    final facturas = _MockFacturaBloc();
    final List<Factura> lista = [
      Factura(
        id: 1,
        folio: 'A-000123',
        fecha: '2026-09-01',
        fechaTimbrado: '2026-09-01 10:15:00',
        referencia: 'REF-0001',
        total: r'$9,770.00',
        zipUrl: '',
        zipNombre: 'factura.zip',
      ),
    ];
    whenListen(
      facturas,
      const Stream<FacturaState>.empty(),
      initialState: FacturaState(
        isLoading: false,
        facturas: lista,
        response: FacturaResponse(
          familia: 'Familia Hidalgo Ruiz',
          facturas: lista,
          success: true,
          message: '',
        ),
      ),
    );

    final login = _MockLoginBloc();
    whenListen(
      login,
      const Stream<LoginState>.empty(),
      initialState: const LoginState(),
    );

    final biometria = _MockBiometriaBloc();
    whenListen(
      biometria,
      const Stream<BiometriaState>.empty(),
      initialState: const BiometriaState(
        estado: EstadoBiometria(
          disponible: BiometriaDisponible.rostro,
          activado: false,
        ),
      ),
    );

    return [
      BlocProvider<MenuPrincipalBloc>.value(value: menu),
      BlocProvider<EdoCtaPagadosBloc>.value(value: pagados),
      BlocProvider<NotificacionBloc>.value(value: notificaciones),
      BlocProvider<BannerBloc>.value(value: banners),
      BlocProvider<FacturaBloc>.value(value: facturas),
      BlocProvider<LoginBloc>.value(value: login),
      BlocProvider<BiometriaBloc>.value(value: biometria),
    ];
  }

  /// Monta [pantalla] con el tema de la app y deja que se asiente.
  ///
  /// Pulsos con reloj y nunca `pumpAndSettle`: Estados de Cuenta tiene una
  /// animación perpetua —el punto del alumno— y no se asentaría nunca.
  Future<void> montar(
    WidgetTester tester,
    Widget pantalla, {
    required ThemeData tema,
    bool conAvisos = false,
  }) async {
    if (!locator.isRegistered<EdoCtaListBlocPorEmisor>()) {
      registrarEmisores();
      locator.registerSingleton<ResenaUseCases>(
        ResenaUseCases(
          registrarPagoExitoso: _MockRegistrarPago(),
          solicitarResena: _MockSolicitarResena(),
          abrirFichaTienda: _MockAbrirFicha(),
        ),
      );
    }
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: blocsDeLaRaiz(conAvisos: conAvisos),
        child: MaterialApp(theme: tema, home: pantalla),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Cada pantalla, con el texto que demuestra que se pintó de verdad.
  ///
  /// `marcarPago` llena el carrito antes: se marca un pago en Estados de Cuenta,
  /// igual que lo haría el usuario, porque el carrito vacío no prueba nada.
  final List<
    ({String nombre, Widget pantalla, String esperado, bool marcarPago})
  >
  pantallas = [
    (
      nombre: 'Login',
      pantalla: const LoginPage(),
      esperado: AppStrings.loginIniciarSesion,
      marcarPago: false,
    ),
    (
      nombre: 'Menú Principal',
      pantalla: const MenuPrincipalPage(),
      esperado: AppStrings.menuPagosPendientes,
      marcarPago: false,
    ),
    (
      nombre: 'Estados de Cuenta (emisor 1)',
      pantalla: const EdoCtaPage(),
      esperado: AppStrings.edoCtaTitle,
      marcarPago: false,
    ),
    (
      nombre: 'Otros pagos (emisor 2, vacío)',
      pantalla: const EdoCtaPage(
        emisorFiscalId: 2,
        titulo: AppStrings.menuOtrosPagos,
      ),
      esperado: AppStrings.menuOtrosPagos,
      marcarPago: false,
    ),
    (
      nombre: 'Carrito',
      pantalla: const CarritoPage(),
      esperado: AppStrings.carritoTitle,
      marcarPago: true,
    ),
    (
      nombre: 'Pagos Realizados',
      pantalla: const EdoCtaPagadosPage(),
      esperado: AppStrings.edoCtaPagadosTitle,
      marcarPago: false,
    ),
    (
      nombre: 'Facturas',
      pantalla: const FacturasPage(),
      esperado: 'A-000123',
      marcarPago: false,
    ),
    (
      nombre: 'Notificaciones',
      pantalla: const NotificacionesPage(),
      esperado: TestNotificacion.noLeida.titulo,
      marcarPago: false,
    ),
    (
      nombre: 'Configuraciones',
      pantalla: const ConfiguracionesPage(),
      esperado: AppStrings.configuracionesCalificarApp,
      marcarPago: false,
    ),
  ];

  // Funciones y no los temas ya hechos: `AppTheme` carga la fuente con
  // `google_fonts`, que necesita el binding del test, y éste no existe todavía
  // mientras se declaran los casos.
  final Map<String, ThemeData Function()> temas = {
    'claro': () => AppTheme.light,
    'oscuro': () => AppTheme.dark,
  };

  for (final PantallaDuo duo in kPantallasDuo) {
    group('iPhone Duo, pantalla ${duo.nombre} '
        '(${duo.tamanoLogico.width.round()} × '
        '${duo.tamanoLogico.height.round()} pt)', () {
      for (final p in pantallas) {
        for (final MapEntry<String, ThemeData Function()> tema
            in temas.entries) {
          for (final double escala in const [1.0, 1.3]) {
            testWidgets(
              '${p.nombre}, tema ${tema.key}, letra al ${(escala * 100).round()} %',
              (tester) async {
                fijarPantalla(tester, duo, escalaTexto: escala);

                if (p.marcarPago) {
                  await montar(tester, const EdoCtaPage(), tema: tema.value());
                  await tester.tap(find.byType(Checkbox).first);
                  await tester.pump(const Duration(seconds: 1));
                }
                await montar(tester, p.pantalla, tema: tema.value());

                expect(tester.takeException(), isNull);
                expect(
                  find.text(p.esperado),
                  findsWidgets,
                  reason: 'la pantalla no pintó su contenido',
                );
              },
            );
          }
        }
      }
    });
  }

  // ==========================================================================
  // PANTALLA PEQUEÑA — el otro extremo
  // ==========================================================================

  /// 360 × 640 dp, como el emulador de Android 7 (perfil Nexus 5). Ahí se vio
  /// el 2026-11-18 que el menú escondía «Pagos Realizados» y «Facturas» en una
  /// franja desplazable, y el lateral escondía «Cerrar Sesión», sin ninguna
  /// pista visual de que existían.
  const PantallaDuo pequena = PantallaDuo('pequeña', Size(1080, 1920));

  /// Que se vea entero sin desplazar nada: dentro de la pantalla **y** dentro
  /// de la zona visible de la lista que lo contiene. Lo segundo es lo que
  /// importa: antes las opciones escondidas quedaban debajo del carrusel, dentro
  /// de la pantalla pero fuera de la franja visible de su lista.
  void expectVisible(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    final String texto = (finder.evaluate().first.widget as Text).data!;
    final Rect r = tester.getRect(finder);
    double limite = pequena.tamanoLogico.height;
    final Finder lista =
        find.ancestor(of: finder, matching: find.byType(Scrollable));
    if (lista.evaluate().isNotEmpty) {
      final double finLista = tester.getRect(lista.first).bottom;
      if (finLista < limite) {
        limite = finLista;
      }
    }
    expect(r.bottom, lessThanOrEqualTo(limite),
        reason: '«$texto» queda fuera de la zona visible');
  }

  group('Pantalla pequeña (360 × 640 dp)', () {
    for (final MapEntry<String, ThemeData Function()> tema in temas.entries) {
      testWidgets('Menú: las cuatro opciones a la vista, tema ${tema.key}',
          (tester) async {
        fijarPantalla(tester, pequena);
        await montar(tester, const MenuPrincipalPage(),
            tema: tema.value(), conAvisos: true);

        expect(tester.takeException(), isNull);
        for (final item in MenuPrincipalState.defaultMenuItems) {
          expectVisible(tester, find.text(item.titulo));
        }
      });

      testWidgets('Menú lateral: «Cerrar Sesión» a la vista, tema ${tema.key}',
          (tester) async {
        fijarPantalla(tester, pequena);
        await montar(tester, const MenuPrincipalPage(),
            tema: tema.value(), conAvisos: true);

        await tester.tap(find.byTooltip(AppStrings.menuMiCuenta));
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        expectVisible(tester, find.text(AppStrings.logoutTitle));
      });
    }

    testWidgets('Menú con letra al 130 %: «Facturas» se alcanza desplazando',
        (tester) async {
      fijarPantalla(tester, pequena, escalaTexto: 1.3);
      await montar(tester, const MenuPrincipalPage(),
          tema: AppTheme.light, conAvisos: true);

      final String ultima = MenuPrincipalState.defaultMenuItems.last.titulo;
      await tester.scrollUntilVisible(find.text(ultima), 100,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
      expectVisible(tester, find.text(ultima));
    });
  });
}
