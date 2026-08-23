import 'package:arjipagos/src/domain/repository/ResenaRepository.dart';

/// Abre la ficha de la app en Google Play o la App Store.
///
/// Es lo que usa el botón "Calificar la app" del menú: Apple **prohíbe**
/// disparar la hoja de reseña nativa desde un botón, pero abrir la ficha sí se
/// permite y además no consume la cuota de invitaciones del sistema.
class AbrirFichaTiendaUseCase {
  final ResenaRepository _repository;

  const AbrirFichaTiendaUseCase(this._repository);

  /// Propaga el error a propósito: aquí el usuario pulsó algo y espera una
  /// reacción, así que si no se puede abrir la tienda hay que decírselo.
  Future<void> run() => _repository.abrirFichaTienda();
}
