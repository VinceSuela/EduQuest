import 'package:flutter/material.dart';

class HeaderLogo extends StatelessWidget {
  const HeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: 60, right: 30),
        child: Transform.translate(
          offset: Offset(0, 10),
          child: Image.asset('assets/images/logo-dark.png'),
        ),
      ),
    );
  }
}
