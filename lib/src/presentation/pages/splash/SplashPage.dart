import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashBloc.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
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
          Navigator.pushNamedAndRemoveUntil(
              context, 'menu_principal', (route) => false);
        } else if (state.navigationState ==
            SplashNavigationState.navigateToLogin) {
          Navigator.pushNamedAndRemoveUntil(
              context, 'login', (route) => false);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.splashGradientStart,
                AppColors.splashGradientEnd,
              ],
            ),
          ),
          child: const Center(
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
        ),
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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
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
    return const Text(
      'ArjiPagos',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

/// Subtítulo descriptivo.
class _SplashSubtitle extends StatelessWidget {
  const _SplashSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Plataforma de Gestión de Pagos',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white70,
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
    final colorScheme = Theme.of(context).colorScheme;

    // El splash siempre tiene fondo oscuro (degradado café). Elegimos el
    // token correcto según el modo activo para garantizar contraste:
    //   • Modo claro → inversePrimary: color primario para superficies oscuras/inversas.
    //   • Modo oscuro → primary: en el tema oscuro el primario ya es claro (#F0BB9E).
    final color = colorScheme.brightness == Brightness.dark
        ? colorScheme.primary
        : colorScheme.inversePrimary;

    return BlocBuilder<SplashBloc, SplashState>(
      buildWhen: (prev, curr) => prev.progress != curr.progress,
      builder: (context, state) {
        final String text =
            '${state.progressPercent.toString().padLeft(3, '0')} %';

        return Text(
          text,
          style: GoogleFonts.shareTechMono(
            fontSize: 28,
            color: color,
            letterSpacing: 6,
            shadows: [
              Shadow(color: color, blurRadius: 6),
              Shadow(color: color, blurRadius: 18),
              Shadow(color: color, blurRadius: 32),
            ],
          ),
        );
      },
    );
  }
}
