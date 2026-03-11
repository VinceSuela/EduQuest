// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/widgets/header_logo.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final String title = '';

  @override
  void initState() {
    bool isLoggedIn = FirebaseAuth.instance.currentUser?.email != null;
    if (isLoggedIn) {
      Provider.of<MyUser>(
        NavigationService.navigatorKey.currentContext!,
      ).setUser();
    }
    Future.delayed(Duration(seconds: 3), () {
      String routeName = isLoggedIn ? '/home' : '/login';
      Navigator.of(
        NavigationService.navigatorKey.currentContext!,
      ).pushReplacementNamed(routeName);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFF47B9FF)),
        child: Center(child: HeaderLogo()),
      ),
    );
  }
}
