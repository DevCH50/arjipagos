import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeState.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/HomeLoadingWidget.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/HomeErrorWidget.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/HomeEmptyWidget.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/HomeAlumnosList.dart';

/// Página principal de la aplicación.
///
/// Muestra la lista de alumnos asociados a la familia del usuario
/// autenticado. Permite refrescar la lista y cerrar sesión.
class HomesPage extends StatefulWidget {
  const HomesPage({super.key});

  @override
  State<HomesPage> createState() => _HomesPageState();
}

class _HomesPageState extends State<HomesPage> {
  HomeBloc? bloc;

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<HomeBloc>(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => _buildBody(state),
      ),
    );
  }

  /// Construye el AppBar con título dinámico y botón de refresh.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Text(state.alumnosResponse?.familia ?? AppStrings.homeCargando);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<HomeBloc>().add(const RefreshHomesList());
          },
        ),
      ],
    );
  }

  /// Construye el cuerpo de la página según el estado actual.
  ///
  /// Retorna el widget correspondiente al estado:
  /// - Loading: indicador de carga
  /// - Error: mensaje de error con opción de reintentar
  /// - Empty: mensaje de lista vacía
  /// - Success: lista de alumnos
  Widget _buildBody(HomeState state) {
    // Estado de carga
    if (state.isLoading) {
      return const HomeLoadingWidget();
    }

    // Estado de error
    if (state.errorMessage != null) {
      return HomeErrorWidget(
        errorMessage: state.errorMessage!,
        onRetry: () => context.read<HomeBloc>().add(const GetHomesList()),
      );
    }

    // Estado vacío
    if (state.alumnos == null || state.alumnos!.isEmpty) {
      return HomeEmptyWidget(
        onRefresh: () => context.read<HomeBloc>().add(const RefreshHomesList()),
      );
    }

    // Lista de alumnos
    return HomeAlumnosList(
      alumnos: state.alumnos!,
      alumnosResponse: state.alumnosResponse,
      onRefresh: () => context.read<HomeBloc>().add(const RefreshHomesList()),
    );
  }
}
