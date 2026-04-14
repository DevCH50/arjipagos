import 'package:equatable/equatable.dart';

/// Eventos del BLoC de facturas.
abstract class FacturaEvent extends Equatable {
  const FacturaEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial de facturas al abrir la página.
class FacturaInicialEvent extends FacturaEvent {
  const FacturaInicialEvent();
}

/// Refresca la lista de facturas (pull-to-refresh).
class FacturaRefreshEvent extends FacturaEvent {
  const FacturaRefreshEvent();
}
