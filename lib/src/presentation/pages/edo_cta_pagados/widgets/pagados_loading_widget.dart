import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Indicador de carga de la pantalla de pagos realizados.
class PagadosLoadingWidget extends StatelessWidget {
  const PagadosLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(AppStrings.edoCtaPagadosLoading),
        ],
      ),
    );
  }
}
