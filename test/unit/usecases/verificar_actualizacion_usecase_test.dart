/// Tests del caso de uso que decide si hay que obligar a actualizar.
///
/// Es la regla de negocio de la feature, y lo que más se blinda aquí es el
/// lado seguro: **ante cualquier duda, no se bloquea**. Un usuario fuera de la
/// app por un fallo de red sería peor que uno con una versión vieja.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/domain/models/version/VersionApp.dart';
import 'package:arjipagos/src/domain/useCases/version/VerificarActualizacionUseCase.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockVersionRepository repository;

  /// Construye el caso de uso con una versión instalada fija.
  VerificarActualizacionUseCase conInstalada({
    int build = 33,
    String version = '1.0.24',
  }) {
    return VerificarActualizacionUseCase(
      repository,
      leerVersionInstalada: () async => (build: build, version: version),
    );
  }

  /// Programa la respuesta del backend.
  void conPolitica(VersionApp politica) {
    when(() => repository.getVersion())
        .thenAnswer((_) async => Success(politica));
  }

  setUp(() {
    repository = MockVersionRepository();
  });

  group('Casos en los que NO se bloquea', () {
    test('si la consulta falla', () async {
      when(() => repository.getVersion())
          .thenAnswer((_) async => Error<VersionApp>('sin red'));

      final resultado = await conInstalada().run();

      expect(resultado.estado, EstadoActualizacion.ninguna);
      expect(resultado.bloquea, isFalse);
    });

    test('si la política no trae umbrales', () async {
      conPolitica(VersionApp.vacia);

      final resultado = await conInstalada().run();

      expect(resultado.estado, EstadoActualizacion.ninguna);
    });

    test('si la versión instalada está al día', () async {
      conPolitica(const VersionApp(buildMinimo: 33, buildRecomendado: 33));

      final resultado = await conInstalada(build: 33).run();

      expect(resultado.estado, EstadoActualizacion.ninguna);
    });

    test('si no se puede leer la versión instalada', () async {
      conPolitica(const VersionApp(buildMinimo: 99));

      final useCase = VerificarActualizacionUseCase(
        repository,
        leerVersionInstalada: () async => throw Exception('canal nativo caído'),
      );

      expect((await useCase.run()).estado, EstadoActualizacion.ninguna);
    });

    test('si el build instalado es ilegible y el nombre de versión está al día',
        () async {
      // Sin este resguardo, un build 0 quedaría por debajo de cualquier mínimo
      // y bloquearía a un usuario que en realidad tiene la versión buena.
      conPolitica(const VersionApp(buildMinimo: 34, versionMinima: '1.0.24'));

      final resultado = await conInstalada(build: 0, version: '1.0.24').run();

      expect(resultado.estado, EstadoActualizacion.ninguna);
    });
  });

  group('Actualización obligatoria', () {
    test('cuando el build queda por debajo del mínimo', () async {
      conPolitica(const VersionApp(
        buildMinimo: 34,
        urlTienda: 'https://play.google.com/store/apps/details?id=x',
        mensaje: 'Actualiza ya',
      ));

      final resultado = await conInstalada(build: 33).run();

      expect(resultado.estado, EstadoActualizacion.obligatoria);
      expect(resultado.bloquea, isTrue);
      expect(resultado.mensaje, 'Actualiza ya');
      expect(resultado.urlTienda, contains('play.google.com'));
    });

    test('usa el mensaje de respaldo si el backend no manda uno', () async {
      conPolitica(const VersionApp(buildMinimo: 34));

      final resultado = await conInstalada(build: 33).run();

      expect(resultado.mensaje, AppStrings.actualizacionMensajeObligatoria);
    });

    test('usa la URL de respaldo si el backend no manda una', () async {
      conPolitica(const VersionApp(buildMinimo: 34));

      final resultado = await conInstalada(build: 33).run();

      // Los tests corren en escritorio, donde la plataforma no es iOS.
      expect(resultado.urlTienda, contains('mx.moriah.arjipagos'));
    });

    test('gana sobre la sugerida cuando se cumplen las dos', () async {
      conPolitica(const VersionApp(buildMinimo: 34, buildRecomendado: 40));

      final resultado = await conInstalada(build: 33).run();

      expect(resultado.estado, EstadoActualizacion.obligatoria);
    });
  });

  group('Actualización sugerida', () {
    test('cuando solo se queda por debajo de la recomendada', () async {
      conPolitica(const VersionApp(buildMinimo: 30, buildRecomendado: 40));

      final resultado = await conInstalada(build: 33).run();

      expect(resultado.estado, EstadoActualizacion.sugerida);
      expect(resultado.bloquea, isFalse);
      expect(resultado.mensaje, AppStrings.actualizacionMensajeSugerida);
    });
  });

  group('Mantenimiento', () {
    test('manda sobre cualquier comparación de versiones', () async {
      conPolitica(const VersionApp(
        buildMinimo: 1,
        mantenimiento: true,
        mensajeMantenimiento: 'Volvemos en 10 minutos',
      ));

      final resultado = await conInstalada(build: 99).run();

      expect(resultado.estado, EstadoActualizacion.mantenimiento);
      expect(resultado.bloquea, isTrue);
      expect(resultado.mensaje, 'Volvemos en 10 minutos');
      // Sin tienda: actualizar no arreglaría un mantenimiento del servidor.
      expect(resultado.urlTienda, isEmpty);
    });

    test('usa el mensaje de respaldo si el backend no manda uno', () async {
      conPolitica(const VersionApp(mantenimiento: true));

      final resultado = await conInstalada().run();

      expect(resultado.mensaje, AppStrings.actualizacionMensajeMantenimiento);
    });
  });
}
