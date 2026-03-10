import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class MyFile with ChangeNotifier {
  late PlatformFile _pdf;

  String get path => File(_pdf.path!).path;
  Uint8List? get bytes => _pdf.bytes;

  void setFile(PlatformFile file) {
    _pdf = file;
    notifyListeners();
  }
}
