import 'dart:math' as math;

import 'package:arjipagos/src/core/theme/estacional/decoracion_estacional.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Dibuja el motivo de la temporada.
///
/// **Es el primer `CustomPainter` del proyecto**, así que va comentado de más.
///
/// ## Por qué se dibuja en vez de usar imágenes
///
/// Siete motivos por dos temas y por cinco densidades de pantalla serían setenta
/// PNG que habría que dar de alta uno a uno en `pubspec.yaml` y en
/// `test/unit/assets_declarados_test.dart`. Dibujándolos: **cero peso en el
/// APK**, nítidos en cualquier densidad, y el color sale del tema en vez de
/// estar quemado en el archivo.
///
/// ## Cómo está organizado
///
/// Todos los motivos son **un patrón que se repite a lo ancho**, así que el
/// bucle está una sola vez, en [_repetir]: calcula cuántas copias caben, reparte
/// el ancho sobrante para que ninguna quede cortada al borde, y llama al
/// dibujante de turno con el centro y el color que le tocan. Cada motivo solo
/// tiene que saber pintarse a sí mismo dentro de la celda que le dan.
class MotivoEstacionalPainter extends CustomPainter {
  /// Qué se dibuja.
  final MotivoEstacional motivo;

  /// Los tres colores de la temporada. Se van alternando entre copias.
  final List<Color> colores;

  /// Cuánto se transparenta todo.
  ///
  /// El listón del menú lo pinta opaco; el splash lo usa muy bajo, para que el
  /// motivo sugiera sin competir con el logo.
  final double opacidad;

  /// Color para los trazos de soporte: el hilo del papel picado y la rama de
  /// navidad.
  ///
  /// Lo pasa el widget desde el `ColorScheme`, y por eso el hilo se ve tanto
  /// sobre el fondo claro como sobre el oscuro. Antes se usaba el primer color
  /// de la temporada y en septiembre quedaba un hilo verde, que no es un hilo.
  final Color colorTrazo;

  const MotivoEstacionalPainter({
    required this.motivo,
    required this.colores,
    required this.colorTrazo,
    this.opacidad = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (motivo == MotivoEstacional.ninguno ||
        colores.isEmpty ||
        size.isEmpty) {
      return;
    }

    switch (motivo) {
      case MotivoEstacional.papelPicado:
        _papelPicado(canvas, size);
      case MotivoEstacional.cempasuchil:
        _repetir(canvas, size, 20, _flor(petalos: 8, redondas: true));
      case MotivoEstacional.ramaNavidad:
        _ramaNavidad(canvas, size);
      case MotivoEstacional.corazones:
        _repetir(canvas, size, 20, _corazon);
      case MotivoEstacional.flores:
        _repetir(canvas, size, 22, _flor(petalos: 5, redondas: false));
      case MotivoEstacional.papalotes:
        _repetir(canvas, size, 24, _papalote);
      case MotivoEstacional.floresConTallo:
        _repetir(canvas, size, 22, _florConTallo);
      case MotivoEstacional.ninguno:
        return;
    }
  }

  // ==========================================================================
  // EL BUCLE COMÚN
  // ==========================================================================

  /// Repite [dibujar] a lo ancho de [size].
  ///
  /// [anchoNominal] es el ancho que le gustaría tener a cada copia. El real se
  /// ajusta hacia arriba o hacia abajo para que quepa un número entero: así
  /// **ninguna copia queda cortada por el borde**, que es lo que delata a un
  /// patrón mal hecho.
  void _repetir(
    Canvas canvas,
    Size size,
    double anchoNominal,
    void Function(Canvas canvas, Offset centro, double lado, Paint pincel)
    dibujar,
  ) {
    final int cuantos = math.max(1, (size.width / anchoNominal).round());
    final double ancho = size.width / cuantos;
    // El lado disponible lo manda el alto, que siempre es el más apretado: el
    // listón mide 15 px y el ancho de la pantalla, cientos.
    final double lado = math.min(ancho, size.height) * 0.88;

    for (int i = 0; i < cuantos; i++) {
      final Offset centro = Offset(ancho * (i + 0.5), size.height / 2);
      dibujar(canvas, centro, lado, _pincel(colores[i % colores.length]));
    }
  }

  /// Pincel relleno del color pedido, ya con la opacidad aplicada.
  Paint _pincel(Color color) => Paint()
    ..color = color.withValues(alpha: color.a * opacidad)
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  // ==========================================================================
  // SEPTIEMBRE — PAPEL PICADO
  // ==========================================================================

  /// Banderines rectangulares colgando de un hilo, con el borde inferior
  /// festoneado y perforaciones, que es como es el papel picado de verdad.
  ///
  /// No usa [_repetir] porque necesita además el hilo del que cuelgan, y porque
  /// los banderines ocupan **todo el alto**, no una celda cuadrada.
  void _papelPicado(Canvas canvas, Size size) {
    const double anchoNominal = 26;
    final int cuantos = math.max(1, (size.width / anchoNominal).round());
    final double ancho = size.width / cuantos;
    final double alto = size.height * 0.9;

    // El hilo del que cuelgan, en el color de trazo del tema.
    canvas.drawLine(
      const Offset(0, 0.5),
      Offset(size.width, 0.5),
      Paint()
        ..color = colorTrazo.withValues(alpha: 0.45 * opacidad)
        ..strokeWidth = 1,
    );

    for (int i = 0; i < cuantos; i++) {
      final Color color = colores[i % colores.length];
      final Path banderin = _banderin(ancho * i, ancho, alto);
      canvas.drawPath(banderin, _pincel(color));
      // Contorno. **Sin esto el banderín blanco del mes patrio desaparece**
      // sobre el fondo crema de la app: se ven el verde y el rojo, y en medio
      // un hueco. El borde es el propio color oscurecido, así que en el blanco
      // sale gris y en los demás pasa desapercibido.
      canvas.drawPath(
        banderin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..isAntiAlias = true
          ..color = _oscurecer(color).withValues(alpha: 0.5 * opacidad),
      );
    }
  }

  /// Un banderín: rectángulo colgando, con el borde inferior recortado en
  /// dientes y una perforación en medio.
  ///
  /// El borde va en **zigzag y no en arcos**. Con arcos, a 15 px de alto, los
  /// entrantes se comían el cuerpo y cada banderín parecía un par de flechas
  /// enfrentadas. El zigzag se lee como papel recortado incluso así de pequeño.
  Path _banderin(double x, double ancho, double alto) {
    final double margen = ancho * 0.13;
    final double izq = x + margen;
    final double der = x + ancho - margen;
    final double base = alto * 0.82;

    const int dientes = 3;
    final double paso = (der - izq) / dientes;
    final double hondura = alto * 0.16;

    final Path cuerpo = Path()
      ..moveTo(izq, 0)
      ..lineTo(der, 0)
      ..lineTo(der, base);
    // De derecha a izquierda, subiendo y bajando en cada diente.
    for (int d = 0; d < dientes; d++) {
      cuerpo
        ..lineTo(der - paso * (d + 0.5), base - hondura)
        ..lineTo(der - paso * (d + 1), base);
    }
    cuerpo
      ..lineTo(izq, 0)
      ..close();

    // Una sola perforación, un rombo. A este tamaño dos ya no se distinguen y
    // solo ensucian la silueta.
    final Path hueco = _rombo(
      Offset((izq + der) / 2, alto * 0.38),
      ancho * 0.16,
    );

    return Path.combine(PathOperation.difference, cuerpo, hueco);
  }

  /// El color, más oscuro. Sirve para sacarle un contorno a un relleno claro.
  Color _oscurecer(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor();
  }

  Path _rombo(Offset centro, double radio) => Path()
    ..moveTo(centro.dx, centro.dy - radio)
    ..lineTo(centro.dx + radio, centro.dy)
    ..lineTo(centro.dx, centro.dy + radio)
    ..lineTo(centro.dx - radio, centro.dy)
    ..close();

  // ==========================================================================
  // DICIEMBRE — RAMA CON ESFERAS
  // ==========================================================================

  /// Una rama horizontal con púas alternas y esferas colgando.
  ///
  /// Tampoco usa [_repetir]: la rama es continua de lado a lado, y lo que se
  /// repite son las púas y las esferas sobre ella.
  void _ramaNavidad(Canvas canvas, Size size) {
    final double y = size.height * 0.3;
    final Paint rama = Paint()
      ..color = colores.first.withValues(alpha: opacidad)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), rama);

    const double paso = 9;
    final int cuantas = math.max(1, (size.width / paso).round());
    final double ancho = size.width / cuantas;
    final double largoPua = size.height * 0.34;

    for (int i = 0; i < cuantas; i++) {
      final double x = ancho * (i + 0.5);
      // Las púas se abren en abanico: se inclinan más cuanto más lejos del
      // centro de su grupo, como las agujas de una rama de pino.
      final double sesgo = (i.isEven ? 1 : -1) * ancho * 0.45;
      canvas.drawLine(Offset(x, y), Offset(x + sesgo, y + largoPua), rama);

      // Una esfera cada tres púas, para que no se amontonen.
      if (i % 3 == 1) {
        final double radio = size.height * 0.16;
        canvas.drawCircle(
          Offset(x, y + largoPua + radio * 0.7),
          radio,
          _pincel(colores[(i ~/ 3 + 1) % colores.length]),
        );
      }
    }
  }

  // ==========================================================================
  // MOTIVOS DE CELDA
  // ==========================================================================

  /// Flor de [petalos] pétalos alrededor de un cogollo.
  ///
  /// Con [redondas] los pétalos son círculos apretados —el cempasúchil, que es
  /// una flor tupida—; sin ello son óvalos abiertos, más de flor de primavera.
  void Function(Canvas, Offset, double, Paint) _flor({
    required int petalos,
    required bool redondas,
  }) {
    return (Canvas canvas, Offset centro, double lado, Paint pincel) {
      final double radio = lado / 2;
      for (int p = 0; p < petalos; p++) {
        final double angulo = 2 * math.pi * p / petalos;
        final Offset donde = centro +
            Offset(math.cos(angulo), math.sin(angulo)) * radio * 0.58;
        if (redondas) {
          canvas.drawCircle(donde, radio * 0.42, pincel);
        } else {
          canvas.save();
          canvas.translate(donde.dx, donde.dy);
          canvas.rotate(angulo);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: radio * 0.9,
              height: radio * 0.5,
            ),
            pincel,
          );
          canvas.restore();
        }
      }
      // El cogollo, un punto más claro para que la flor no sea una mancha.
      canvas.drawCircle(
        centro,
        radio * 0.3,
        Paint()..color = pincel.color.withValues(alpha: 0.45 * opacidad),
      );
    };
  }

  /// Flor con tallo y una hoja. Mayo.
  void _florConTallo(Canvas canvas, Offset centro, double lado, Paint pincel) {
    final double radio = lado / 2;
    final Offset pie = Offset(centro.dx, centro.dy + radio);
    final Offset cabeza = Offset(centro.dx, centro.dy - radio * 0.2);

    final Paint trazo = Paint()
      ..color = pincel.color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pie, cabeza, trazo);
    // La hoja: un arco que sale del tallo a media altura.
    canvas.drawPath(
      Path()
        ..moveTo(centro.dx, centro.dy + radio * 0.4)
        ..quadraticBezierTo(
          centro.dx + radio * 0.7,
          centro.dy + radio * 0.2,
          centro.dx + radio * 0.1,
          centro.dy - radio * 0.05,
        ),
      trazo,
    );
    _flor(petalos: 5, redondas: false)(canvas, cabeza, lado * 0.75, pincel);
  }

  /// Un corazón. Febrero.
  void _corazon(Canvas canvas, Offset centro, double lado, Paint pincel) {
    final double r = lado / 2;
    // Dos lóbulos arriba y una punta abajo, con curvas cúbicas.
    final Path corazon = Path()
      ..moveTo(centro.dx, centro.dy + r * 0.75)
      ..cubicTo(
        centro.dx - r * 1.5, centro.dy - r * 0.1,
        centro.dx - r * 0.5, centro.dy - r * 1.2,
        centro.dx, centro.dy - r * 0.4,
      )
      ..cubicTo(
        centro.dx + r * 0.5, centro.dy - r * 1.2,
        centro.dx + r * 1.5, centro.dy - r * 0.1,
        centro.dx, centro.dy + r * 0.75,
      )
      ..close();
    canvas.drawPath(corazon, pincel);
  }

  /// Un papalote con su cola. Abril.
  void _papalote(Canvas canvas, Offset centro, double lado, Paint pincel) {
    final double r = lado * 0.42;
    final Offset alto = Offset(centro.dx, centro.dy - r * 1.1);
    final Offset bajo = Offset(centro.dx, centro.dy + r * 0.7);

    canvas.drawPath(
      Path()
        ..moveTo(alto.dx, alto.dy)
        ..lineTo(centro.dx + r * 0.75, centro.dy - r * 0.1)
        ..lineTo(bajo.dx, bajo.dy)
        ..lineTo(centro.dx - r * 0.75, centro.dy - r * 0.1)
        ..close(),
      pincel,
    );

    // La cola: una ese corta con dos moños.
    final Paint cola = Paint()
      ..color = pincel.color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(bajo.dx, bajo.dy)
        ..quadraticBezierTo(
          centro.dx + r * 0.5, centro.dy + r * 1.1,
          centro.dx, centro.dy + r * 1.5,
        ),
      cola,
    );
    canvas.drawCircle(Offset(centro.dx + r * 0.3, centro.dy + r * 1.1), 1.2, pincel);
    canvas.drawCircle(Offset(centro.dx, centro.dy + r * 1.5), 1.2, pincel);
  }

  // ==========================================================================

  /// Solo repinta si cambia algo que se ve.
  ///
  /// Sin esto Flutter volvería a dibujar los banderines en cada cuadro de
  /// cualquier animación de la pantalla, que en el menú son unas cuantas.
  @override
  bool shouldRepaint(covariant MotivoEstacionalPainter anterior) =>
      anterior.motivo != motivo ||
      anterior.opacidad != opacidad ||
      anterior.colorTrazo != colorTrazo ||
      !listEquals(anterior.colores, colores);

  /// El motivo es decorativo: no aporta nada que un lector de pantalla deba
  /// recorrer. La etiqueta la pone el widget de arriba, una sola vez.
  @override
  bool shouldRebuildSemantics(covariant MotivoEstacionalPainter anterior) =>
      false;
}
