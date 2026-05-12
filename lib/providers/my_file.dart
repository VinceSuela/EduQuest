import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// This provider manages the state of the currently selected PDF file, 
// including its bytes, name, current page, and review mode status.  
// It also computes a hash of the file for quiz farming prevention.
class MyFile with ChangeNotifier {
  late PlatformFile _pdf;
  late String _name;
  Uint8List _bytes = Uint8List(0);
  int _page = 1;
  bool _isReviewMode = false;
  String _currentHash = '';

  String get currentHash => _currentHash;
  bool get isReviewMode => _isReviewMode;
  String get path => File(_pdf.path!).path;
  Uint8List get bytes => Uint8List.fromList(_bytes);
  String get name => _name;
  PlatformFile get file => _pdf;
  int get page => _page;

// Call this method when a new file is selected to update the state and compute the hash for quiz farming prevention.
void setFile(PlatformFile file, String name) {
  _pdf = file;
  _name = name;
  _page = 1;
  _isReviewMode = false;
 
  if (file.bytes != null) {
    _bytes = Uint8List.fromList(file.bytes!.toList());
  } else if (file.path != null) {
    _bytes = File(file.path!).readAsBytesSync();
  }
 
 // Compute the SHA-256 hash of the file bytes for quiz farming prevention.
  _currentHash = sha256.convert(_bytes.toList()).toString();
 
  notifyListeners();
}


void setFileFromBytes(Uint8List bytes, String fileName) {
  _bytes = Uint8List.fromList(bytes.toList());
  _name = fileName;
  _isReviewMode = true;
  _currentHash = sha256.convert(_bytes.toList()).toString();
  notifyListeners();
}

  void setPage(int page) {
    _page = page;
    // notifyListeners();
  }

  void setReviewMode(bool isReview) {
    _isReviewMode = isReview;
    notifyListeners();
  }

 void reset() {
  _bytes = Uint8List(0);
  _name = '';
  _currentHash = '';
  _pdf = PlatformFile(
    name: '', 
    path: '', 
    size: 0, 
    bytes: Uint8List(0));
  _page = 1;
  _isReviewMode = false;
  notifyListeners();
}


}
