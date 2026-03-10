import 'package:flutter/material.dart';

class MyCard extends StatelessWidget {
  final Widget child;

  const MyCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Color(0xFFF8C71D),
            width: 7.0,
          ),
          borderRadius: BorderRadius.circular(
            20.0,
          ), 
        ),
        elevation: 8,
        color: Colors.white,
        child: Padding(padding: const EdgeInsets.all(8.0), child: child),
      ),
    );
  }
}
