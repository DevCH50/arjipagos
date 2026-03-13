class BlocForItem {
  final String value;
  final String? error;

  const BlocForItem({this.value = '', this.error});

  BlocForItem copyWith({String? value, String? error}) {
    return BlocForItem(value: value ?? this.value, error: error ?? this.error);
  }

}
