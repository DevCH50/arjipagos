import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaState.dart';
import 'package:arjipagos/src/presentation/pages/facturas/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de Facturas.
///
/// Muestra la lista de facturas del usuario con opción de compartir
/// el archivo ZIP de cada una. El ZIP viene en base64 desde el servidor
/// y se decodifica de forma lazy solo al presionar compartir.
class FacturasPage extends StatelessWidget {
  const FacturasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.facturasTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          BlocBuilder<FacturaBloc, FacturaState>(
            builder: (context, state) {
              // Botón de refresco: oculto durante la carga
              if (state.isLoading) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.homeRefresh,
                onPressed: () {
                  context.read<FacturaBloc>().add(const FacturaRefreshEvent());
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FacturaBloc, FacturaState>(
        builder: (context, state) {
          // Estado de carga
          if (state.isLoading) {
            return const FacturaLoadingWidget();
          }

          // Estado de error
          if (state.errorMessage != null) {
            return FacturaErrorWidget(
              message: state.errorMessage!,
              onRetry: () {
                context.read<FacturaBloc>().add(const FacturaRefreshEvent());
              },
            );
          }

          // Estado vacío
          if (state.facturas.isEmpty) {
            return const FacturaEmptyWidget();
          }

          // Lista de facturas con pull-to-refresh
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FacturaBloc>().add(const FacturaRefreshEvent());
              // Esperar a que termine la carga
              await context
                  .read<FacturaBloc>()
                  .stream
                  .firstWhere((s) => !s.isLoading);
            },
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                // Header con nombre de familia
                if (state.response != null)
                  _FamiliaHeader(familia: state.response!.familia),

                // Lista de facturas
                ...state.facturas.map(
                  (factura) => FacturaItemWidget(factura: factura),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Encabezado con el nombre de la familia asociada a las facturas.
class _FamiliaHeader extends StatelessWidget {
  final String familia;

  const _FamiliaHeader({required this.familia});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(Icons.family_restroom, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              familia,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
