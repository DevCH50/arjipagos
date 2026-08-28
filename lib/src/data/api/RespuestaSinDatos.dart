/// Distingue la respuesta «aquí no hay nada que mostrar» de un fallo real.
///
/// ## El problema que resuelve
///
/// Cuando un usuario no tiene familia asignada —o no tiene alumnos, ni estados
/// de cuenta, ni facturas—, el backend no responde `200` con una lista vacía:
/// responde **`404`** con un cuerpo como
///
/// ```json
/// {"success": false, "message": "El usuario no tiene una familia asignada."}
/// ```
///
/// Hasta el 2026-08-28 los services metían eso en su rama de error genérica, y
/// la consecuencia era que la pantalla mostraba **«Error al cargar»** en rojo
/// —más un `AlertDialog` encima— cuando lo cierto es que no había nada que
/// cargar. Los estados vacíos («No tienes facturas disponibles» y compañía) ya
/// existían, pero nunca se llegaba a ellos: el cuerpo de cada pantalla comprueba
/// el error *antes* que la lista vacía.
///
/// ## Por qué se exigen las dos condiciones
///
/// No basta con mirar el `404`. Un `404` a secas también lo devuelve Laravel
/// cuando la ruta no existe, y ese sí es un fallo que el usuario debe ver. La
/// diferencia está en el cuerpo: la respuesta de «no hay datos» la construye la
/// aplicación y **siempre lleva la clave `success`**, mientras que el 404 de
/// ruta inexistente lo genera el framework y llega sin ella:
///
/// ```json
/// {"message": "The route api/v1/... could not be found."}
/// ```
///
/// Por eso se piden las dos cosas a la vez. Tragarse cualquier `404` convertiría
/// un error de despliegue —una ruta renombrada, un prefijo mal puesto— en una
/// pantalla vacía y silenciosa, que es justo lo contrario de lo que se busca.
///
/// No se compara el texto del mensaje: es del backend, puede cambiar de
/// redacción o traducirse, y atarse a él sería frágil.
library;

/// Indica si [statusCode] y [data] son la respuesta de «no hay datos».
///
/// [data] es el cuerpo ya decodificado con `json.decode`. Se acepta `dynamic`
/// porque eso es lo que devuelve el decodificador; cualquier cosa que no sea un
/// mapa con `success == false` se considera un error de verdad.
bool esRespuestaSinDatos(int statusCode, dynamic data) {
  if (statusCode != 404) {
    return false;
  }

  return data is Map && data['success'] == false;
}
