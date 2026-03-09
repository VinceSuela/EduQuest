import 'package:flutter/foundation.dart';

class MyCounter with ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void decrease() {
    _count--;
    notifyListeners();
  }
}
