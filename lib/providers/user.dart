// lib/providers/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pomodoro/services/api_key_service.dart';
import 'package:unique_names_generator/unique_names_generator.dart';

class MyUser with ChangeNotifier {
  bool isLoggedIn = false;

  // User info fields
  String username = '';
  String email = '';

  late UserCredential credentials;

  final _uniqueName = UniqueNamesGenerator(
    config: Config(
      length: 2,
      separator: ' ',
      dictionaries: [adjectives, animals],
    ),
  );

  //
  Future<void> setUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    email = user.email ?? '';


    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      username = doc.data()?['displayName'] as String? ?? email;
    } catch (_) {
      username = user.displayName ?? email;
    }

    notifyListeners();
  }

  Future<UserCredential> logIn(String email, String password) async {
    try {
      credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserDocument(credentials.user!);
      await _restoreApiKeyFromFirestore(credentials.user!);
      await setUser();

      if (kDebugMode) print(credentials.user);
      return credentials;
    } catch (e) {
      if (kDebugMode) print(e);
      rethrow;
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserDocument(credentials.user!);
      await setUser();

      if (kDebugMode) print(credentials.user);
      return credentials;
    } catch (e) {
      if (kDebugMode) print(e);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> _ensureUserDocument(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // Create a new user document with a unique display name and default stats.
      final generatedName = _uniqueName.generate();

      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': generatedName,  
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'totalAnswered': 0,
        'totalCorrect': 0,
        'weekScore': 0.0,
        'currentStreak': 0,
        'encryptedApiKey': '',
      });
    } else {
      // Update existing document with latest email and photoURL in case they changed,
      // without overwriting the displayName or stats.
      await ref.update({
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Attempt to restore the user's API key from Firestore if it's not already stored locally. 
  // This allows users to retain their API key across devices and sessions without having to re-enter it,
  // while still keeping it secure through encryption.
  Future<void> _restoreApiKeyFromFirestore(User user) async {
    if (await ApiKeyService.hasApiKey()) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final encrypted = doc.data()?['encryptedApiKey'] as String?;
      if (encrypted == null || encrypted.isEmpty) return;

      final decrypted = ApiKeyService.decryptFromFirestore(
        payload: encrypted,
        uid: user.uid,
      );

      if (decrypted != null && decrypted.isNotEmpty) {
        await ApiKeyService.saveApiKeyLocally(decrypted);
        if (kDebugMode) print('API key restored successfully.');
      }
    } catch (e) {
      if (kDebugMode) print('API restore failed: $e');
    }
  }

  // Push the user's API key to Firestore in encrypted form, and also save it locally. 
  // This ensures the key is backed up and can be restored on other devices, while keeping it secure.
  static Future<void> pushApiKeyToFirestore(String uid, String apiKey) async {
    await ApiKeyService.saveApiKeyLocally(apiKey);
    final encrypted = ApiKeyService.encryptForFirestore(
      apiKey: apiKey,
      uid: uid,
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'encryptedApiKey': encrypted});
  }

  static Future<void> deleteApiKey(String uid) async {
    await ApiKeyService.deleteApiKey();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'encryptedApiKey': ''});
  }
}