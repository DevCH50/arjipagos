import 'package:equatable/equatable.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';

class HomeState extends Equatable {
  final List<Alumno>? alumnos;
  final AlumnoResponse? alumnosResponse;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.alumnos,
    this.alumnosResponse,
    this.isLoading = false,
    this.errorMessage,
  });

  factory HomeState.initial() => const HomeState();

  HomeState copyWith({
    List<Alumno>? alumnos,
    AlumnoResponse? alumnosResponse,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      alumnos: alumnos ?? this.alumnos,
      alumnosResponse: alumnosResponse ?? this.alumnosResponse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [alumnos, alumnosResponse, isLoading, errorMessage];
}
