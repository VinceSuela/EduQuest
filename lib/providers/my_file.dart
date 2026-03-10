import 'dart:io';

import 'package:flutter/foundation.dart';

class MyFile with ChangeNotifier {
  late File _pdf;

  String get path => _pdf.path;
  String get name => _pdf.path;

  void setFile(File file) {
    _pdf = file;
    notifyListeners();
  }
}
