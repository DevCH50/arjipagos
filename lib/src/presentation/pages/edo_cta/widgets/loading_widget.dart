import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget que muestra indicador de carga.
class EdoCtaLoadingWidget extends StatelessWidget {
  const EdoCtaLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(AppStrings.edoCtaLoading),
        ],
      ),
    );
  }
}
