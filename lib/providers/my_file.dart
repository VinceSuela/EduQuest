// import 'dart:io';
// import 'package:crypto/crypto.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';

// // This provider manages the state of the currently selected PDF file,
// // including its bytes, name, current page, and review mode status.
// // It also computes a hash of the file for quiz farming prevention.
// class MyFile with ChangeNotifier {
//   late PlatformFile _pdf;
//   late String _name;
//   Uint8List _bytes = Uint8List(0);
//   int _page = 1;
//   bool _isReviewMode = false;
//   String _currentHash = '';

//   String get currentHash => _currentHash;
//   bool get isReviewMode => _isReviewMode;
//   String get path => File(_pdf.path!).path;
//   Uint8List get bytes => Uint8List.fromList(_bytes);
//   String get name => _name;
//   PlatformFile get file => _pdf;
//   int get page => _page;

//   // Call this method when a new file is selected to update the state and compute the hash for quiz farming prevention.
//   void setFile(PlatformFile file, String name) {
//     _pdf = file;
//     _name = name;
//     _page = 1;
//     _isReviewMode = false;

//     if (file.bytes != null) {
//       _bytes = Uint8List.fromList(file.bytes!.toList());
//     } else if (file.path != null) {
//       _bytes = File(file.path!).readAsBytesSync();
//     }

//     // Compute the SHA-256 hash of the file bytes for quiz farming prevention.
//     _currentHash = sha256.convert(_bytes.toList()).toString();

//     notifyListeners();
//   }

//   void setFileFromBytes(Uint8List bytes, String fileName) {
//     _bytes = Uint8List.fromList(bytes.toList());
//     _name = fileName;
//     _isReviewMode = true;
//     _currentHash = sha256.convert(_bytes.toList()).toString();
//     notifyListeners();
//   }

//   void setPage(int page) {
//     _page = page;
//     // notifyListeners();
//   }

//   void setReviewMode(bool isReview) {
//     _isReviewMode = isReview;
//     notifyListeners();
//   }

//   void reset() {
//     _bytes = Uint8List(0);
//     _name = '';
//     _currentHash = '';
//     _pdf = PlatformFile(name: '', path: '', size: 0, bytes: Uint8List(0));
//     _page = 1;
//     _isReviewMode = false;
//     notifyListeners();
//   }
// }

// class PdfCacheService {
//   static Future<String> _cachePath() async {
//     final dir = await getApplicationCacheDirectory();
//     return '${dir.path}/pdf_cache';
//   }

//   static Future<void> savePdf(String pdfHash, Uint8List bytes) async {
//     if (kIsWeb) return; // web has no file system
//     final path = await _cachePath();
//     await Directory(path).create(recursive: true);
//     await File('$path/$pdfHash.pdf').writeAsBytes(bytes);
//   }

//   static Future<Uint8List?> loadPdf(String pdfHash) async {
//     if (kIsWeb) return null;
//     final path = await _cachePath();
//     final file = File('$path/$pdfHash.pdf');
//     if (await file.exists()) return await file.readAsBytes();
//     return null;
//   }

//   // Call on app startup — delete PDFs older than 30 days
//   static Future<void> evictOldCache() async {
//     if (kIsWeb) return;
//     final path = await _cachePath();
//     final dir = Directory(path);
//     if (!await dir.exists()) return;
//     final cutoff = DateTime.now().subtract(const Duration(days: 30));
//     await for (final file in dir.list()) {
//       final stat = await file.stat();
//       if (stat.modified.isBefore(cutoff)) await file.delete();
//     }
//   }
// }

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class MyFile with ChangeNotifier {
  late PlatformFile _pdf;
  late String _name;
  Uint8List _bytes = Uint8List(0);
  int _page = 1;
  bool _isReviewMode = false;
  String _currentHash = '';

  // New: loading/error state for background PDF fetch
  bool _isLoading = false;
  String? _errorMessage;

  String get currentHash => _currentHash;
  bool get isReviewMode => _isReviewMode;
  String get path => File(_pdf.path!).path;
  Uint8List get bytes => Uint8List.fromList(_bytes);
  String get name => _name;
  PlatformFile get file => _pdf;
  int get page => _page;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  void setFile(PlatformFile file, String name) {
    _pdf = file;
    _name = name;
    _page = 1;
    _isReviewMode = false;
    _isLoading = false;
    _errorMessage = null;
    if (file.bytes != null) {
      _bytes = Uint8List.fromList(file.bytes!.toList());
    } else if (file.path != null) {
      _bytes = File(file.path!).readAsBytesSync();
    }
    _currentHash = sha256.convert(_bytes.toList()).toString();
    notifyListeners();
  }

  void setFileFromBytes(Uint8List bytes, String fileName) {
    _bytes = Uint8List.fromList(bytes.toList());
    _name = fileName;
    _isReviewMode = true;
    _isLoading = false;         // bytes arrived — no longer loading
    _errorMessage = null;
    _currentHash = sha256.convert(_bytes.toList()).toString();
    notifyListeners();
  }

  /// Call this before navigating to PinchPage when bytes aren't ready yet.
  /// Sets the name so PinchPage's build() guard doesn't redirect to /home,
  /// and raises the loading flag so it shows a spinner instead of crashing.
  void setLoadingState(String fileName) {
    _bytes = Uint8List(0);
    _name = fileName;
    _isReviewMode = true;
    _isLoading = true;
    _errorMessage = null;
    _currentHash = '';
    _pdf = PlatformFile(name: fileName, path: '', size: 0, bytes: Uint8List(0));
    notifyListeners();
  }

  /// Call this when the background Firestore fetch fails.
  void setError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void setPage(int page) {
    _page = page;
  }

  void setReviewMode(bool isReview) {
    _isReviewMode = isReview;
    notifyListeners();
  }

  void reset() {
    _bytes = Uint8List(0);
    _name = '';
    _currentHash = '';
    _pdf = PlatformFile(name: '', path: '', size: 0, bytes: Uint8List(0));
    _page = 1;
    _isReviewMode = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
