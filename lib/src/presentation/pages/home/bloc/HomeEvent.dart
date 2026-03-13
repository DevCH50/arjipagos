import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class GetHomesList extends HomeEvent {
  const GetHomesList();
}

class RefreshHomesList extends HomeEvent {
  const RefreshHomesList();
}

class HomeLogoutEvent extends HomeEvent {
  const HomeLogoutEvent();
}
