import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Widget de carga para el carrito.
class CarritoLoadingWidget extends StatelessWidget {
  const CarritoLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(AppStrings.carritoLoading),
        ],
      ),
    );
  }
}
