import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashBloc.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
import 'package:arjipagos/src/presentation/widgets/estacional/adorno_estacional.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Página de splash/carga inicial de la aplicación.
///
/// Muestra el logo girando en el centro de la pantalla mientras se
/// inicializan las dependencias y se verifica la sesión del usuario.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(const SplashStarted()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (prev, curr) =>
          prev.navigationState != curr.navigationState,
      listener: (context, state) {
        if (state.navigationState == SplashNavigationState.navigateToHome) {
          Navigator.restorablePushNamedAndRemoveUntil(
              context, 'menu_principal', (route) => false);
        } else if (state.navigationState ==
            SplashNavigationState.navigateToLogin) {
          Navigator.restorablePushNamedAndRemoveUntil(
              context, 'login', (route) => false);
        }
      },
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
              ),
              child: const Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SpinningLogo(),
                        SizedBox(height: 48),
                        _SplashTitle(),
                        SizedBox(height: 8),
                        _SplashSubtitle(),
                        SizedBox(height: 32),
                        _MatrixPercent(),
                      ],
                    ),
                  ),
                  _AdornoSplash(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo giratorio
// ---------------------------------------------------------------------------

/// Logo circular con sombra que gira continuamente hasta que el progreso
/// alcanza el 100%, momento en el que se detiene suavemente.
class _SpinningLogo extends StatefulWidget {
  const _SpinningLogo();

  @override
  State<_SpinningLogo> createState() => _SpinningLogoState();
}

class _SpinningLogoState extends State<_SpinningLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (prev, curr) => prev.progress != curr.progress,
      listener: (context, state) {
        if (state.progress >= 1.0) {
          // Terminar la rotación suavemente al llegar al 100%
          _controller.animateTo(
            1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      },
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.logoCircleBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.logoCircleShadow,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/arji/logo_arji.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Textos
// ---------------------------------------------------------------------------

/// Título principal.
class _SplashTitle extends StatelessWidget {
  const _SplashTitle();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Text(
      AppStrings.appName,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

/// Subtítulo descriptivo.
class _SplashSubtitle extends StatelessWidget {
  const _SplashSubtitle();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Text(
      AppStrings.appDescription,
      style: TextStyle(
        fontSize: 14,
        color: color.withValues(alpha: 0.7),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Porcentaje estilo Matrix
// ---------------------------------------------------------------------------

/// Muestra el porcentaje de carga con tipografía monoespaciada estilo Matrix
/// usando los colores del tema de la aplicación.
class _MatrixPercent extends StatelessWidget {
  const _MatrixPercent();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return BlocBuilder<SplashBloc, SplashState>(
      buildWhen: (prev, curr) => prev.progress != curr.progress,
      builder: (context, state) {
        final String text =
            '${state.progressPercent.toString().padLeft(3, '0')}%';

        return Text(
          text,
          style: GoogleFonts.shareTechMono(
            fontSize: 28,
            color: color,
            letterSpacing: 6,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.9), blurRadius: 4),
              Shadow(color: color.withValues(alpha: 0.6), blurRadius: 14),
              Shadow(color: color.withValues(alpha: 0.2), blurRadius: 24),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Adorno de la temporada
// ---------------------------------------------------------------------------

/// El motivo del mes, al pie del splash.
///
/// **Muy transparente a propósito.** El splash dura dos segundos y lo que el
/// usuario mira es el logo y el porcentaje; el adorno está para que se note el
/// mes de reojo, no para competir. A opacidad plena, sobre el degradado marrón,
/// se comía la pantalla.
///
/// Va como widget aparte, igual que `_SpinningLogo` o `_MatrixPercent`, para no
/// añadir otro nivel de anidación dentro del `Stack`.
///
/// Fuera de temporada `AdornoEstacional` no ocupa nada, así que siete meses al
/// año el splash queda exactamente como estaba.
class _AdornoSplash extends StatelessWidget {
  const _AdornoSplash();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 28),
        child: AdornoEstacional(alto: 30, opacidad: 0.3),
      ),
    );
  }
}
