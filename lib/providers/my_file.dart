import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class MyFile with ChangeNotifier {
  late PlatformFile _pdf;
  late String _name;

  String get path => File(_pdf.path!).path;
  Uint8List? get bytes => _pdf.bytes;
  String get name => _name;

  void setFile(PlatformFile file, String name) {
    _pdf = file;
    _name = name;
    notifyListeners();
  }
}
