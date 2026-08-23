import 'package:arjipagos/src/data/dataSource/local/ResenaNativa.dart';
import 'package:arjipagos/src/data/dataSource/local/ResenaStorage.dart';
import 'package:arjipagos/src/domain/models/resena/EstadoResena.dart';
import 'package:arjipagos/src/domain/repository/ResenaRepository.dart';

/// Implementación de [ResenaRepository].
///
/// Junta las dos mitades: el estado persistido en [ResenaStorage] y el canal
/// nativo en [ResenaNativa]. Aquí no hay política — el "cuándo invitar" vive en
/// `SolicitarResenaUseCase`.
class ResenaRepositoryImpl implements ResenaRepository {
  final ResenaStorage _storage;
  final ResenaNativa _nativa;

  ResenaRepositoryImpl(this._storage, this._nativa);

  @override
  Future<EstadoResena> obtenerEstado() => _storage.cargar();

  @override
  Future<void> registrarPagoExitoso() => _storage.registrarPagoExitoso();

  @override
  Future<bool> invitacionDisponible() => _nativa.disponible();

  @override
  Future<void> mostrarInvitacion() => _nativa.solicitar();

  @override
  Future<void> registrarInvitacion() => _storage.registrarInvitacion();

  @override
  Future<void> abrirFichaTienda() => _nativa.abrirFicha();
}
