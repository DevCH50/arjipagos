/// Formateo de cantidades de dinero para la interfaz.
///
/// Vive aquí y no dentro de cada widget porque la app enseña importes en cinco
/// sitios —barra de Pagos Pendientes, barra del Carrito, tarjeta del alumno,
/// facturas y tickets— y tres de ellos llevaban la **misma** función privada
/// copiada. Con tres copias, corregir el formato en una dejaba las otras dos
/// mostrando el dinero de otra manera.
library;

/// Cantidad con símbolo, separador de miles y dos decimales: `$9,770.00`.
///
/// Dos decimales siempre, incluso si la cantidad es redonda: en una pantalla de
/// pagos, `$9,770` y `$9,770.00` en renglones contiguos se leen como formatos
/// distintos del mismo dato.
String formatearMonto(double monto) {
  final partes = monto.toStringAsFixed(2).split('.');
  final parteEntera = partes[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '\$$parteEntera.${partes[1]}';
}

/// Igual, pero partiendo del texto que manda el backend.
///
/// Las facturas traen el total como cadena y con **cuatro** decimales
/// (`"9770.0000"`), que es como lo guarda el timbrado. Pintarlo tal cual dejaba
/// `Total: 9770.0000` en pantalla, sin símbolo ni separadores, mientras el
/// resto de la app mostraba `$9,770.00`.
///
/// Si el texto no es un número —el backend manda algo inesperado o vacío— se
/// devuelve tal cual: es preferible enseñar el dato crudo que un `$0.00` que
/// parece una cantidad real y no lo es.
String formatearMontoTexto(String monto) {
  final valor = double.tryParse(monto.trim());
  if (valor == null) {
    return monto;
  }
  return formatearMonto(valor);
}
