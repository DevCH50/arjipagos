import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/useCases/alumnos/HomeUseCases.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;

import 'package:arjipagos/src/presentation/pages/home/bloc/HomeEvent.dart';
import 'package:arjipagos/src/presentation/pages/home/bloc/HomeState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona el estado de la página Home.
///
/// Maneja la carga de alumnos, refresco de lista y cierre de sesión.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeUseCases homeUseCases;
  AuthUseCases authUseCases;

  HomeBloc(this.homeUseCases, this.authUseCases)
      : super(HomeState.initial()) {
    on<GetHomesList>(_onGetHomesList);
    on<RefreshHomesList>(_onGetHomesList);
    on<HomeLogoutEvent>(_onLogout);
  }

  /// Maneja el evento de cierre de sesión.
  Future<void> _onLogout(
    HomeLogoutEvent event,
    Emitter<HomeState> emit,
  ) async {
    await authUseCases.logout.run();
  }

  /// Carga la lista de alumnos desde el servidor.
  ///
  /// Maneja los estados de carga, éxito y error.
  Future<void> _onGetHomesList(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final utils.Resource<dynamic> result = await homeUseCases.getAlumnos.run();

      if (result is utils.Success) {
        final data = result.data;
        if (data is AlumnoResponse) {
          emit(
            state.copyWith(
              alumnos: data.alumnos,
              alumnosResponse: data,
              isLoading: false,
              errorMessage: null,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: AppStrings.homeDatosInesperados,
            ),
          );
        }
      } else if (result is utils.Error) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.msg,
        ));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Error inesperado: $e',
        ),
      );
    }
  }
}
