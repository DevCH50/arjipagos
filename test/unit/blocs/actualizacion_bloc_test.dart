/// Tests del BLoC de actualización.
///
/// Lo que se blinda aquí es el ritmo de las consultas: el arranque siempre
/// revisa, y el regreso del segundo plano solo lo hace si ya pasó el intervalo
/// mínimo. Sin eso, alternar entre aplicaciones dispararía una petición por
/// cada regreso.
library;

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/domain/useCases/version/VersionUseCases.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionEvent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockVerificarActualizacionUseCase mockVerificar;
  late MockSharedPref mockSharedPref;
  late VersionUseCases useCases;

  /// Instante fijo para no depender del reloj real.
  final ahora = DateTime(2026, 8, 21, 12, 0);

  /// Construye el BLoC con la marca de la última revisión que se le indique.
  ActualizacionBloc crearBloc({DateTime? ultimaRevision}) {
    when(() => mockSharedPref.read(any())).thenAnswer(
      (_) async => ultimaRevision?.millisecondsSinceEpoch,
    );
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});

    return ActualizacionBloc(useCases, mockSharedPref, ahora: () => ahora);
  }

  setUp(() {
    mockVerificar = MockVerificarActualizacionUseCase();
    mockSharedPref = MockSharedPref();
    useCases = VersionUseCases(verificarActualizacion: mockVerificar);

    when(() => mockVerificar.run())
        .thenAnswer((_) async => ResultadoActualizacion.sinCambios);
  });

  group('Ritmo de las consultas', () {
    test('el arranque siempre consulta, aunque acabe de revisarse', () async {
      final bloc = crearBloc(ultimaRevision: ahora);

      bloc.add(const ActualizacionVerificarEvent(forzar: true));
      await Future<void>.delayed(Duration.zero);

      verify(() => mockVerificar.run()).called(1);
      await bloc.close();
    });

    test('sin marca previa, consulta', () async {
      final bloc = crearBloc();

      bloc.add(const ActualizacionVerificarEvent());
      await Future<void>.delayed(Duration.zero);

      verify(() => mockVerificar.run()).called(1);
      await bloc.close();
    });

    test('no consulta dos veces dentro del intervalo mínimo', () async {
      final bloc = crearBloc(
        ultimaRevision: ahora.subtract(const Duration(minutes: 5)),
      );

      bloc.add(const ActualizacionVerificarEvent());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockVerificar.run());
      await bloc.close();
    });

    test('vuelve a consultar pasado el intervalo', () async {
      final bloc = crearBloc(
        ultimaRevision: ahora.subtract(
          AppDurations.intervaloRevisionVersion + const Duration(minutes: 1),
        ),
      );

      bloc.add(const ActualizacionVerificarEvent());
      await Future<void>.delayed(Duration.zero);

      verify(() => mockVerificar.run()).called(1);
      await bloc.close();
    });

    test('una marca en el futuro se ignora (reloj del móvil movido)', () async {
      final bloc = crearBloc(ultimaRevision: ahora.add(const Duration(days: 2)));

      bloc.add(const ActualizacionVerificarEvent());
      await Future<void>.delayed(Duration.zero);

      verify(() => mockVerificar.run()).called(1);
      await bloc.close();
    });
  });

  group('Veredicto', () {
    test('publica el resultado que devuelve el caso de uso', () async {
      when(() => mockVerificar.run()).thenAnswer(
        (_) async => const ResultadoActualizacion(
          estado: EstadoActualizacion.obligatoria,
          mensaje: 'Actualiza',
          urlTienda: 'https://play.google.com/store/apps/details?id=x',
        ),
      );

      final bloc = crearBloc();
      bloc.add(const ActualizacionVerificarEvent(forzar: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.resultado.estado, EstadoActualizacion.obligatoria);
      expect(bloc.state.hayDialogoPendiente, isTrue);
      await bloc.close();
    });

    test('un fallo del caso de uso no bloquea ni rompe el BLoC', () async {
      when(() => mockVerificar.run()).thenThrow(Exception('fallo inesperado'));

      final bloc = crearBloc();
      bloc.add(const ActualizacionVerificarEvent(forzar: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.resultado.estado, EstadoActualizacion.ninguna);
      await bloc.close();
    });

    test('con el diálogo abierto no se vuelve a consultar', () async {
      final bloc = crearBloc();

      bloc.add(const ActualizacionDialogoMostradoEvent());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ActualizacionVerificarEvent(forzar: true));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockVerificar.run());
      await bloc.close();
    });

    test('Reintentar vuelve a consultar aunque el diálogo esté abierto',
        () async {
      // Regresión del fallo visto en el Oppo el 2026-08-21: se mandaban dos
      // eventos —cierre y comprobación— y `bloc` no garantiza el orden entre
      // handlers distintos. La comprobación corría primero, encontraba
      // `dialogoAbierto == true` y salía sin consultar: el aviso de
      // mantenimiento se cerraba y no volvía nada.
      when(() => mockVerificar.run()).thenAnswer(
        (_) async => const ResultadoActualizacion(
          estado: EstadoActualizacion.mantenimiento,
          mensaje: 'En mantenimiento',
        ),
      );

      final bloc = crearBloc();
      bloc.add(const ActualizacionVerificarEvent(forzar: true));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ActualizacionDialogoMostradoEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.dialogoAbierto, isTrue);

      // Al reintentar, el servidor ya salió de mantenimiento y toca actualizar.
      when(() => mockVerificar.run()).thenAnswer(
        (_) async => const ResultadoActualizacion(
          estado: EstadoActualizacion.sugerida,
          mensaje: 'Hay una versión nueva',
        ),
      );

      bloc.add(const ActualizacionReintentarEvent());
      await Future<void>.delayed(Duration.zero);

      verify(() => mockVerificar.run()).called(2);
      expect(bloc.state.resultado.estado, EstadoActualizacion.sugerida);
      // Y el veredicto nuevo queda listo para pintarse.
      expect(bloc.state.hayDialogoPendiente, isTrue);
      await bloc.close();
    });

    test('Reintentar sin nada pendiente deja la pantalla limpia', () async {
      when(() => mockVerificar.run()).thenAnswer(
        (_) async => ResultadoActualizacion.sinCambios,
      );

      final bloc = crearBloc();
      bloc.add(const ActualizacionDialogoMostradoEvent());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ActualizacionReintentarEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.resultado.estado, EstadoActualizacion.ninguna);
      expect(bloc.state.dialogoAbierto, isFalse);
      await bloc.close();
    });

    test('cerrar el diálogo devuelve el estado a neutro', () async {
      when(() => mockVerificar.run()).thenAnswer(
        (_) async => const ResultadoActualizacion(
          estado: EstadoActualizacion.sugerida,
          mensaje: 'Hay versión nueva',
        ),
      );

      final bloc = crearBloc();
      bloc.add(const ActualizacionVerificarEvent(forzar: true));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ActualizacionDialogoCerradoEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.resultado.estado, EstadoActualizacion.ninguna);
      expect(bloc.state.dialogoAbierto, isFalse);
      await bloc.close();
    });
  });
}
