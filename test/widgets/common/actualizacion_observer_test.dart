// Test de widget: ActualizacionObserver
//
// Test de regresión de un fallo visto en el Oppo el 2026-08-21: el diálogo de
// actualización aparecía y se desvanecía solo un segundo después, dejando al
// usuario dentro de la app con una versión obsoleta.
//
// La causa era el splash: al terminar navega con
// `restorablePushNamedAndRemoveUntil(..., (route) => false)`, y ese predicado
// retira *todas* las rutas de la pila — la del diálogo incluida. El observador
// no se enteraba porque para él el diálogo simplemente "se había cerrado".
//
// ## Por qué el BLoC se crea dentro de cada prueba
//
// `testWidgets` corre el cuerpo dentro de una zona `FakeAsync`. Un BLoC creado
// en `setUp` nace en la zona de fuera, y entonces sus eventos no se entregan
// hasta que la prueba termina: el diálogo aparecía después de los `expect`, y
// esperar a su `close()` dejaba el runner colgado. Todo se construye aquí
// dentro, ya en la zona correcta.

import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/domain/useCases/version/VersionUseCases.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionBloc.dart';
import 'package:arjipagos/src/presentation/utils/AppNavigatorKey.dart';
import 'package:arjipagos/src/presentation/widgets/ActualizacionObserver.dart';
import 'package:arjipagos/src/presentation/widgets/ActualizacionRequeridaDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  const obligatoria = ResultadoActualizacion(
    estado: EstadoActualizacion.obligatoria,
    mensaje: 'Actualiza para seguir usando ArjiPagos',
    urlTienda: 'https://play.google.com/store/apps/details?id=x',
  );

  const sugerida = ResultadoActualizacion(
    estado: EstadoActualizacion.sugerida,
    mensaje: 'Hay una versión nueva',
    urlTienda: 'https://play.google.com/store/apps/details?id=x',
  );

  /// Monta la app igual que `main.dart` —el observador en el `builder` de
  /// `MaterialApp`, por encima del Navigator— y devuelve el BLoC en uso.
  Future<ActualizacionBloc> montarApp(
    WidgetTester tester,
    ResultadoActualizacion veredicto,
  ) async {
    final mockVerificar = MockVerificarActualizacionUseCase();
    when(() => mockVerificar.run()).thenAnswer((_) async => veredicto);

    final sharedPref = MockSharedPref();
    when(() => sharedPref.read(any())).thenAnswer((_) async => null);
    when(() => sharedPref.save(any(), any())).thenAnswer((_) async {});

    final bloc = ActualizacionBloc(
      VersionUseCases(verificarActualizacion: mockVerificar),
      sharedPref,
    );

    await tester.pumpWidget(
      BlocProvider<ActualizacionBloc>.value(
        value: bloc,
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          builder: (context, child) => ActualizacionObserver(child: child!),
          routes: {
            '/': (_) => const Scaffold(body: Text('splash')),
            'login': (_) => const Scaffold(body: Text('login')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    return bloc;
  }

  /// Reproduce el salto del splash: retira todas las rutas y deja el login.
  Future<void> saltoDelSplash(WidgetTester tester) async {
    appNavigatorKey.currentState!
        .pushNamedAndRemoveUntil('login', (route) => false);
    await tester.pumpAndSettle();

    // El observador espera a que la navegación acabe antes de reabrir el
    // diálogo; hay que dejar correr ese margen.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('levanta el diálogo al arrancar, sin necesidad de sesión',
      (tester) async {
    await montarApp(tester, obligatoria);

    expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);
  });

  testWidgets('el bloqueo sobrevive al salto del splash', (tester) async {
    await montarApp(tester, obligatoria);
    expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);

    await saltoDelSplash(tester);

    // Antes del arreglo, aquí el diálogo ya no estaba.
    expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('un aviso descartable también sobrevive al salto',
      (tester) async {
    await montarApp(tester, sugerida);

    await saltoDelSplash(tester);

    expect(find.byType(ActualizacionRequeridaDialog), findsOneWidget);
  });

  testWidgets('si el usuario lo descarta, NO se vuelve a abrir',
      (tester) async {
    final bloc = await montarApp(tester, sugerida);

    // El atrás cierra un aviso descartable, y eso sí es voluntad del usuario.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ActualizacionRequeridaDialog), findsNothing);
    expect(bloc.state.resultado.estado, EstadoActualizacion.ninguna);

    // Ni siquiera una navegación posterior debe resucitarlo.
    await saltoDelSplash(tester);
    expect(find.byType(ActualizacionRequeridaDialog), findsNothing);
  });

  testWidgets('sin actualización pendiente no molesta a nadie',
      (tester) async {
    await montarApp(tester, ResultadoActualizacion.sinCambios);

    expect(find.byType(ActualizacionRequeridaDialog), findsNothing);
  });
}
