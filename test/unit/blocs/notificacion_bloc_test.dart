/// Tests unitarios para NotificacionBloc.
///
/// Cubre todos los handlers de eventos:
/// - NotificacionInicialEvent (carga inicial + conteo)
/// - CargarMasNotificacionesEvent (paginación)
/// - MarcarLeidaEvent (optimistic update individual)
/// - MarcarTodasLeidasEvent (marcar todas)
/// - ActualizarContadorEvent (refresh badge)
/// - NotificacionForegroundRecibidaEvent (push en foreground)
/// - ResetNuevaNotificacionEvent (apagar indicador de nueva notif)
/// - NotificacionAbiertaDesdeBackgroundEvent (apertura desde notif → debeNavegar)
/// - ResetDebeNavegarEvent (limpiar señal de navegación automática)
library;

import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockGetNotificacionesUseCase mockGetNotificaciones;
  late MockGetCountNoLeidasUseCase mockGetCountNoLeidas;
  late MockMarcarLeidaUseCase mockMarcarLeida;
  late MockMarcarTodasLeidasUseCase mockMarcarTodasLeidas;

  // Construye el BLoC inyectando streams vacíos para aislar Firebase.
  NotificacionBloc buildBloc() => NotificacionBloc(
        createMockNotificacionUseCases(
          getNotificaciones: mockGetNotificaciones,
          getCountNoLeidas: mockGetCountNoLeidas,
          marcarLeida: mockMarcarLeida,
          marcarTodasLeidas: mockMarcarTodasLeidas,
        ),
        fcmForegroundStream: const Stream.empty(),
        fcmBackgroundTapStream: const Stream.empty(),
        getInitialMessage: () async => null,
      );

  setUp(() {
    mockGetNotificaciones = MockGetNotificacionesUseCase();
    mockGetCountNoLeidas = MockGetCountNoLeidasUseCase();
    mockMarcarLeida = MockMarcarLeidaUseCase();
    mockMarcarTodasLeidas = MockMarcarTodasLeidasUseCase();
  });

  group('estado inicial', () {
    test('es NotificacionState con valores por defecto', () {
      final bloc = buildBloc();
      expect(bloc.state, const NotificacionState());
      bloc.close();
    });
  });

  // ============================================================================
  // NotificacionInicialEvent
  // ============================================================================

  group('NotificacionInicialEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'emite [loading, datos] cuando lista y conteo tienen éxito',
      build: buildBloc,
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Success(TestNotificacion.listaPagina1));
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Success(3));
      },
      act: (bloc) => bloc.add(const NotificacionInicialEvent()),
      expect: () => [
        // Estado de carga inicial
        isA<NotificacionState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.notificaciones, 'notificaciones', isEmpty)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        // Estado final con datos
        isA<NotificacionState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.notificaciones, 'notificaciones',
                TestNotificacion.listaPagina1)
            .having((s) => s.noLeidas, 'noLeidas', 3)
            .having((s) => s.hayNueva, 'hayNueva', false)
            .having((s) => s.hayMas, 'hayMas', true)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'hayMas=false cuando la primera página viene vacía',
      build: buildBloc,
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Success(<Notificacion>[]));
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Success(0));
      },
      act: (bloc) => bloc.add(const NotificacionInicialEvent()),
      expect: () => [
        isA<NotificacionState>().having((s) => s.isLoading, 'isLoading', true),
        isA<NotificacionState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.notificaciones, 'notificaciones', isEmpty)
            .having((s) => s.hayMas, 'hayMas', false),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'emite errorMessage cuando falla la lista',
      build: buildBloc,
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Error('Sin conexión'));
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Success(0));
      },
      act: (bloc) => bloc.add(const NotificacionInicialEvent()),
      expect: () => [
        isA<NotificacionState>().having((s) => s.isLoading, 'isLoading', true),
        isA<NotificacionState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage', 'Sin conexión'),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'conserva noLeidas previo cuando falla solo el conteo',
      build: () {
        // Simular estado previo con noLeidas=5 usando seed
        final bloc = buildBloc();
        return bloc;
      },
      seed: () => const NotificacionState(noLeidas: 5),
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Success(TestNotificacion.listaPagina1));
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Error('Error contador'));
      },
      act: (bloc) => bloc.add(const NotificacionInicialEvent()),
      expect: () => [
        isA<NotificacionState>().having((s) => s.isLoading, 'isLoading', true),
        // noLeidas conserva el valor previo (5) porque el conteo falló
        isA<NotificacionState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.noLeidas, 'noLeidas', 5)
            .having((s) => s.notificaciones, 'notificaciones',
                TestNotificacion.listaPagina1),
      ],
    );
  });

  // ============================================================================
  // CargarMasNotificacionesEvent
  // ============================================================================

  group('CargarMasNotificacionesEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'agrega nuevas notificaciones e incrementa paginaActual',
      build: buildBloc,
      seed: () => NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        paginaActual: 1,
        hayMas: true,
      ),
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Success(TestNotificacion.listaPagina2));
      },
      act: (bloc) => bloc.add(const CargarMasNotificacionesEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.isCargandoMas, 'isCargandoMas', true),
        isA<NotificacionState>()
            .having((s) => s.isCargandoMas, 'isCargandoMas', false)
            .having(
              (s) => s.notificaciones.length,
              'notificaciones.length',
              TestNotificacion.listaPagina1.length +
                  TestNotificacion.listaPagina2.length,
            )
            .having((s) => s.paginaActual, 'paginaActual', 2)
            .having((s) => s.hayMas, 'hayMas', true),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'hayMas=false y página sin cambio cuando respuesta viene vacía',
      build: buildBloc,
      seed: () => NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        paginaActual: 1,
        hayMas: true,
      ),
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Success(<Notificacion>[]));
      },
      act: (bloc) => bloc.add(const CargarMasNotificacionesEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.isCargandoMas, 'isCargandoMas', true),
        isA<NotificacionState>()
            .having((s) => s.isCargandoMas, 'isCargandoMas', false)
            .having((s) => s.hayMas, 'hayMas', false)
            .having((s) => s.paginaActual, 'paginaActual', 1),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'emite errorMessage cuando falla la carga',
      build: buildBloc,
      seed: () =>
          const NotificacionState(paginaActual: 1, hayMas: true),
      setUp: () {
        when(() => mockGetNotificaciones.run(page: any(named: 'page')))
            .thenAnswer((_) async => Error('Error de red'));
      },
      act: (bloc) => bloc.add(const CargarMasNotificacionesEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.isCargandoMas, 'isCargandoMas', true),
        isA<NotificacionState>()
            .having((s) => s.isCargandoMas, 'isCargandoMas', false)
            .having((s) => s.errorMessage, 'errorMessage', 'Error de red'),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'no emite nada si isCargandoMas=true',
      build: buildBloc,
      seed: () => const NotificacionState(isCargandoMas: true, hayMas: true),
      act: (bloc) => bloc.add(const CargarMasNotificacionesEvent()),
      expect: () => [],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'no emite nada si hayMas=false',
      build: buildBloc,
      seed: () => const NotificacionState(isCargandoMas: false, hayMas: false),
      act: (bloc) => bloc.add(const CargarMasNotificacionesEvent()),
      expect: () => [],
    );
  });

  // ============================================================================
  // MarcarLeidaEvent
  // ============================================================================

  group('MarcarLeidaEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'marca como leída y decrementa noLeidas cuando era no leída',
      build: buildBloc,
      seed: () => NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        noLeidas: 2,
      ),
      setUp: () {
        when(() => mockMarcarLeida.run(any()))
            .thenAnswer((_) async => Success(true));
      },
      act: (bloc) =>
          bloc.add(MarcarLeidaEvent(id: TestNotificacion.noLeida.id)),
      expect: () => [
        isA<NotificacionState>().having(
          (s) => s.notificaciones.firstWhere((n) => n.id == 1).isRead,
          'isRead',
          true,
        ).having((s) => s.noLeidas, 'noLeidas', 1),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'no emite nuevo estado cuando la notificación ya estaba leída',
      build: buildBloc,
      seed: () => NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        noLeidas: 1,
      ),
      setUp: () {
        when(() => mockMarcarLeida.run(any()))
            .thenAnswer((_) async => Success(true));
      },
      act: (bloc) =>
          bloc.add(MarcarLeidaEvent(id: TestNotificacion.leida.id)),
      // El estado resultante es idéntico al anterior (Equatable lo detecta),
      // por lo que el Bloc no emite un estado nuevo.
      expect: () => [],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'emite errorMessage cuando falla el servidor',
      build: buildBloc,
      seed: () => NotificacionState(
          notificaciones: TestNotificacion.listaPagina1),
      setUp: () {
        when(() => mockMarcarLeida.run(any()))
            .thenAnswer((_) async => Error('No autorizado'));
      },
      act: (bloc) =>
          bloc.add(MarcarLeidaEvent(id: TestNotificacion.noLeida.id)),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.errorMessage, 'errorMessage', 'No autorizado'),
      ],
    );
  });

  // ============================================================================
  // MarcarTodasLeidasEvent
  // ============================================================================

  group('MarcarTodasLeidasEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'marca todas como leídas y pone noLeidas en 0',
      build: buildBloc,
      seed: () => NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        noLeidas: 3,
      ),
      setUp: () {
        when(() => mockMarcarTodasLeidas.run())
            .thenAnswer((_) async => Success(true));
      },
      act: (bloc) => bloc.add(const MarcarTodasLeidasEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having(
              (s) => s.notificaciones.every((n) => n.isRead),
              'todas leídas',
              true,
            )
            .having((s) => s.noLeidas, 'noLeidas', 0),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'emite errorMessage cuando falla el servidor',
      build: buildBloc,
      setUp: () {
        when(() => mockMarcarTodasLeidas.run())
            .thenAnswer((_) async => Error('Error al marcar'));
      },
      act: (bloc) => bloc.add(const MarcarTodasLeidasEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.errorMessage, 'errorMessage', 'Error al marcar'),
      ],
    );
  });

  // ============================================================================
  // ActualizarContadorEvent
  // ============================================================================

  group('ActualizarContadorEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'actualiza noLeidas con el valor del servidor',
      build: buildBloc,
      setUp: () {
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Success(7));
      },
      act: (bloc) => bloc.add(const ActualizarContadorEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.noLeidas, 'noLeidas', 7)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'emite errorMessage cuando falla el servidor',
      build: buildBloc,
      setUp: () {
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Error('Sin conexión'));
      },
      act: (bloc) => bloc.add(const ActualizarContadorEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.errorMessage, 'errorMessage', 'Sin conexión'),
      ],
    );
  });

  // ============================================================================
  // NotificacionForegroundRecibidaEvent
  // ============================================================================

  group('NotificacionForegroundRecibidaEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'inserta notificación al inicio, activa hayNueva e incrementa noLeidas',
      build: buildBloc,
      seed: () => NotificacionState(
        notificaciones: TestNotificacion.listaPagina1,
        noLeidas: 1,
      ),
      act: (bloc) => bloc.add(
        NotificacionForegroundRecibidaEvent(
            notificacion: TestNotificacion.foreground),
      ),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.hayNueva, 'hayNueva', true)
            .having((s) => s.noLeidas, 'noLeidas', 2)
            .having(
              (s) => s.notificaciones.first.id,
              'primer id',
              TestNotificacion.foreground.id,
            )
            .having(
              (s) => s.notificaciones.length,
              'length',
              TestNotificacion.listaPagina1.length + 1,
            ),
      ],
    );
  });

  // ============================================================================
  // ResetNuevaNotificacionEvent
  // ============================================================================

  group('ResetNuevaNotificacionEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'apaga hayNueva',
      build: buildBloc,
      seed: () => const NotificacionState(hayNueva: true),
      act: (bloc) => bloc.add(const ResetNuevaNotificacionEvent()),
      expect: () => [
        isA<NotificacionState>().having((s) => s.hayNueva, 'hayNueva', false),
      ],
    );
  });

  // ============================================================================
  // NotificacionAbiertaDesdeBackgroundEvent
  // ============================================================================

  group('NotificacionAbiertaDesdeBackgroundEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'activa hayNueva y debeNavegar, actualiza noLeidas desde el servidor',
      build: buildBloc,
      setUp: () {
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Success(4));
      },
      act: (bloc) =>
          bloc.add(const NotificacionAbiertaDesdeBackgroundEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.hayNueva, 'hayNueva', true)
            .having((s) => s.debeNavegar, 'debeNavegar', true),
        isA<NotificacionState>()
            .having((s) => s.hayNueva, 'hayNueva', true)
            .having((s) => s.debeNavegar, 'debeNavegar', true)
            .having((s) => s.noLeidas, 'noLeidas', 4),
      ],
    );

    blocTest<NotificacionBloc, NotificacionState>(
      'mantiene hayNueva=true y debeNavegar=true aunque falle el contador',
      build: buildBloc,
      setUp: () {
        when(() => mockGetCountNoLeidas.run())
            .thenAnswer((_) async => Error('Error'));
      },
      act: (bloc) =>
          bloc.add(const NotificacionAbiertaDesdeBackgroundEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.hayNueva, 'hayNueva', true)
            .having((s) => s.debeNavegar, 'debeNavegar', true),
        // No emite segundo estado porque el error no produce emit en este handler
      ],
    );
  });

  // ============================================================================
  // ResetDebeNavegarEvent
  // ============================================================================

  group('ResetDebeNavegarEvent', () {
    blocTest<NotificacionBloc, NotificacionState>(
      'apaga debeNavegar sin afectar hayNueva',
      build: buildBloc,
      seed: () => const NotificacionState(hayNueva: true, debeNavegar: true),
      act: (bloc) => bloc.add(const ResetDebeNavegarEvent()),
      expect: () => [
        isA<NotificacionState>()
            .having((s) => s.debeNavegar, 'debeNavegar', false)
            .having((s) => s.hayNueva, 'hayNueva', true),
      ],
    );
  });
}
