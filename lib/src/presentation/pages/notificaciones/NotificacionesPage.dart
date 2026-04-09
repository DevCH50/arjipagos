import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_detalle_widget.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_item_widget.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/widgets/notificacion_vacia_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página principal de notificaciones del usuario.
///
/// Muestra la lista paginada de notificaciones con soporte para:
/// - Carga inicial al montar la pantalla.
/// - Paginación infinita al llegar al 80 % del scroll.
/// - Refresco mediante pull-to-refresh.
/// - Marcar todas como leídas desde el AppBar.
/// - Abrir el detalle de cada notificación en un bottom sheet.
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  /// Controlador del scroll para detectar el fin de la lista y paginar.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Disparar la carga inicial de notificaciones.
    context.read<NotificacionBloc>().add(const NotificacionInicialEvent());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Detecta cuando el usuario llega al 80 % del scroll y solicita más datos.
  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.8) {
      final state = context.read<NotificacionBloc>().state;
      if (state.hayMas && !state.isCargandoMas) {
        context.read<NotificacionBloc>().add(const CargarMasNotificacionesEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocConsumer<NotificacionBloc, NotificacionState>(
        listener: _onStateChange,
        builder: _buildBody,
      ),
    );
  }

  /// Construye el AppBar con botón de actualizar y acción condicional de marcar todas leídas.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Notificaciones'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Botón de marcar todas leídas — solo visible si hay no leídas.
        BlocBuilder<NotificacionBloc, NotificacionState>(
          buildWhen: (prev, curr) => prev.noLeidas != curr.noLeidas,
          builder: (context, state) {
            if (state.noLeidas > 0) {
              return TextButton(
                onPressed: () {
                  context.read<NotificacionBloc>().add(
                        const MarcarTodasLeidasEvent(),
                      );
                },
                child: const Text('Marcar todas leídas'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Botón de actualizar — siempre visible.
        BlocBuilder<NotificacionBloc, NotificacionState>(
          buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
          builder: (context, state) {
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: () {
                context.read<NotificacionBloc>().add(
                      const NotificacionInicialEvent(),
                    );
              },
            );
          },
        ),
      ],
    );
  }

  /// Escucha cambios de estado para mostrar SnackBar de error.
  void _onStateChange(BuildContext context, NotificacionState state) {
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Construye el cuerpo principal según el estado actual del BLoC.
  Widget _buildBody(BuildContext context, NotificacionState state) {
    // Estado: carga inicial en progreso.
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado: lista vacía y sin carga activa.
    if (state.notificaciones.isEmpty && !state.isLoading) {
      return const NotificacionVaciaWidget();
    }

    // Estado normal: lista con notificaciones.
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificacionBloc>().add(const NotificacionInicialEvent());
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        // +1 para el indicador de carga al final cuando se pagina.
        itemCount: state.notificaciones.length + (state.isCargandoMas ? 1 : 0),
        itemBuilder: (context, index) {
          // Indicador de paginación al final de la lista.
          if (index == state.notificaciones.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final notificacion = state.notificaciones[index];
          return NotificacionItemWidget(
            notificacion: notificacion,
            onTap: () => _abrirDetalle(context, notificacion),
          );
        },
      ),
    );
  }

  /// Muestra el bottom sheet con el detalle de la notificación seleccionada.
  void _abrirDetalle(
    BuildContext context,
    Notificacion notificacion,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificacionDetalleWidget(notificacion: notificacion),
    );
  }
}
