import 'package:flutter/material.dart';

/// Observa qué ruta está arriba en el `Navigator` raíz.
///
/// ## Para qué
///
/// El cerrojo biométrico necesita saber si el usuario está a media pasarela de
/// pago, para **no bloquear encima de una transacción en curso**. El caso real
/// es este: el banco manda un código por SMS, el usuario sale a la app de
/// mensajes a copiarlo, tarda más de la cuenta y vuelve. Si el cerrojo salta
/// ahí, se queda sin poder terminar de pagar.
///
/// ## Por qué así y no tocando `PagoWebViewPage`
///
/// La alternativa era que la propia página levantara una bandera en su
/// `initState` y la bajara en el `dispose`. Se descartó: `PagoWebViewPage` es
/// el flujo de dinero, el más delicado de la app, y **no se toca para añadirle
/// una responsabilidad que no es suya**. Un observador es aditivo, vive fuera
/// de esa pantalla y no puede romperla.
///
/// Se registra en `navigatorObservers` del `MaterialApp`.
class RutaActualObserver extends NavigatorObserver {
  /// Nombre de la ruta visible, o `null` si no se sabe.
  ///
  /// Las rutas sin nombre —los `MaterialPageRoute` que se empujan a mano, como
  /// el de Recuperar Contraseña— dejan esto en `null`. Es correcto: lo único
  /// que se consulta es si estamos en el WebView de pago, y esa sí es una ruta
  /// con nombre.
  String? get rutaActual => _rutaActual;
  String? _rutaActual;

  /// Ruta de la pasarela de pago, la única que suspende el cerrojo.
  static const String rutaPagoWebView = 'pago_webview';

  /// Si hay un pago en curso en pantalla.
  bool get hayPagoEnCurso => _rutaActual == rutaPagoWebView;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _rutaActual = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Al cerrar una ruta, la visible pasa a ser la de debajo.
    _rutaActual = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _rutaActual = newRoute?.settings.name;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);

    // `didRemove` se dispara una vez por cada ruta que retira un
    // `pushAndRemoveUntil`, incluidas las que ya no estaban arriba. Actualizar
    // siempre dejaría el nombre apuntando a una ruta enterrada; solo interesa
    // cuando la retirada es la que se estaba viendo.
    if (_rutaActual == route.settings.name) {
      _rutaActual = previousRoute?.settings.name;
    }
  }
}

/// Instancia única, compartida entre el `MaterialApp` y el cerrojo.
final RutaActualObserver rutaActualObserver = RutaActualObserver();
