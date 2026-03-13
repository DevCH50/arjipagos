import 'package:flutter/material.dart';

class DefaultIconBack extends StatelessWidget {
  final double left;
  final double top;

  const DefaultIconBack({super.key, required this.left, required this.top});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(top: top, left: left),
      child: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 35),
      ),
    );
  }
}
