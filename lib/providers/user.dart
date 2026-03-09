// import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MyUser with ChangeNotifier {
  bool isLoggedIn = false;
  String username = '';
  late UserCredential credentials;

  // bool get isLoggedIn => _isLoggedIn;
  // String get username => _username;

  Future<void> setUser() async {
    try {
      username = FirebaseAuth.instance.currentUser!.email!;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> logIn(String email, String password) async {
    try {
      credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      username = credentials.user!.email!;
      print(credentials.user);
      return credentials;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      username = credentials.user!.email!;
      print(credentials.user);
      return credentials;
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}
