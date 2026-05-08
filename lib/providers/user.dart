import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pomodoro/services/api_key_service.dart';

class MyUser with ChangeNotifier {
  bool isLoggedIn = false;
  String username = '';
  late UserCredential credentials;

  Future<void> setUser() async {
    try {
      username = FirebaseAuth.instance.currentUser!.email!;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> logIn(
    String email,
    String password,
  ) async {
    try {
      credentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      username = credentials.user!.email!;

      await _ensureUserDocument(credentials.user!);

      await _restoreApiKeyFromFirestore(
        credentials.user!,
      );

      if (kDebugMode) {
        print(credentials.user);
      }

      return credentials;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  Future<UserCredential> signUp(
    String email,
    String password,
  ) async {
    try {
      credentials = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      username = credentials.user!.email!;

      await _ensureUserDocument(
        credentials.user!,
      );

      if (kDebugMode) {
        print(credentials.user);
      }

      return credentials;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }

      rethrow;
    }
  }

  Future<void> resetPassword(
    String email,
  ) async {
    await FirebaseAuth.instance
        .sendPasswordResetEmail(
      email: email,
    );
  }

  Future<void> _ensureUserDocument(
    User user,
  ) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName':
            user.displayName ?? 'Student',
        'photoURL': user.photoURL ?? '',
        'createdAt':
            FieldValue.serverTimestamp(),
        'totalAnswered': 0,
        'totalCorrect': 0,
        'weekScore': 0.0,
        'currentStreak': 0,
        'encryptedApiKey': '',
      });
    } else {
      await ref.update({
        'email': user.email ?? '',
        'displayName':
            user.displayName ?? 'Student',
        'photoURL': user.photoURL ?? '',
        'lastLoginAt':
            FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _restoreApiKeyFromFirestore(
    User user,
  ) async {
    // Already cached locally
    if (await ApiKeyService.hasApiKey()) {
      return;
    }

    try {
      final doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      final encrypted =
          doc.data()?['encryptedApiKey']
              as String?;

      if (encrypted == null ||
          encrypted.isEmpty) {
        return;
      }

      final decrypted =
          ApiKeyService.decryptFromFirestore(
        payload: encrypted,
        uid: user.uid,
      );

      if (decrypted != null &&
          decrypted.isNotEmpty) {
        // Cache locally
        await ApiKeyService
            .saveApiKeyLocally(
          decrypted,
        );

        if (kDebugMode) {
          print(
            'API key restored successfully.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'API restore failed: $e',
        );
      }
    }
  }

  static Future<void>
      pushApiKeyToFirestore(
    String uid,
    String apiKey,
  ) async {
    // Save locally first
    await ApiKeyService
        .saveApiKeyLocally(
      apiKey,
    );

    // Encrypt for Firestore
    final encrypted =
        ApiKeyService.encryptForFirestore(
      apiKey: apiKey,
      uid: uid,
    );

    // Upload encrypted copy
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'encryptedApiKey': encrypted,
    });
  }

  static Future<void> deleteApiKey(
    String uid,
  ) async {
    // Remove local cache
    await ApiKeyService.deleteApiKey();

    // Remove cloud copy
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'encryptedApiKey': '',
    });
  }
}