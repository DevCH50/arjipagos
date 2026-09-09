/// La regla de calendario de la decoración estacional.
///
/// Este archivo **no importa Flutter a propósito**: es aritmética de fechas y
/// nada más. Lo visual —colores y motivos— vive en `decoracion_estacional.dart`,
/// y así la regla se puede probar entera sin montar un solo widget.
///
/// ## Por qué la fecha entra por parámetro
///
/// [temporadaDe] recibe la fecha, no la lee. Un `DateTime.now()` aquí dentro
/// obligaría a mockear el reloj para probar diciembre, y los tests dependerían
/// del mes en que se ejecuten: en septiembre pasarían y en octubre fallarían
/// solos. Quien necesita la fecha real es `DecoracionEstacional.deHoy()`, que es
/// el único sitio de todo esto que llama a `DateTime.now()`.
library;

/// Las fechas que decoran la app.
///
/// Solo están los meses que celebran algo en un colegio mexicano. Los demás
/// —enero, junio, julio, agosto y octubre— caen en [Temporada.ninguna], que no
/// es un caso raro ni un error: es el estado normal de la app siete meses al
/// año.
enum Temporada {
  /// Sin decoración. La app se ve exactamente como si nada de esto existiera.
  ninguna,

  /// Septiembre — mes patrio.
  patria,

  /// Noviembre — día de muertos.
  muertos,

  /// Diciembre — navidad.
  navidad,

  /// Febrero — día del amor y la amistad.
  amistad,

  /// Marzo — bienvenida a la primavera (21 de marzo).
  ///
  /// Decidido con Carlos el 2026-09-08: cae el mismo día que el natalicio de
  /// Juárez, pero en preescolar y primaria la fiesta que se celebra es la
  /// primavera.
  primavera,

  /// Abril — día del niño.
  ninez,

  /// Mayo — día de la madre y del maestro.
  madres,
}

/// **El interruptor general de la decoración estacional.**
///
/// En `false`, [temporadaDe] devuelve [Temporada.ninguna] los doce meses y la
/// app queda **exactamente** como estaba antes de todo esto: el listón vuelve a
/// ser el `Divider` de siempre, el splash pierde su motivo y la tirilla de
/// avisos su adorno. Ni un píxel de diferencia.
///
/// Es el primer nivel de marcha atrás, y está pensado para usarse sin pensar: si
/// algo se ve mal en producción, se cambia esta línea y se publica. El segundo
/// nivel es tirar el trabajo entero con
/// `git reset --hard antes-decoracion-estacional`.
///
/// Hay un test que comprueba que apagarlo deja los doce meses sin decorar.
const bool kDecoracionEstacionalActivada = true;

/// Fuerza una temporada para **poder verla sin esperar a que llegue el mes**.
///
/// Solo surte efecto en compilaciones de depuración (lo comprueba
/// `DecoracionEstacional.deHoy()` con `kDebugMode`), así que aunque se colara a
/// producción no cambiaría nada para el usuario. Aun así **tiene que estar en
/// `null` en el repositorio**, y hay un test que lo vigila: dejarlo puesto
/// significaría que quien arranque la app en `flutter run` vería diciembre en
/// abril y perdería un rato averiguando por qué.
///
/// Uso: ponerlo en la temporada que se quiera mirar, hot reload, y devolverlo a
/// `null` al terminar.
const Temporada? kTemporadaForzada = null;

/// La temporada que corresponde a [fecha].
///
/// [activada] existe para que el test del interruptor pueda apagarlo de verdad:
/// [kDecoracionEstacionalActivada] es una constante de compilación y un test no
/// puede cambiarla. Fuera de los tests nadie pasa este parámetro.
///
/// La regla es por **mes completo**. Se valoró acotarla a los días de la
/// festividad —del 1 al 16 de septiembre, la semana del 2 de noviembre— y se
/// descartó: el adorno pasaría desapercibido para quien entra a pagar una vez al
/// mes, que es justo el uso normal de esta app.
Temporada temporadaDe(
  DateTime fecha, {
  bool activada = kDecoracionEstacionalActivada,
}) {
  if (!activada) {
    return Temporada.ninguna;
  }

  return switch (fecha.month) {
    DateTime.february => Temporada.amistad,
    DateTime.march => Temporada.primavera,
    DateTime.april => Temporada.ninez,
    DateTime.may => Temporada.madres,
    DateTime.september => Temporada.patria,
    DateTime.november => Temporada.muertos,
    DateTime.december => Temporada.navidad,
    // Enero, junio, julio, agosto y octubre. El colegio no celebra nada en
    // esos meses que dé para un adorno, y saturar el año le quitaría gracia a
    // los que sí.
    _ => Temporada.ninguna,
  };
}
