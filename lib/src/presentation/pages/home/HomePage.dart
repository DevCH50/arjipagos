import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../main.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeBloc.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeState.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/CloseSession.dart';
import 'package:arjipagos/src/presentation/pages/home/widget/Drawer.dart';
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

  /// Maneja el proceso de cierre de sesión.
  ///
  /// Muestra un diálogo de confirmación y, si el usuario acepta,
  /// dispara el evento de logout y navega a la pantalla inicial.
  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloseSession(
        title: 'Cerrar Sesión',
        message: '¿Estás seguro que deseas cerrar sesión?',
        icon: Icons.logout,
        iconColor: Colors.orange,
        confirmText: 'Cerrar Sesión',
        cancelText: 'Cancelar',
        confirmButtonColor: Colors.red,
        confirmTextColor: Colors.white,
        onConfirm: () {},
        onCancel: () {},
      ),
    );

    if (shouldLogout == true && mounted) {
      bloc?.add(const HomeLogoutEvent());
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<HomeBloc>(context);

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: HomeDrawer(
        authUseCases: bloc!.authUseCases,
        onLogout: _handleLogout,
      ),
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
          return Text(state.alumnosResponse?.familia ?? 'Cargando...');
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
