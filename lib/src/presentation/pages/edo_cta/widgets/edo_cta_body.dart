import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/alumnos_list.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/empty_widget.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/error_widget.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cuerpo principal de la página de Estados de Cuenta.
/// Maneja los diferentes estados: cargando, error, vacío, con datos.
class EdoCtaBody extends StatelessWidget {
  const EdoCtaBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EdoCtaListBloc, EdoCtaListState>(
      listener: _onStateChange,
      builder: (context, state) {
        if (state.isLoading) {
          return const EdoCtaLoadingWidget();
        }

        if (state.errorMessage != null && state.alumnos == null) {
          return EdoCtaErrorWidget(
            message: state.errorMessage!,
            onRetry: () => _recargarDatos(context),
          );
        }

        // `alumnosDelEmisor` ya trae solo los pagos del emisor que muestra
        // esta pantalla, y descarta a los alumnos que no tienen ninguno.
        final alumnos = state.alumnosDelEmisor;
        if (alumnos == null || alumnos.isEmpty) {
          return EdoCtaEmptyWidget(onRetry: () => _recargarDatos(context));
        }

        return RefreshIndicator(
          onRefresh: () async => _recargarDatos(context),
          child: AlumnosList(alumnos: alumnos),
        );
      },
    );
  }

  /// Maneja cambios de estado para mostrar diálogos de error.
  void _onStateChange(BuildContext context, EdoCtaListState state) {
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      _mostrarDialogoError(context, state.errorMessage!);
    }
  }

  /// Recarga los datos del servidor.
  void _recargarDatos(BuildContext context) {
    context.read<EdoCtaListBloc>().add(const EdoCtaListRefreshEvent());
  }

  /// Muestra diálogo de error.
  void _mostrarDialogoError(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }
}
