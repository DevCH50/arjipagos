/// Tamaños de pantalla del **iPhone Duo**, para los tests de widget.
///
/// El Duo es plegable y tiene dos pantallas. Desde abril de 2027 App Store
/// Connect exige capturas de las dos, y al compilar con el SDK de iOS 27.1 la
/// app ocupa la pantalla entera: tiene que verse bien en las dos sin que exista
/// todavía un simulador en esta Mac (ver «Abril de 2027» en `CLAUDE.md`).
///
/// **De dónde salen las cifras.** Son los tamaños de captura que pide App Store
/// Connect, a densidad 3x:
///
/// | Pantalla | Captura (px) | Puntos lógicos |
/// | --- | --- | --- |
/// | Exterior | 1398 × 2034 | 466 × 678 |
/// | Interior | 2007 × 2853 | 669 × 951 |
///
/// Apple no ha publicado aún los puntos exactos; si cuando salga el simulador
/// no coinciden, se cambian aquí y nada más.
///
/// Solo vertical: la app está fijada a `portraitUp`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Una de las dos pantallas del Duo.
class PantallaDuo {
  /// Nombre con el que sale en la descripción del test.
  final String nombre;

  /// Tamaño en píxeles físicos, el de la captura de App Store Connect.
  final Size tamanoFisico;

  /// Densidad de la pantalla.
  final double densidad;

  const PantallaDuo(this.nombre, this.tamanoFisico, {this.densidad = 3});

  /// Tamaño en puntos lógicos, que es lo que ve el layout de Flutter.
  Size get tamanoLogico => tamanoFisico / densidad;
}

/// Pantalla exterior, con el teléfono plegado.
const PantallaDuo kDuoExterior = PantallaDuo('exterior', Size(1398, 2034));

/// Pantalla interior, con el teléfono abierto. Casi cuadrada (1.42 : 1).
const PantallaDuo kDuoInterior = PantallaDuo('interior', Size(2007, 2853));

/// Las dos, para recorrerlas en los tests.
const List<PantallaDuo> kPantallasDuo = [kDuoExterior, kDuoInterior];

/// Pone la vista del test al tamaño de [pantalla] y con la letra del sistema a
/// [escalaTexto], y deja registrado cómo deshacerlo al acabar el test.
///
/// Es el mismo ajuste del test de pantalla pequeña de Configuraciones, sacado
/// aquí para no repetirlo en cada caso.
void fijarPantalla(
  WidgetTester tester,
  PantallaDuo pantalla, {
  double escalaTexto = 1.0,
}) {
  tester.view.physicalSize = pantalla.tamanoFisico;
  tester.view.devicePixelRatio = pantalla.densidad;
  tester.platformDispatcher.textScaleFactorTestValue = escalaTexto;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
