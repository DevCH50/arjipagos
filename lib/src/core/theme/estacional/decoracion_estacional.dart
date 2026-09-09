import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/theme/estacional/temporada.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// La decoración de la temporada, colgada del tema.
///
/// ## Por qué una `ThemeExtension` y no una constante global
///
/// Es la primera `ThemeExtension` del proyecto, y se eligió por tres razones
/// concretas, no por seguir la moda:
///
/// 1. **Los widgets no preguntan qué mes es.** Piden
///    `Theme.of(context).extension<DecoracionEstacional>()` y pintan lo que se
///    les diga. No hay ni un `if (mes == 9)` repartido por la app, que es
///    justamente lo que convierte una decoración en un problema de
///    mantenimiento.
/// 2. **Claro y oscuro salen solos.** La extensión se adjunta dentro de
///    `AppTheme._buildTheme`, por donde pasan los seis temas —claro, oscuro y
///    sus variantes de contraste—, y cada uno recibe la paleta que le toca.
/// 3. **Los tests fuerzan la temporada sin tocar el reloj.** Basta con
///    `AppTheme.light.copyWith(extensions: [DecoracionEstacional.de(Temporada.navidad)])`.
///    Sin esto habría que mockear `DateTime.now()`, y los tests pasarían o
///    fallarían según el mes en que se ejecutaran.
///
/// ## Cuándo se decide la temporada
///
/// Al construir el tema, o sea **al arrancar la app**. Quien la deje abierta
/// durante la medianoche del 30 de septiembre seguirá viendo el papel picado
/// hasta que la vuelva a abrir. Es aceptable y no merece un temporizador
/// vigilando el cambio de día: nadie deja una app de pagos abierta esperando a
/// que cambie el mes.
///
/// ## Los colores no son los de la app
///
/// Ninguna paleta toca `primary`, `error`, `success` ni ningún color funcional.
/// Son colores propios de la decoración y solo se usan para adornar, así que
/// **ningún estado de la app puede volverse ilegible o ambiguo** por culpa del
/// mes en que se mire.
@immutable
class DecoracionEstacional extends ThemeExtension<DecoracionEstacional> {
  /// La fecha que se está celebrando.
  final Temporada temporada;

  /// Colores del listón y del motivo, en el orden en que se pintan.
  ///
  /// Siempre son tres: es lo que necesitan tanto el degradado del listón como
  /// la alternancia de los banderines del papel picado.
  final List<Color> colores;

  /// Qué se dibuja.
  final MotivoEstacional motivo;

  const DecoracionEstacional({
    required this.temporada,
    required this.colores,
    required this.motivo,
  });

  /// La decoración de hoy.
  ///
  /// **Es el único sitio de toda la función que llama a `DateTime.now()`.** La
  /// regla de calendario vive en [temporadaDe], que recibe la fecha por
  /// parámetro justamente para no depender del reloj.
  ///
  /// [kTemporadaForzada] solo se respeta en depuración: sirve para mirar
  /// diciembre en septiembre durante el desarrollo, y aunque se colara al
  /// repositorio no afectaría a ningún usuario.
  factory DecoracionEstacional.deHoy({
    Brightness brillo = Brightness.light,
  }) {
    final Temporada temporada = (kDebugMode && kTemporadaForzada != null)
        ? kTemporadaForzada!
        : temporadaDe(DateTime.now());
    return DecoracionEstacional.de(temporada, brillo: brillo);
  }

  /// La decoración de una temporada concreta. Lo usan los tests y la
  /// previsualización.
  factory DecoracionEstacional.de(
    Temporada temporada, {
    Brightness brillo = Brightness.light,
  }) {
    if (temporada == Temporada.ninguna) {
      return const DecoracionEstacional(
        temporada: Temporada.ninguna,
        colores: <Color>[],
        motivo: MotivoEstacional.ninguno,
      );
    }
    return DecoracionEstacional(
      temporada: temporada,
      colores: brillo == Brightness.dark
          ? _paletasOscuras[temporada]!
          : _paletasClaras[temporada]!,
      motivo: _motivos[temporada]!,
    );
  }

  /// `false` los siete meses que no celebran nada.
  ///
  /// Los widgets lo consultan para devolver lo que había antes de todo esto en
  /// lugar de un adorno vacío.
  bool get hayDecoracion => temporada != Temporada.ninguna;

  /// Cómo lo anuncia un lector de pantalla.
  ///
  /// Es un adorno, no contenido: se nombra como tal para que quien navegue con
  /// TalkBack o VoiceOver sepa que no se está perdiendo información.
  String get etiquetaAccesible => switch (temporada) {
    Temporada.ninguna => '',
    Temporada.patria => AppStrings.decoracionPatria,
    Temporada.muertos => AppStrings.decoracionMuertos,
    Temporada.navidad => AppStrings.decoracionNavidad,
    Temporada.amistad => AppStrings.decoracionAmistad,
    Temporada.primavera => AppStrings.decoracionPrimavera,
    Temporada.ninez => AppStrings.decoracionNinez,
    Temporada.madres => AppStrings.decoracionMadres,
  };

  @override
  DecoracionEstacional copyWith({
    Temporada? temporada,
    List<Color>? colores,
    MotivoEstacional? motivo,
  }) {
    return DecoracionEstacional(
      temporada: temporada ?? this.temporada,
      colores: colores ?? this.colores,
      motivo: motivo ?? this.motivo,
    );
  }

  /// Interpola con [other] al cambiar de tema.
  ///
  /// **Solo los colores interpolan.** La temporada y el motivo son discretos:
  /// no existe «medio papel picado», así que saltan a la mitad de la animación.
  /// Es lo que recomienda el propio contrato de `ThemeExtension` para campos que
  /// no son numéricos.
  ///
  /// Si las paletas no miden lo mismo —pasa al entrar o salir de
  /// [Temporada.ninguna], que no tiene colores— no hay nada que interpolar y se
  /// salta también.
  @override
  DecoracionEstacional lerp(
    covariant ThemeExtension<DecoracionEstacional>? other,
    double t,
  ) {
    if (other is! DecoracionEstacional) {
      return this;
    }
    if (colores.length != other.colores.length) {
      return t < 0.5 ? this : other;
    }
    return DecoracionEstacional(
      temporada: t < 0.5 ? temporada : other.temporada,
      motivo: t < 0.5 ? motivo : other.motivo,
      colores: <Color>[
        for (int i = 0; i < colores.length; i++)
          Color.lerp(colores[i], other.colores[i], t)!,
      ],
    );
  }

  // `==` y `hashCode` a mano: el `CustomPainter` del motivo los usa en su
  // `shouldRepaint` para no repintar en cada cuadro.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecoracionEstacional &&
          other.temporada == temporada &&
          other.motivo == motivo &&
          listEquals(other.colores, colores);

  @override
  int get hashCode => Object.hash(temporada, motivo, Object.hashAll(colores));
}

/// Lo que se dibuja en cada temporada.
enum MotivoEstacional {
  /// Nada. Los siete meses sin fiesta.
  ninguno,

  /// Banderines de papel picado colgando de un hilo.
  papelPicado,

  /// Flores de cempasúchil.
  cempasuchil,

  /// Rama de pino con esferas.
  ramaNavidad,

  /// Corazones.
  corazones,

  /// Flores abiertas.
  flores,

  /// Papalotes con cola.
  papalotes,

  /// Flores con tallo y hoja.
  floresConTallo,
}

/// Paleta de cada temporada sobre fondo claro.
///
/// Son tres colores siempre, en el orden en que se pintan de izquierda a
/// derecha. Los del mes patrio son los oficiales de la bandera mexicana; el
/// resto son tonos convencionales de cada fecha, elegidos con suficiente
/// saturación para leerse a 15 px de alto.
const Map<Temporada, List<Color>> _paletasClaras = <Temporada, List<Color>>{
  Temporada.patria: <Color>[
    Color(0xFF006847), // Verde bandera
    Color(0xFFF7F7F7), // Blanco roto: el blanco puro desaparece sobre la
    Color(0xFFCE1126), // superficie clara de la app.
  ],
  Temporada.muertos: <Color>[
    Color(0xFFFF6D00), // Naranja cempasúchil
    Color(0xFF6A1B9A), // Morado de altar
    Color(0xFFE91E63), // Rosa mexicano
  ],
  // **El dorado va EN MEDIO, y no es un capricho.** Con el rojo pegado al
  // verde —el orden de hasta el 2026-09-09— el degradado de la franja pasa por
  // el punto medio de dos complementarios, que es un **café sucio**: el vivo
  // parecía otoño mal impreso, no navidad. Con el dorado en medio las dos
  // transiciones son limpias: verde→dorado por oliva, dorado→rojo por naranja.
  // El verde tiene que seguir siendo el primero: es el color de la guirnalda.
  Temporada.navidad: <Color>[
    Color(0xFF1B5E20), // Verde pino
    Color(0xFFC8A02C), // Dorado
    Color(0xFFC62828), // Rojo
  ],
  Temporada.amistad: <Color>[
    Color(0xFFD81B60),
    Color(0xFFF06292),
    Color(0xFFE53935),
  ],
  Temporada.primavera: <Color>[
    Color(0xFF43A047), // Verde hoja
    Color(0xFFFBC02D), // Amarillo
    Color(0xFFEC7FA6), // Rosa
  ],
  Temporada.ninez: <Color>[
    Color(0xFF00ACC1), // Turquesa
    Color(0xFFFFB300), // Amarillo
    Color(0xFFEF5350), // Coral
  ],
  Temporada.madres: <Color>[
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF43A047),
  ],
};

/// Paleta de cada temporada sobre fondo oscuro.
///
/// No son los mismos colores aclarados sin más: los tonos profundos —el verde
/// bandera, el morado de altar, el verde pino— se pierden contra un fondo
/// oscuro, así que suben bastante de luminosidad, mientras que los ya claros
/// apenas cambian. El blanco del mes patrio baja a gris claro para no deslumbrar
/// en la penumbra, que es cuando se usa el tema oscuro.
const Map<Temporada, List<Color>> _paletasOscuras = <Temporada, List<Color>>{
  Temporada.patria: <Color>[
    Color(0xFF2E9E76),
    Color(0xFFDCDCDC),
    Color(0xFFE8555F),
  ],
  Temporada.muertos: <Color>[
    Color(0xFFFF9142),
    Color(0xFF9C5BC7),
    Color(0xFFF06292),
  ],
  // Mismo orden que en claro, y por el mismo motivo: el dorado separa el verde
  // del rojo para que el degradado no se enlode.
  Temporada.navidad: <Color>[
    Color(0xFF4CAF50),
    Color(0xFFE5C158),
    Color(0xFFEF5350),
  ],
  Temporada.amistad: <Color>[
    Color(0xFFF06292),
    Color(0xFFF8A5C0),
    Color(0xFFEF5350),
  ],
  Temporada.primavera: <Color>[
    Color(0xFF81C784),
    Color(0xFFFFE082),
    Color(0xFFF8BBD0),
  ],
  Temporada.ninez: <Color>[
    Color(0xFF4DD0E1),
    Color(0xFFFFD54F),
    Color(0xFFFF8A65),
  ],
  Temporada.madres: <Color>[
    Color(0xFFF06292),
    Color(0xFFCE93D8),
    Color(0xFF81C784),
  ],
};

/// Qué motivo le toca a cada temporada.
const Map<Temporada, MotivoEstacional> _motivos =
    <Temporada, MotivoEstacional>{
      Temporada.patria: MotivoEstacional.papelPicado,
      Temporada.muertos: MotivoEstacional.cempasuchil,
      Temporada.navidad: MotivoEstacional.ramaNavidad,
      Temporada.amistad: MotivoEstacional.corazones,
      Temporada.primavera: MotivoEstacional.flores,
      Temporada.ninez: MotivoEstacional.papalotes,
      Temporada.madres: MotivoEstacional.floresConTallo,
    };
