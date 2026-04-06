import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashBloc.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de splash/carga inicial de la aplicación.
///
/// Muestra el logo ensamblándose como un rompecabezas a pantalla completa:
/// cada pieza parte del centro de la pantalla y vuela hacia su posición final.
/// Al llegar al 100% la imagen queda totalmente armada.
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
          child: const Stack(
            children: [
              // Animación del rompecabezas a pantalla completa
              Positioned.fill(child: _PuzzleLogoAnimation()),
              // Título y subtítulo en la parte inferior
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: _SplashTextArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dimensiones calculadas una vez por layout
// ---------------------------------------------------------------------------

/// Contiene todas las medidas necesarias para posicionar las piezas.
class _SplashDimensions {
  final double logoSize;
  final double pieceSize;
  final double logoLeft;
  final double logoTop;
  final double startX; // x de inicio (centro pantalla − mitad pieza)
  final double startY; // y de inicio (centro pantalla − mitad pieza)

  const _SplashDimensions({
    required this.logoSize,
    required this.pieceSize,
    required this.logoLeft,
    required this.logoTop,
    required this.startX,
    required this.startY,
  });

  factory _SplashDimensions.from(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;

    // Logo cuadrado: 80 % del ancho o 52 % del alto, lo que sea menor
    final logoSize = (w * 0.80).clamp(0.0, h * 0.52);
    final pieceSize = logoSize / _PuzzleLogoAnimationState._cols;

    // Logo centrado horizontalmente, a 28 % desde arriba
    final logoLeft = (w - logoSize) / 2;
    final logoTop = h * 0.28;

    // Punto de inicio: centro absoluto de la pantalla
    final startX = w / 2 - pieceSize / 2;
    final startY = h / 2 - pieceSize / 2;

    return _SplashDimensions(
      logoSize: logoSize,
      pieceSize: pieceSize,
      logoLeft: logoLeft,
      logoTop: logoTop,
      startX: startX,
      startY: startY,
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
// Widget de animación a pantalla completa
// ---------------------------------------------------------------------------

/// Anima 9 piezas (3×3) del logo a pantalla completa.
///
/// Cada pieza parte del centro de la pantalla y vuela hasta su posición
/// definitiva en la cuadrícula del logo. Las piezas del centro animan
/// primero; las esquinas, al final.
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

  // Orden: centro primero (menor distancia Manhattan), esquinas al final
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
          final dims = _SplashDimensions.from(constraints);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: _pieces
                    .map((piece) => _buildPiece(piece, dims))
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }

  /// Construye una pieza posicionada y animada.
  Widget _buildPiece(_PieceInfo piece, _SplashDimensions dims) {
    const int total = _cols * _rows; // 9

    // Ventana de progreso de esta pieza.
    // Pieza 0 (centro): [0.0, 0.50] — pieza 8 (esquina): [0.40, 0.90]
    final double staggerStart = (piece.staggerIndex / (total - 1)) * 0.40;
    final double staggerEnd = staggerStart + 0.50;

    final double raw =
        (_controller.value - staggerStart) / (staggerEnd - staggerStart);
    final double pieceProgress = raw.clamp(0.0, 1.0);

    // Curva con rebote suave al aterrizar
    final double eased = Curves.easeOutBack.transform(pieceProgress);

    // Posición final de la pieza en el logo ensamblado
    final double finalLeft = dims.logoLeft + piece.col * dims.pieceSize;
    final double finalTop = dims.logoTop + piece.row * dims.pieceSize;

    // Interpolación: desde el centro de la pantalla hasta la posición final
    final double currentLeft = dims.startX + (finalLeft - dims.startX) * eased;
    final double currentTop = dims.startY + (finalTop - dims.startY) * eased;

    // Opacidad: aparece en la primera mitad del recorrido de la pieza
    final double opacity = (pieceProgress * 2).clamp(0.0, 1.0);

    // Alineación para recortar la porción correcta del logo
    final double alignX =
        _cols > 1 ? (-1.0 + piece.col * 2.0 / (_cols - 1)) : 0.0;
    final double alignY =
        _rows > 1 ? (-1.0 + piece.row * 2.0 / (_rows - 1)) : 0.0;

    return Positioned(
      left: currentLeft,
      top: currentTop,
      width: dims.pieceSize,
      height: dims.pieceSize,
      child: Opacity(
        opacity: opacity,
        child: ClipRect(
          // Align con constraints apretados (de Positioned) ubica la imagen
          // completa según la alineación, mostrando solo la porción de esta pieza.
          child: Align(
            alignment: Alignment(alignX, alignY),
            child: Image.asset(
              'assets/arji/logo_arji.png',
              width: dims.logoSize,
              height: dims.logoSize,
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
// Área de texto inferior con fade-in
// ---------------------------------------------------------------------------

/// Título y subtítulo que aparecen con fade-in cuando el logo está casi armado.
class _SplashTextArea extends StatelessWidget {
  const _SplashTextArea();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplashBloc, SplashState>(
      buildWhen: (prev, curr) => prev.progress != curr.progress,
      builder: (context, state) {
        // Aparece entre progress 0.65 y 0.90
        final double opacity =
            ((state.progress - 0.65) / 0.25).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
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
        );
      },
    );
  }
}
