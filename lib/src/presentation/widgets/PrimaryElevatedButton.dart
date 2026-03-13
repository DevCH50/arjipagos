import 'package:flutter/material.dart';

class PrimaryElevatedButton extends StatelessWidget {
  final String text;
  final Color color;
  final Function() onPressed;

  const PrimaryElevatedButton({super.key, 
    required this.text, 
    required this.onPressed,
    this.color = const Color.fromARGB(255, 181, 211, 5), // Button color    
    });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.black54)),
    );
  }
}
