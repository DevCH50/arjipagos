/// Tests de widget para NotificacionDetalleWidget.
///
/// Verifica:
/// - Que el contenido HTML se renderiza con `HtmlWidget` sin lanzar excepción
///   (blinda `flutter_widget_from_html_core` / `xml` ante breaking changes).
/// - Que al abrir el detalle se despacha MarcarLeidaEvent solo si la
///   notificación no estaba leída.
///
/// Se usa un MockBloc (bloc_test) para observar los eventos despachados sin
/// depender de la lógica interna del NotificacionBloc real.
library;

import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_detalle_widget.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificacionBloc
    extends MockBloc<NotificacionEvent, NotificacionState>
    implements NotificacionBloc {}

Notificacion _notif({required bool isRead, String mensaje = 'Mensaje simple'}) =>
    Notificacion(
      id: 1,
      userId: 10,
      titulo: 'Título de prueba',
      mensaje: mensaje,
      campania: 'estado_cuenta',
      fecha: DateTime(2026, 4, 8, 14, 30),
      isRead: isRead,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const MarcarLeidaEvent(id: 0));
  });

  late MockNotificacionBloc bloc;

  setUp(() {
    bloc = MockNotificacionBloc();
    whenListen(
      bloc,
      const Stream<NotificacionState>.empty(),
      initialState: const NotificacionState(),
    );
  });

  Future<void> montar(WidgetTester tester, Notificacion notificacion) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<NotificacionBloc>.value(
            value: bloc,
            child: NotificacionDetalleWidget(notificacion: notificacion),
          ),
        ),
      ),
    );
  }

  group('renderizado', () {
    testWidgets('muestra el título y renderiza el HTML con HtmlWidget',
        (tester) async {
      await montar(
        tester,
        _notif(
          isRead: true,
          mensaje: '<h3>Aviso</h3><p>Tu pago ha <b>vencido</b></p>',
        ),
      );
      await tester.pump();

      expect(find.text('Título de prueba'), findsOneWidget);
      // El HTML se renderiza mediante HtmlWidget (no lanza al parsear).
      expect(find.byType(HtmlWidget), findsOneWidget);
    });
  });

  group('marcar como leída al abrir', () {
    testWidgets('despacha MarcarLeidaEvent cuando la notificación NO está leída',
        (tester) async {
      final notificacion = _notif(isRead: false);

      await montar(tester, notificacion);
      await tester.pump(); // ejecuta el addPostFrameCallback

      verify(() => bloc.add(MarcarLeidaEvent(id: notificacion.id))).called(1);
    });

    testWidgets('NO despacha ningún evento cuando ya estaba leída',
        (tester) async {
      await montar(tester, _notif(isRead: true));
      await tester.pump();

      verifyNever(() => bloc.add(any()));
    });
  });
}
