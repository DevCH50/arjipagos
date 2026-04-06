import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashBloc.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de splash/carga inicial de la aplicación.
///
/// El logo se escala a pantalla completa y se divide en 9 piezas (3×3).
/// Cada pieza parte del centro de la pantalla y vuela a su posición final,
/// cubriendo toda la pantalla al llegar al 100% de progreso.
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
          // Fondo degradado visible durante la fase inicial
          // (antes de que las piezas cubran la pantalla).
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
          child: const Stack(
            children: [
              // Piezas a pantalla completa
              Positioned.fill(child: _PuzzleLogoAnimation()),
              // Título y subtítulo sobre un scrim en la parte inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _SplashTextOverlay(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Datos de cada pieza
// ---------------------------------------------------------------------------

class _PieceInfo {
  final int row;
  final int col;
  final int staggerIndex;

  const _PieceInfo({
    required this.row,
    required this.col,
    required this.staggerIndex,
  });
}

// ---------------------------------------------------------------------------
// Widget principal de animación
// ---------------------------------------------------------------------------

/// Divide el logo en 9 piezas (3×3) que cubren toda la pantalla.
///
/// Todas las piezas parten del centro absoluto de la pantalla y vuelan
/// a sus posiciones finales. Las piezas más cercanas al centro animan
/// primero; las esquinas, al final. Al terminar el logo queda
/// ensamblado cubriendo la pantalla completa.
class _PuzzleLogoAnimation extends StatefulWidget {
  const _PuzzleLogoAnimation();

  @override
  State<_PuzzleLogoAnimation> createState() => _PuzzleLogoAnimationState();
}

class _PuzzleLogoAnimationState extends State<_PuzzleLogoAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const int _cols = 3;
  static const int _rows = 3;

  // Orden: pieza central primero (distancia Manhattan 0), esquinas al final.
  static final List<_PieceInfo> _pieces = _buildPieceOrder();

  static List<_PieceInfo> _buildPieceOrder() {
    final list = <MapEntry<double, (int, int)>>[];

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final dist =
            (r - (_rows - 1) / 2).abs() + (c - (_cols - 1) / 2).abs();
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
        _controller.animateTo(
          state.progress,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          // Cada pieza cubre una celda de la pantalla completa
          final pieceW = screenW / _cols;
          final pieceH = screenH / _rows;

          // Punto de inicio: centro de la pantalla (todas las piezas arrancan aquí)
          final startX = screenW / 2 - pieceW / 2;
          final startY = screenH / 2 - pieceH / 2;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: _pieces
                    .map((piece) => _buildPiece(
                          piece: piece,
                          screenW: screenW,
                          screenH: screenH,
                          pieceW: pieceW,
                          pieceH: pieceH,
                          startX: startX,
                          startY: startY,
                        ))
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }

  /// Construye una pieza con animación de posición y opacidad.
  Widget _buildPiece({
    required _PieceInfo piece,
    required double screenW,
    required double screenH,
    required double pieceW,
    required double pieceH,
    required double startX,
    required double startY,
  }) {
    const int total = _cols * _rows;

    // Ventana de progreso de cada pieza:
    // Pieza 0 (centro) → [0.00, 0.50]
    // Pieza 8 (esquina) → [0.40, 0.90]
    final double staggerStart = (piece.staggerIndex / (total - 1)) * 0.40;
    final double staggerEnd = staggerStart + 0.50;

    final double raw =
        (_controller.value - staggerStart) / (staggerEnd - staggerStart);
    final double pieceProgress = raw.clamp(0.0, 1.0);

    // Curva con rebote suave al aterrizar
    final double eased = Curves.easeOutBack.transform(pieceProgress);

    // Posición final: celda correspondiente en la cuadrícula de pantalla completa
    final double finalLeft = piece.col * pieceW;
    final double finalTop = piece.row * pieceH;

    // Interpolación desde el centro de la pantalla hasta la posición final
    final double currentLeft = startX + (finalLeft - startX) * eased;
    final double currentTop = startY + (finalTop - startY) * eased;

    // Opacidad: aparece en la primera mitad del recorrido
    final double opacity = (pieceProgress * 2).clamp(0.0, 1.0);

    // Alineación para recortar la porción correcta de la imagen a pantalla completa.
    // Align con constraints apretados (de Positioned) posiciona la imagen
    // completa (screenW × screenH) mostrando solo la porción de esta celda.
    final double alignX =
        _cols > 1 ? (-1.0 + piece.col * 2.0 / (_cols - 1)) : 0.0;
    final double alignY =
        _rows > 1 ? (-1.0 + piece.row * 2.0 / (_rows - 1)) : 0.0;

    return Positioned(
      left: currentLeft,
      top: currentTop,
      width: pieceW,
      height: pieceH,
      child: Opacity(
        opacity: opacity,
        child: ClipRect(
          child: Align(
            alignment: Alignment(alignX, alignY),
            child: Image.asset(
              'assets/arji/logo_arji.png',
              width: screenW,
              height: screenH,
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
// Texto inferior con scrim
// ---------------------------------------------------------------------------

/// Título y subtítulo sobre un degradado oscuro para legibilidad.
/// Aparecen con fade-in cuando el logo está casi ensamblado.
class _SplashTextOverlay extends StatelessWidget {
  const _SplashTextOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplashBloc, SplashState>(
      buildWhen: (prev, curr) => prev.progress != curr.progress,
      builder: (context, state) {
        // Fade-in entre progress 0.65 y 0.90
        final double opacity =
            ((state.progress - 0.65) / 0.25).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ArjiPagos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Plataforma de Gestión de Pagos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
