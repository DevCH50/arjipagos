import 'package:arjipagos/src/domain/useCases/resena/AbrirFichaTiendaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/RegistrarPagoExitosoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/resena/SolicitarResenaUseCase.dart';

/// Agrupa los casos de uso de reseñas, igual que el resto de áreas del dominio.
class ResenaUseCases {
  final RegistrarPagoExitosoUseCase registrarPagoExitoso;
  final SolicitarResenaUseCase solicitarResena;
  final AbrirFichaTiendaUseCase abrirFichaTienda;

  const ResenaUseCases({
    required this.registrarPagoExitoso,
    required this.solicitarResena,
    required this.abrirFichaTienda,
  });
}
