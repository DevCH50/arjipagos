import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget de carga para la página de Facturas.
class FacturaLoadingWidget extends StatelessWidget {
  const FacturaLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(AppStrings.facturasLoading),
        ],
      ),
    );
  }
}
