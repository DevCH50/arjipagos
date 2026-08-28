/// Tests del push de pago exitoso sobre la lista de pagos **sin pagar**.
///
/// Regla que se protege: cada emisor fiscal es independiente, así que el push
/// de un cobro solo puede refrescar la lista del emisor que se cobró. Si
/// refrescara las dos, un emisor se enteraría de lo que pasa en el otro y
/// además perdería su selección sin motivo.
///
/// `EdoCtaPagadosBloc` (Pagos Realizados) es otra historia y no se toca aquí:
/// ese sí se refresca con cualquier pago, porque muestra todos.
library;

import 'dart:async';

import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// Push tal y como lo entrega FCM: **todos los valores son texto**, incluido
/// `emisorfiscal_id`. Darlo por entero aquí escondería el fallo real.
RemoteMessage _pushDePago({String? emisorFiscalId}) => RemoteMessage(
  data: <String, String>{
    'campania': 'pago',
    'accion': 'pago_exitoso',
    'alumno_id': '7',
    'ticket_folio': 'T7672',
    'emisorfiscal_id': ?emisorFiscalId,
  },
);

void main() {
  late MockSharedPref mockSharedPref;
  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;

  setUp(() {
    mockSharedPref = MockSharedPref();
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();

    when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
    when(
      () => mockGetEstadosDeCuenta.run(
        emisorFiscalId: any(named: 'emisorFiscalId'),
      ),
    ).thenAnswer(
      (_) async => Success(
        EstadosDeCuentaResponse(
          alumnos: [alumnoConPagosPorCiclo(7, const {})],
          cicloPredeterminadoId: '1',
          familiaId: '1',
          familia: 'Familia Test',
          success: true,
          message: '',
        ),
      ),
    );
  });

  /// Crea el BLoC de [emisorFiscalId] escuchando [stream] como si fuera FCM.
  EdoCtaListBloc crearBloc(int emisorFiscalId, Stream<RemoteMessage> stream) =>
      EdoCtaListBloc(
        createMockEdoCtaUseCases(getEstadosDeCuenta: mockGetEstadosDeCuenta),
        SeleccionPagosStorage(
          mockSharedPref,
          claveSeleccion: 'seleccion_pagos_ef$emisorFiscalId',
        ),
        emisorFiscalId: emisorFiscalId,
        fcmPrimerPlanoStream: stream,
      );

  /// Espera a que el BLoC procese lo que tenga pendiente.
  Future<void> asentar() => Future<void>.delayed(Duration.zero);

  group('El push refresca solo la lista de su emisor', () {
    test('un push del emisor 2 NO toca la lista del emisor 1', () async {
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final ef1 = crearBloc(1, controlador.stream);
      addTearDown(ef1.close);
      await asentar();

      controlador.add(_pushDePago(emisorFiscalId: '2'));
      await asentar();

      // Ni una sola petición: el emisor 1 ni se entera del cobro del 2.
      verifyNever(
        () => mockGetEstadosDeCuenta.run(
          emisorFiscalId: any(named: 'emisorFiscalId'),
        ),
      );
    });

    test('un push del emisor 2 SÍ refresca la lista del emisor 2', () async {
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final ef2 = crearBloc(2, controlador.stream);
      addTearDown(ef2.close);
      await asentar();

      controlador.add(_pushDePago(emisorFiscalId: '2'));
      await asentar();

      // No basta con que haya refrescado: tiene que haber pedido **su** emisor.
      // Consultar con el 1 traería los pagos de la otra pantalla.
      verify(() => mockGetEstadosDeCuenta.run(emisorFiscalId: 2)).called(1);
      verifyNever(() => mockGetEstadosDeCuenta.run(emisorFiscalId: 1));
    });

    test('los dos emisores a la vez: solo reacciona el cobrado', () async {
      // El caso real: las dos instancias existen y escuchan el mismo FCM.
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final otroMock = MockGetEstadosDeCuentaUseCase();
      when(
        () => otroMock.run(emisorFiscalId: any(named: 'emisorFiscalId')),
      ).thenAnswer(
        (_) async => Success(
          EstadosDeCuentaResponse(
            alumnos: const [],
            cicloPredeterminadoId: '1',
            familiaId: '1',
            familia: 'Familia Test',
            success: true,
            message: '',
          ),
        ),
      );

      final ef1 = EdoCtaListBloc(
        createMockEdoCtaUseCases(getEstadosDeCuenta: otroMock),
        SeleccionPagosStorage(
          mockSharedPref,
          claveSeleccion: 'seleccion_pagos_ef1',
        ),
        emisorFiscalId: 1,
        fcmPrimerPlanoStream: controlador.stream,
      );
      final ef2 = crearBloc(2, controlador.stream);
      addTearDown(ef1.close);
      addTearDown(ef2.close);
      await asentar();

      controlador.add(_pushDePago(emisorFiscalId: '1'));
      await asentar();

      // El emisor 1 refresca, y pidiendo el suyo.
      verify(() => otroMock.run(emisorFiscalId: 1)).called(1);
      verifyNever(
        () => mockGetEstadosDeCuenta.run(
          emisorFiscalId: any(named: 'emisorFiscalId'),
        ),
      );
    });
  });

  group('Compatibilidad y datos raros', () {
    test('sin `emisorfiscal_id` refresca el emisor predeterminado', () async {
      // Un backend que todavía no mande la clave debe seguir refrescando la
      // lista de siempre, no dejar de refrescar ninguna.
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final ef1 = crearBloc(1, controlador.stream);
      addTearDown(ef1.close);
      await asentar();

      controlador.add(_pushDePago());
      await asentar();

      verify(
        () => mockGetEstadosDeCuenta.run(
          emisorFiscalId: any(named: 'emisorFiscalId'),
        ),
      ).called(1);
    });

    test('un `emisorfiscal_id` ilegible cae en el predeterminado', () async {
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final ef1 = crearBloc(1, controlador.stream);
      addTearDown(ef1.close);
      await asentar();

      controlador.add(_pushDePago(emisorFiscalId: 'no-es-un-numero'));
      await asentar();

      verify(
        () => mockGetEstadosDeCuenta.run(
          emisorFiscalId: any(named: 'emisorFiscalId'),
        ),
      ).called(1);
    });

    test('un push que no es de pago se ignora', () async {
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final ef1 = crearBloc(1, controlador.stream);
      addTearDown(ef1.close);
      await asentar();

      // Le falta `accion`: la convención exige las dos claves.
      controlador.add(
        const RemoteMessage(
          data: <String, String>{'campania': 'pago', 'emisorfiscal_id': '1'},
        ),
      );
      // Y un push de banners, que no es asunto de esta pantalla.
      controlador.add(
        const RemoteMessage(
          data: <String, String>{
            'campania': 'banner',
            'accion': 'refrescar_banners',
          },
        ),
      );
      await asentar();

      verifyNever(
        () => mockGetEstadosDeCuenta.run(
          emisorFiscalId: any(named: 'emisorFiscalId'),
        ),
      );
    });

    test('al refrescar por push se vacía la selección de ese emisor', () async {
      // Lo recién liquidado desaparece de la lista; dejar sus IDs marcados
      // daría un total y una referencia que no corresponden a nada.
      final controlador = StreamController<RemoteMessage>.broadcast();
      addTearDown(controlador.close);

      final ef2 = crearBloc(2, controlador.stream);
      addTearDown(ef2.close);
      await asentar();

      controlador.add(_pushDePago(emisorFiscalId: '2'));
      await asentar();

      // Solo su clave. La del otro emisor no se toca.
      verify(() => mockSharedPref.save('seleccion_pagos_ef2', {})).called(1);
      verifyNever(() => mockSharedPref.save('seleccion_pagos_ef1', any()));
    });
  });
}
