/// Tests unitarios para SplashBloc.
///
/// Se cubren los handlers deterministas de navegación y progreso. El evento
/// SplashStarted NO se testea aquí porque depende de timers, delays y del
/// service locator (`locator<AuthUseCases>()`), fuera del alcance unitario.
library;

import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashBloc.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estado inicial es SplashState() en loading', () {
    final bloc = SplashBloc();
    expect(bloc.state.navigationState, SplashNavigationState.loading);
    expect(bloc.state.progress, 0.0);
    bloc.close();
  });

  group('SplashProgressUpdated', () {
    blocTest<SplashBloc, SplashState>(
      'actualiza progreso y texto de estado',
      build: SplashBloc.new,
      act: (bloc) => bloc.add(
        const SplashProgressUpdated(progress: 0.5, statusText: 'Configurando'),
      ),
      expect: () => [
        isA<SplashState>()
            .having((s) => s.progress, 'progress', 0.5)
            .having((s) => s.statusText, 'statusText', 'Configurando')
            .having((s) => s.progressPercent, 'progressPercent', 50),
      ],
    );
  });

  group('navegación', () {
    blocTest<SplashBloc, SplashState>(
      'SplashSessionFound navega al home con progreso completo',
      build: SplashBloc.new,
      act: (bloc) => bloc.add(const SplashSessionFound()),
      expect: () => [
        isA<SplashState>()
            .having((s) => s.navigationState, 'navigationState',
                SplashNavigationState.navigateToHome)
            .having((s) => s.progress, 'progress', 1.0)
            .having((s) => s.shouldNavigate, 'shouldNavigate', true),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'SplashNoSessionFound navega al login',
      build: SplashBloc.new,
      act: (bloc) => bloc.add(const SplashNoSessionFound()),
      expect: () => [
        isA<SplashState>().having((s) => s.navigationState, 'navigationState',
            SplashNavigationState.navigateToLogin),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'SplashError navega al login y expone el mensaje de error',
      build: SplashBloc.new,
      act: (bloc) => bloc.add(const SplashError('Fallo de inicialización')),
      expect: () => [
        isA<SplashState>()
            .having((s) => s.navigationState, 'navigationState',
                SplashNavigationState.navigateToLogin)
            .having((s) => s.errorMessage, 'errorMessage',
                'Fallo de inicialización'),
      ],
    );
  });
}
