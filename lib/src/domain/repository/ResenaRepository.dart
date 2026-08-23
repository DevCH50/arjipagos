import 'package:arjipagos/src/domain/models/resena/EstadoResena.dart';

/// Acceso a las invitaciones para calificar la app.
///
/// Separa el **qué** (leer/escribir el estado, pedirle al sistema que muestre
/// la hoja de reseña) del **cuándo**, que decide `SolicitarResenaUseCase`.
abstract class ResenaRepository {
  /// Estado persistido de las invitaciones.
  Future<EstadoResena> obtenerEstado();

  /// Suma un pago completado con éxito.
  ///
  /// La primera llamada también fija la fecha de primer uso, que es el ancla
  /// para exigir una antigüedad mínima antes de invitar.
  Future<void> registrarPagoExitoso();

  /// Si el sistema puede mostrar la hoja de reseña nativa.
  ///
  /// En Android devuelve `false` cuando la app no viene de Google Play (por
  /// ejemplo instalada con `adb install`), y en iOS si el dispositivo no
  /// soporta la API.
  Future<bool> invitacionDisponible();

  /// Pide al sistema que muestre la hoja de reseña nativa.
  ///
  /// **No hay garantía de que aparezca**: Apple limita a 3 veces por usuario al
  /// año y Google aplica su propia cuota. La API no informa de si se mostró ni
  /// de si el usuario calificó, así que no devuelve nada útil.
  Future<void> mostrarInvitacion();

  /// Anota que se acaba de invitar, para respetar el intervalo y el tope anual.
  Future<void> registrarInvitacion();

  /// Abre la ficha de la app en la tienda correspondiente.
  ///
  /// Es el camino para un botón explícito de "Calificar la app": Apple prohíbe
  /// disparar la hoja nativa desde un botón, pero abrir la ficha sí se permite.
  Future<void> abrirFichaTienda();
}
