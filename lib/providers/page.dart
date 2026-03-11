// import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';

class MyPage with ChangeNotifier {
  bool _isDrawerOpen = false;

  bool get isDrawerOpen => _isDrawerOpen;

  void toggleDrawer() {
    _isDrawerOpen = !_isDrawerOpen;
    notifyListeners();
  }

  void setDrawerState(bool toggle) {
    _isDrawerOpen = toggle;
    notifyListeners();
  }
}
