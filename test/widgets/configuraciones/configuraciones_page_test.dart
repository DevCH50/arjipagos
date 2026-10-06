/// Tests de la pantalla de Configuraciones y de su entrada en el drawer.
///
/// Fijan la mudanza del 2026-10-06: el bloqueo biométrico salió del drawer y
/// "Calificar la app" salió del Menú Principal, y los dos viven ahora en
/// Configuraciones, que se abre desde el drawer.
library;

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/useCases/resena/AbrirFichaTiendaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/RegistrarPagoExitosoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/ResenaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/resena/SolicitarResenaUseCase.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaBloc.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaEvent.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaState.dart';
import 'package:arjipagos/src/presentation/pages/biometria/widgets/InterruptorBiometria.dart';
import 'package:arjipagos/src/presentation/pages/configuraciones/ConfiguracionesPage.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/user_drawer.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _MockBiometriaBloc extends MockBloc<BiometriaEvent, BiometriaState>
    implements BiometriaBloc {}

class _MockMenuBloc extends MockBloc<MenuPrincipalEvent, MenuPrincipalState>
    implements MenuPrincipalBloc {}

class _MockAbrirFicha extends Mock implements AbrirFichaTiendaUseCase {}

class _MockRegistrarPago extends Mock implements RegistrarPagoExitosoUseCase {}

class _MockSolicitarResena extends Mock implements SolicitarResenaUseCase {}

void main() {
  late _MockBiometriaBloc biometria;
  late _MockAbrirFicha abrirFicha;

  setUp(() {
    biometria = _MockBiometriaBloc();
    when(() => biometria.state).thenReturn(
      const BiometriaState(
        estado: EstadoBiometria(
          disponible: BiometriaDisponible.huella,
          activado: false,
        ),
      ),
    );

    abrirFicha = _MockAbrirFicha();
    when(() => abrirFicha.run()).thenAnswer((_) async {});
    locator.registerSingleton<ResenaUseCases>(
      ResenaUseCases(
        registrarPagoExitoso: _MockRegistrarPago(),
        solicitarResena: _MockSolicitarResena(),
        abrirFichaTienda: abrirFicha,
      ),
    );
  });

  tearDown(() => locator.reset());

  /// Monta la pantalla con el tema pedido, para probar claro y oscuro.
  Future<void> montar(
    WidgetTester tester, {
    Brightness brillo = Brightness.light,
  }) {
    return tester.pumpWidget(
      BlocProvider<BiometriaBloc>.value(
        value: biometria,
        child: MaterialApp(
          theme: ThemeData(brightness: brillo),
          home: const ConfiguracionesPage(),
        ),
      ),
    );
  }

  group('ConfiguracionesPage', () {
    testWidgets('muestra el título y las dos opciones', (tester) async {
      await montar(tester);

      expect(find.text(AppStrings.configuracionesTitulo), findsOneWidget);
      expect(find.byType(InterruptorBiometria), findsOneWidget);
      expect(find.text(AppStrings.biometriaTituloAjuste), findsOneWidget);
      expect(find.text(AppStrings.configuracionesCalificarApp), findsOneWidget);
    });

    testWidgets('se pinta sin errores en tema oscuro', (tester) async {
      await montar(tester, brillo: Brightness.dark);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.configuracionesCalificarApp), findsOneWidget);
    });

    testWidgets('cabe en pantalla pequeña con letra grande', (tester) async {
      // iPhone SE (320 × 568) con la letra del sistema al 130 %: el peor caso
      // de ancho. Un desbordamiento haría fallar el test con una excepción.
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await montar(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('el interruptor manda el cambio al BiometriaBloc', (
      tester,
    ) async {
      await montar(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      verify(
        () => biometria.add(const BiometriaBloqueoCambiado(activar: true)),
      ).called(1);
    });

    testWidgets('Calificar la app abre la ficha de la tienda', (tester) async {
      await montar(tester);

      await tester.tap(find.text(AppStrings.configuracionesCalificarApp));
      await tester.pump();

      verify(() => abrirFicha.run()).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('si la tienda no abre, avisa con un AlertDialog sin detalle', (
      tester,
    ) async {
      when(
        () => abrirFicha.run(),
      ).thenThrow(Exception('PlatformException(detalle técnico)'));
      await montar(tester);

      await tester.tap(find.text(AppStrings.configuracionesCalificarApp));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(AppStrings.resenaErrorAbrirTienda), findsOneWidget);
      expect(find.textContaining('detalle técnico'), findsNothing);
    });
  });

  group('UserDrawer', () {
    late _MockMenuBloc menu;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'ArjiPagos',
        packageName: 'mx.moriah.arjipagos',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      menu = _MockMenuBloc();
      when(() => menu.state).thenReturn(const MenuPrincipalState());
    });

    Future<void> montarDrawer(WidgetTester tester) {
      return tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<MenuPrincipalBloc>.value(value: menu),
            BlocProvider<BiometriaBloc>.value(value: biometria),
          ],
          child: MaterialApp(
            home: const Scaffold(drawer: UserDrawer(), body: SizedBox()),
            routes: {'configuraciones': (_) => const ConfiguracionesPage()},
          ),
        ),
      );
    }

    testWidgets('ya no lleva el interruptor biométrico, sino Configuraciones', (
      tester,
    ) async {
      await montarDrawer(tester);
      final ScaffoldState scaffold = tester.state(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(InterruptorBiometria), findsNothing);
      expect(find.text(AppStrings.configuracionesTitulo), findsOneWidget);
    });

    testWidgets('Configuraciones cierra el drawer y abre la pantalla', (
      tester,
    ) async {
      await montarDrawer(tester);
      final ScaffoldState scaffold = tester.state(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.configuracionesTitulo));
      await tester.pumpAndSettle();

      expect(find.byType(ConfiguracionesPage), findsOneWidget);
      expect(find.byType(InterruptorBiometria), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    });
  });
}
