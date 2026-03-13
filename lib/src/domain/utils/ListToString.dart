String ListToString(dynamic data) {
  String message = '';
  if (data is List<dynamic>) {
    message = data.join('\n');
  } else if (data is String) {
    message = data;
  }
  return message;
}
