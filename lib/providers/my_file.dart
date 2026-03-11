import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class MyFile with ChangeNotifier {
  late PlatformFile _pdf;
  late String _name;
  late Uint8List _bytes;
  int _page = 1;

  String get path => File(_pdf.path!).path;
  Uint8List get bytes => Uint8List.fromList(_bytes);
  String get name => _name;
  PlatformFile get file => _pdf;
  int get page => _page;

  void setFile(PlatformFile file, String name) {
    _pdf = file;
    _name = name;
    _bytes = file.bytes!;
    _page = 1;
    notifyListeners();
  }

  void setPage(int page) {
    _page = page;
    // notifyListeners();
  }
}
