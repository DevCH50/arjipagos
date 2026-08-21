import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de Pagos Realizados.
///
/// Muestra, agrupados por alumno, los pagos que ya fueron liquidados, con su
/// fecha de pago, folio y acceso al ticket. Es de solo lectura: no hay
/// selección de pagos, ni barra de total, ni paso al carrito.
class EdoCtaPagadosPage extends StatelessWidget {
  const EdoCtaPagadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: const EdoCtaPagadosBody(),
    );
  }

  /// AppBar con botón de regreso y acción de actualizar.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(AppStrings.edoCtaPagadosTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.edoCtaPagadosActualizar,
          onPressed: () => context
              .read<EdoCtaPagadosBloc>()
              .add(const EdoCtaPagadosRefreshEvent()),
        ),
      ],
    );
  }
}
