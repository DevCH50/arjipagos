import 'package:flutter/material.dart';

/// Llave del `Navigator` raíz de la aplicación.
///
/// Hace falta porque el `builder` de `MaterialApp` se inserta **por encima**
/// del `Navigator`: su contexto no tiene un navegador antepasado, así que desde
/// ahí no se puede llamar a `showDialog`. `ActualizacionObserver` vive en ese
/// `builder` —para poder envolver toda la app— y usa esta llave para abrir el
/// diálogo de actualización sobre cualquier pantalla que esté visible.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
