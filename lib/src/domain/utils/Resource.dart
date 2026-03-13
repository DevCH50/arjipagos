abstract class Resource<AuthResponse> {}

class Initial extends Resource {}

class Loading extends Resource {}

class Success<T> extends Resource<T> {
  final T data;
  Success(this.data);
}

class Error<T> extends Resource<T> {
  final String msg;
  Error(this.msg);
}

class Warning<T> extends Resource {
  final String msg;
  Warning(this.msg);
}

class Info<T> extends Resource {
  final String msg;
  Info(this.msg);
}

class NoInternet extends Resource {}

class Timeout extends Resource {}

class Unauthorized extends Resource {}

class Empty extends Resource {}
