/// Tests de widget para NotificacionItemWidget.
///
/// Verifica:
/// - Renderizado correcto de título y mensaje en texto plano (sin HTML).
/// - Indicadores visuales para notificaciones leídas y no leídas.
/// - Fecha relativa en el trailing.
/// - Callback onTap se invoca al presionar.
library;

import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Crea un widget bajo prueba envuelto en MaterialApp + Scaffold.
  Widget crearWidget({
    required Notificacion notificacion,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: NotificacionItemWidget(
          notificacion: notificacion,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  /// Notificación de prueba no leída con HTML en título y mensaje.
  Notificacion notificacionNoLeida({
    String titulo = '<b>Estado de Cuenta Vencido</b>',
    String mensaje = '<h3>Tu pago ha vencido</h3><p>Fecha l&iacute;mite: <b>15 de abril</b></p>',
  }) {
    return Notificacion(
      id: 1,
      userId: 10,
      titulo: titulo,
      mensaje: mensaje,
      campania: 'estado_cuenta',
      fecha: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    );
  }

  /// Notificación de prueba ya leída con texto plano.
  Notificacion notificacionLeida() {
    return Notificacion(
      id: 2,
      userId: 10,
      titulo: 'Notificación leída',
      mensaje: 'Este mensaje ya fue leído.',
      campania: 'manual',
      fecha: DateTime.now().subtract(const Duration(hours: 25)),
      isRead: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Renderizado de texto plano (HTML stripping)
  // ---------------------------------------------------------------------------
  group('strip HTML en título y mensaje', () {
    testWidgets('muestra título sin etiquetas HTML', (tester) async {
      await tester.pumpWidget(crearWidget(
        notificacion: notificacionNoLeida(titulo: '<b>Estado de Cuenta Vencido</b>'),
      ));

      expect(find.text('Estado de Cuenta Vencido'), findsOneWidget);
      expect(find.textContaining('<b>'), findsNothing);
    });

    testWidgets('muestra mensaje sin etiquetas HTML', (tester) async {
      await tester.pumpWidget(crearWidget(
        notificacion: notificacionNoLeida(
          mensaje: '<h3>Tu pago ha vencido</h3>',
        ),
      ));

      expect(find.text('Tu pago ha vencido'), findsOneWidget);
      expect(find.textContaining('<h3>'), findsNothing);
    });

    testWidgets('decodifica entidades HTML españolas en mensaje', (tester) async {
      await tester.pumpWidget(crearWidget(
        notificacion: notificacionNoLeida(
          mensaje: 'Fecha l&iacute;mite: 15 de abril',
        ),
      ));

      expect(find.textContaining('límite'), findsOneWidget);
      expect(find.textContaining('&iacute;'), findsNothing);
    });

    testWidgets('muestra texto plano sin modificar', (tester) async {
      await tester.pumpWidget(crearWidget(
        notificacion: notificacionNoLeida(
          titulo: 'Título simple',
          mensaje: 'Mensaje simple sin HTML.',
        ),
      ));

      expect(find.text('Título simple'), findsOneWidget);
      expect(find.textContaining('Mensaje simple'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Estado visual — leída vs no leída
  // ---------------------------------------------------------------------------
  group('indicadores visuales leída / no leída', () {
    testWidgets('notificación no leída muestra ícono de campana activo',
        (tester) async {
      await tester.pumpWidget(
        crearWidget(notificacion: notificacionNoLeida()),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('notificación leída muestra ícono de campana outlined',
        (tester) async {
      await tester.pumpWidget(
        crearWidget(notificacion: notificacionLeida()),
      );

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('notificación no leída muestra punto indicador (8×8)',
        (tester) async {
      await tester.pumpWidget(
        crearWidget(notificacion: notificacionNoLeida()),
      );

      // El punto indicador es un Container de exactamente 8×8 con BoxShape.circle.
      // El CircleAvatar (leading) tiene tamaño distinto, por eso filtramos por tamaño.
      final contenedores = tester.widgetList<Container>(find.byType(Container));
      final tienePunto = contenedores.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.shape == BoxShape.circle &&
            c.constraints?.maxWidth == 8 &&
            c.constraints?.maxHeight == 8;
      });
      expect(tienePunto, isTrue);
    });

    testWidgets('notificación leída no muestra punto indicador (8×8)', (tester) async {
      await tester.pumpWidget(
        crearWidget(notificacion: notificacionLeida()),
      );

      final contenedores = tester.widgetList<Container>(find.byType(Container));
      final tienePunto = contenedores.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.shape == BoxShape.circle &&
            c.constraints?.maxWidth == 8 &&
            c.constraints?.maxHeight == 8;
      });
      expect(tienePunto, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Fecha relativa
  // ---------------------------------------------------------------------------
  group('fecha relativa', () {
    testWidgets('muestra "hace Xmin" para notificaciones recientes', (tester) async {
      final notif = Notificacion(
        id: 3,
        userId: 10,
        titulo: 'Test',
        mensaje: 'Test',
        campania: 'manual',
        fecha: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
      );

      await tester.pumpWidget(crearWidget(notificacion: notif));

      expect(find.textContaining('min'), findsOneWidget);
    });

    testWidgets('muestra "hace Xh" para notificaciones de horas', (tester) async {
      final notif = Notificacion(
        id: 4,
        userId: 10,
        titulo: 'Test',
        mensaje: 'Test',
        campania: 'manual',
        fecha: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      );

      await tester.pumpWidget(crearWidget(notificacion: notif));

      expect(find.textContaining('h'), findsOneWidget);
    });

    testWidgets('muestra "ayer" para notificaciones del día anterior', (tester) async {
      final notif = Notificacion(
        id: 5,
        userId: 10,
        titulo: 'Test',
        mensaje: 'Test',
        campania: 'manual',
        fecha: DateTime.now().subtract(const Duration(hours: 30)),
        isRead: false,
      );

      await tester.pumpWidget(crearWidget(notificacion: notif));

      expect(find.text('ayer'), findsOneWidget);
    });

    testWidgets('muestra fecha dd/MM/yy para notificaciones antiguas', (tester) async {
      final notif = Notificacion(
        id: 6,
        userId: 10,
        titulo: 'Test',
        mensaje: 'Test',
        campania: 'manual',
        fecha: DateTime(2026, 1, 15),
        isRead: false,
      );

      await tester.pumpWidget(crearWidget(notificacion: notif));

      expect(find.text('15/01/26'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Interacción
  // ---------------------------------------------------------------------------
  group('interacción', () {
    testWidgets('invoca onTap al presionar el item', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(crearWidget(
        notificacion: notificacionNoLeida(),
        onTap: () => tapCount++,
      ));

      await tester.tap(find.byType(ListTile));
      expect(tapCount, equals(1));
    });
  });
}
