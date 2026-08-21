import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/error_widget.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/alumnos_pagados_list.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pagados_empty_widget.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/pagados_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cuerpo principal de la página de Pagos Realizados.
///
/// Maneja los estados de carga, error, vacío y con datos. Reutiliza
/// [EdoCtaErrorWidget] porque su contenido ya es genérico (mensaje + reintentar)
/// y no depende del flujo de pagos pendientes.
class EdoCtaPagadosBody extends StatelessWidget {
  const EdoCtaPagadosBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EdoCtaPagadosBloc, EdoCtaPagadosState>(
      listener: _onStateChange,
      builder: (context, state) {
        if (state.isLoading) {
          return const PagadosLoadingWidget();
        }

        if (state.errorMessage != null && state.alumnos == null) {
          return EdoCtaErrorWidget(
            message: state.errorMessage!,
            onRetry: () => _recargarDatos(context),
          );
        }

        // Un alumno sin pagos realizados no debe ocupar una tarjeta vacía: si
        // ningún alumno tiene pagos, la pantalla completa se considera vacía.
        final alumnosConPagos = state.alumnos
            ?.where((a) => a.estadoDeCuenta.isNotEmpty)
            .toList();

        if (alumnosConPagos == null || alumnosConPagos.isEmpty) {
          return const PagadosEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: () async => _recargarDatos(context),
          child: AlumnosPagadosList(alumnos: alumnosConPagos),
        );
      },
    );
  }

  /// Muestra el diálogo de error cuando el BLoC reporta uno.
  void _onStateChange(BuildContext context, EdoCtaPagadosState state) {
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      _mostrarDialogoError(context, state.errorMessage!);
    }
  }

  /// Recarga los datos del servidor.
  void _recargarDatos(BuildContext context) {
    context.read<EdoCtaPagadosBloc>().add(const EdoCtaPagadosRefreshEvent());
  }

  /// Muestra diálogo de error (nunca Toast ni SnackBar).
  void _mostrarDialogoError(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }
}
