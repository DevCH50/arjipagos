import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashBloc.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de splash/carga inicial de la aplicación.
///
/// Muestra el logo ensamblándose como un rompecabezas mientras se
/// inicializan las dependencias y se verifica la sesión del usuario.
/// Cada pieza cae desde el centro hacia su posición final.
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
      listenWhen: (previous, current) =>
          previous.navigationState != current.navigationState,
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
                _PuzzleLogoAnimation(),
                SizedBox(height: 48),
                _SplashTitle(),
                SizedBox(height: 8),
                _SplashSubtitle(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Datos de cada pieza del rompecabezas
// ---------------------------------------------------------------------------

/// Información de posición y orden de animación de una pieza del logo.
class _PieceInfo {
  final int row;
  final int col;

  /// Índice de stagger (0 = anima primero, n-1 = anima último).
  final int staggerIndex;

  const _PieceInfo({
    required this.row,
    required this.col,
    required this.staggerIndex,
  });
}

// ---------------------------------------------------------------------------
// Widget de animación de rompecabezas
// ---------------------------------------------------------------------------

/// Anima el logo dividiéndolo en 9 piezas (3×3) que caen desde el
/// centro hacia sus posiciones finales, ensamblando la imagen completa
/// al llegar al 100% de progreso.
///
/// Las piezas más cercanas al centro animan primero; las esquinas, al final.
class _PuzzleLogoAnimation extends StatefulWidget {
  const _PuzzleLogoAnimation();

  @override
  State<_PuzzleLogoAnimation> createState() => _PuzzleLogoAnimationState();
}

class _PuzzleLogoAnimationState extends State<_PuzzleLogoAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ---- constantes de cuadrícula ----
  static const int _cols = 3;
  static const int _rows = 3;
  static const double _logoSize = 100.0;
  static const double _pieceSize = _logoSize / _cols; // 33.33…

  // Orden de piezas: centro primero, esquinas al final (por distancia Manhattan)
  static final List<_PieceInfo> _pieces = _buildPieceOrder();

  static List<_PieceInfo> _buildPieceOrder() {
    final list = <MapEntry<double, (int, int)>>[];

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final dist = (r - (_rows - 1) / 2).abs() + (c - (_cols - 1) / 2).abs();
        list.add(MapEntry(dist, (r, c)));
      }
    }

    list.sort((a, b) => a.key.compareTo(b.key));

    return list.indexed
        .map((e) => _PieceInfo(
              row: e.$2.value.$1,
              col: e.$2.value.$2,
              staggerIndex: e.$1,
            ))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
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
        // Animar el controlador hasta el progreso actual del BLoC.
        // Cada actualización del BLoC lleva el controlador suavemente
        // al nuevo valor (200 ms de transición).
        _controller.animateTo(
          state.progress,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      },
      child: Container(
        width: 130,
        height: 130,
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
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                width: _logoSize,
                height: _logoSize,
                child: Stack(
                  // clipBehavior none para que las piezas puedan sobrepasar
                  // levemente el borde del Stack durante la animación easeOutBack.
                  clipBehavior: Clip.none,
                  children: _pieces.map(_buildPiece).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Construye una pieza del rompecabezas con su animación de posición y opacidad.
  Widget _buildPiece(_PieceInfo piece) {
    const int totalPieces = _cols * _rows; // 9

    // Ventana de progreso de esta pieza dentro del rango [0, 1].
    // La pieza 0 (centro) comienza en t=0.0 y termina en t=0.50.
    // La pieza 8 (esquina) comienza en t=0.40 y termina en t=0.90.
    // A partir de t=0.90 todas las piezas ya están en su lugar.
    final double staggerStart =
        (piece.staggerIndex / (totalPieces - 1)) * 0.40;
    final double staggerEnd = staggerStart + 0.50;

    // Progreso normalizado de esta pieza: 0.0 → 1.0
    final double raw = (_controller.value - staggerStart) /
        (staggerEnd - staggerStart);
    final double pieceProgress = raw.clamp(0.0, 1.0);

    // Curva easeOutBack: da un efecto de rebote suave al aterrizar.
    final double eased = Curves.easeOutBack.transform(pieceProgress);

    // Posición final de la pieza en el Stack
    final double finalLeft = piece.col * _pieceSize;
    final double finalTop = piece.row * _pieceSize;

    // Posición de inicio: todas las piezas parten del centro del logo
    const double startLeft = _logoSize / 2 - _pieceSize / 2;
    const double startTop = _logoSize / 2 - _pieceSize / 2;

    // Interpolación posición (inicio → final)
    final double currentLeft = startLeft + (finalLeft - startLeft) * eased;
    final double currentTop = startTop + (finalTop - startTop) * eased;

    // Opacidad: aparece progresivamente en la primera mitad del recorrido
    final double opacity = (pieceProgress * 2).clamp(0.0, 1.0);

    // Alineación para recortar la porción correcta del logo completo
    final double alignX =
        _cols > 1 ? (-1.0 + piece.col * 2.0 / (_cols - 1)) : 0.0;
    final double alignY =
        _rows > 1 ? (-1.0 + piece.row * 2.0 / (_rows - 1)) : 0.0;

    return Positioned(
      left: currentLeft,
      top: currentTop,
      width: _pieceSize,
      height: _pieceSize,
      child: Opacity(
        opacity: opacity,
        child: ClipRect(
          // Align con constraints apretados (de Positioned) posiciona la
          // imagen completa (_logoSize) según la alineación, mostrando
          // solo la porción correspondiente a esta pieza.
          child: Align(
            alignment: Alignment(alignX, alignY),
            child: Image.asset(
              'assets/arji/logo_arji.png',
              width: _logoSize,
              height: _logoSize,
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets de texto
// ---------------------------------------------------------------------------

/// Título principal de la app.
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
