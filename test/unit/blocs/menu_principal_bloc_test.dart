/// Tests unitarios para MenuPrincipalBloc y MenuPrincipalState.
///
/// Verifica el comportamiento del BLoC del menú principal:
/// - Carga de datos de sesión y estados de cuenta
/// - Selección de items del menú
/// - Cierre de sesión
/// - Getter resumenAlumnos del estado
library;

import 'package:arjipagos/src/domain/models/EstatodosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalBloc.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalEvent.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/bloc/MenuPrincipalState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MenuPrincipalBloc bloc;
  late MockGetUserSessionUseCase mockGetUserSession;
  late MockGetEstadosDeCuentaUseCase mockGetEstadosDeCuenta;
  late MockLogoutUseCase mockLogout;
  late MockFcmService mockFcmService;

  final testAuthResponse = TestAuthResponse.valid;
  final testAlumnoActivo = TestAlumno.activo;
  final testAlumnoBaja = TestAlumno.baja;

  /// Crea una instancia del BLoC con los mocks configurados.
  MenuPrincipalBloc createBloc() {
    return MenuPrincipalBloc(
      createMockAuthUseCases(
        getUserSession: mockGetUserSession,
        logout: mockLogout,
      ),
      createMockEdoCtaUseCases(
        getEstadosDeCuenta: mockGetEstadosDeCuenta,
      ),
      mockFcmService,
    );
  }

  setUp(() {
    // Arrange - configurar mocks antes de cada test
    mockGetUserSession = MockGetUserSessionUseCase();
    mockGetEstadosDeCuenta = MockGetEstadosDeCuentaUseCase();
    mockLogout = MockLogoutUseCase();
    mockFcmService = MockFcmService();
    // Stub obtenerToken para que _registrarTokenFcm no lance MissingStubError
    when(() => mockFcmService.obtenerToken()).thenAnswer((_) async => null);
    // Inicializar bloc por defecto para que tearDown siempre funcione
    bloc = createBloc();
  });

  tearDown(() {
    bloc.close();
  });

  // ==========================================================================
  // TESTS DE MenuPrincipalState
  // ==========================================================================

  group('MenuPrincipalState', () {
    group('resumenAlumnos', () {
      test('devuelve "Sin alumnos" cuando la lista está vacía', () {
        // Arrange
        const estado = MenuPrincipalState(alumnos: []);

        // Act
        final resumen = estado.resumenAlumnos;

        // Assert
        expect(resumen, equals('Sin alumnos'));
      });

      test('devuelve singular con nombre cuando hay un solo alumno', () {
        // Arrange
        final estado = MenuPrincipalState(alumnos: [testAlumnoActivo]);

        // Act
        final resumen = estado.resumenAlumnos;

        // Assert - usa el campo `nombre` (María), no `alumno` (apellidos)
        expect(resumen, equals('1 alumno: María'));
      });

      test('devuelve plural con nombres separados por coma cuando hay dos alumnos', () {
        // Arrange
        final estado = MenuPrincipalState(
          alumnos: [testAlumnoActivo, testAlumnoBaja],
        );

        // Act
        final resumen = estado.resumenAlumnos;

        // Assert - usa `nombre` de cada alumno: 'María' y 'Pedro'
        expect(resumen, equals('2 alumnos: María, Pedro'));
      });

      test('usa el campo nombre y NO el campo alumno (apellidos en mayúsculas)', () {
        // Arrange
        final estado = MenuPrincipalState(alumnos: [testAlumnoActivo]);

        // Act
        final resumen = estado.resumenAlumnos;

        // Assert - no debe contener la cadena de apellidos en mayúsculas
        expect(resumen, isNot(contains('LOPEZ GARCIA MARIA')));
        expect(resumen, contains('María'));
      });
    });

    test('defaultMenuItems contiene los items de pagos y facturas', () {
      // Act
      final items = MenuPrincipalState.defaultMenuItems;

      // Assert
      expect(items, hasLength(2));
      expect(items.map((i) => i.id), containsAll(['pagos', 'facturas']));
    });
  });

  // ==========================================================================
  // TESTS DE MenuPrincipalBloc
  // ==========================================================================

  group('MenuPrincipalBloc', () {
    test('estado inicial es correcto', () {
      // Arrange & Act
      bloc = createBloc();

      // Assert
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.alumnos, isEmpty);
      expect(bloc.state.menuItems, isEmpty);
      expect(bloc.state.nombreUsuario, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.selectedItemId, isNull);
    });

    // ========================================================================
    // MenuPrincipalInitialEvent
    // ========================================================================

    group('MenuPrincipalInitialEvent', () {
      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'emite error cuando getUserSession devuelve null',
        setUp: () {
          when(() => mockGetUserSession.run()).thenAnswer((_) async => null);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuPrincipalInitialEvent()),
        expect: () => [
          // Estado de carga
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isTrue),
          // Estado de error sin sesión
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'No se pudo cargar la información del usuario',
              )
              .having(
                (s) => s.menuItems,
                'menuItems',
                hasLength(MenuPrincipalState.defaultMenuItems.length),
              ),
        ],
        verify: (_) {
          verify(() => mockGetUserSession.run()).called(1);
        },
      );

      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'carga usuario y alumnos cuando getUserSession y getEstadosDeCuenta son exitosos',
        setUp: () {
          when(() => mockGetUserSession.run())
              .thenAnswer((_) async => testAuthResponse);
          when(() => mockGetEstadosDeCuenta.run()).thenAnswer(
            (_) async => Success(
              EstatodosDeCuentaResponse(
                familiaId: '1',
                familia: 'Familia López García',
                cicloPredeterminadoId: '2024',
                alumnos: [testAlumnoActivo],
              ),
            ),
          );
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuPrincipalInitialEvent()),
        expect: () => [
          // Estado de carga
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isTrue),
          // Estado intermedio con datos de usuario cargados
          isA<MenuPrincipalState>()
              .having(
                (s) => s.nombreUsuario,
                'nombreUsuario',
                testAuthResponse.user.fullName,
              )
              .having(
                (s) => s.emailUsuario,
                'emailUsuario',
                testAuthResponse.user.email,
              )
              .having(
                (s) => s.menuItems,
                'menuItems',
                hasLength(MenuPrincipalState.defaultMenuItems.length),
              ),
          // Estado final con alumnos y familia cargados
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.familia, 'familia', 'Familia López García')
              .having((s) => s.alumnos, 'alumnos', hasLength(1))
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
        verify: (_) {
          verify(() => mockGetUserSession.run()).called(1);
          verify(() => mockGetEstadosDeCuenta.run()).called(1);
        },
      );

      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'carga usuario sin alumnos cuando getEstadosDeCuenta devuelve Error',
        setUp: () {
          when(() => mockGetUserSession.run())
              .thenAnswer((_) async => testAuthResponse);
          when(() => mockGetEstadosDeCuenta.run())
              .thenAnswer((_) async => Error('Error de conexión'));
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuPrincipalInitialEvent()),
        expect: () => [
          // Estado de carga
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isTrue),
          // Estado intermedio con datos de usuario
          isA<MenuPrincipalState>()
              .having(
                (s) => s.nombreUsuario,
                'nombreUsuario',
                testAuthResponse.user.fullName,
              ),
          // Estado final: usuario cargado pero sin alumnos
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.alumnos, 'alumnos', isEmpty)
              .having((s) => s.familia, 'familia', isNull),
        ],
        verify: (_) {
          verify(() => mockGetUserSession.run()).called(1);
          verify(() => mockGetEstadosDeCuenta.run()).called(1);
        },
      );

      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'carga usuario sin alumnos cuando getEstadosDeCuenta lanza excepción',
        setUp: () {
          when(() => mockGetUserSession.run())
              .thenAnswer((_) async => testAuthResponse);
          when(() => mockGetEstadosDeCuenta.run())
              .thenThrow(Exception('Fallo de red inesperado'));
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuPrincipalInitialEvent()),
        expect: () => [
          // Estado de carga
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isTrue),
          // Estado intermedio con datos de usuario
          isA<MenuPrincipalState>()
              .having((s) => s.nombreUsuario, 'nombreUsuario', isNotNull),
          // Estado final: cargado sin alumnos (excepción interna capturada)
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.alumnos, 'alumnos', isEmpty),
        ],
      );

      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'emite mensaje de error cuando getUserSession lanza excepción',
        setUp: () {
          when(() => mockGetUserSession.run())
              .thenThrow(Exception('Sin conexión'));
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuPrincipalInitialEvent()),
        expect: () => [
          // Estado de carga
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isTrue),
          // Estado de error
          isA<MenuPrincipalState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                startsWith('Error al cargar datos:'),
              )
              .having(
                (s) => s.menuItems,
                'menuItems',
                hasLength(MenuPrincipalState.defaultMenuItems.length),
              ),
        ],
        verify: (_) {
          verify(() => mockGetUserSession.run()).called(1);
        },
      );
    });

    // ========================================================================
    // MenuItemSelected
    // ========================================================================

    group('MenuItemSelected', () {
      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'emite el itemId seleccionado y luego null para permitir re-selección',
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuItemSelected(itemId: 'pagos')),
        expect: () => [
          // Primer emit: item seleccionado
          isA<MenuPrincipalState>()
              .having((s) => s.selectedItemId, 'selectedItemId', 'pagos'),
          // Segundo emit: reset a null
          isA<MenuPrincipalState>()
              .having((s) => s.selectedItemId, 'selectedItemId', isNull),
        ],
      );

      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'permite seleccionar el mismo item más de una vez',
        build: () => createBloc(),
        act: (bloc) {
          bloc.add(const MenuItemSelected(itemId: 'facturas'));
          bloc.add(const MenuItemSelected(itemId: 'facturas'));
        },
        expect: () => [
          isA<MenuPrincipalState>()
              .having((s) => s.selectedItemId, 'selectedItemId', 'facturas'),
          isA<MenuPrincipalState>()
              .having((s) => s.selectedItemId, 'selectedItemId', isNull),
          isA<MenuPrincipalState>()
              .having((s) => s.selectedItemId, 'selectedItemId', 'facturas'),
          isA<MenuPrincipalState>()
              .having((s) => s.selectedItemId, 'selectedItemId', isNull),
        ],
      );
    });

    // ========================================================================
    // MenuPrincipalLogout
    // ========================================================================

    group('MenuPrincipalLogout', () {
      blocTest<MenuPrincipalBloc, MenuPrincipalState>(
        'llama al caso de uso de logout',
        setUp: () {
          // getUserSession devuelve null → _eliminarTokenFcm termina temprano sin error
          when(() => mockGetUserSession.run()).thenAnswer((_) async => null);
          when(() => mockLogout.run()).thenAnswer((_) async => true);
        },
        build: () => createBloc(),
        act: (bloc) => bloc.add(const MenuPrincipalLogout()),
        expect: () => [],
        verify: (_) {
          verify(() => mockLogout.run()).called(1);
        },
      );
    });
  });
}
