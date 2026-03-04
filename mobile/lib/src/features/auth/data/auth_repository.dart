import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/domain/app_user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String> _generateUniqueFriendCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
      );
      final existing = await _usersCol
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
    required String language,
    bool isAIAssisted = false,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.updateDisplayName(displayName);

    final friendCode = await _generateUniqueFriendCode();

    final appUser = AppUser(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      language: language,
      friendCode: friendCode,
      isAIAssisted: isAIAssisted,
      createdAt: DateTime.now(),
    );

    await _usersCol.doc(credential.user!.uid).set(appUser.toFirestore());

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) {
    return _usersCol.doc(uid).set(updates, SetOptions(merge: true));
  }

  Stream<AppUser?> watchUserProfile(String uid) {
    return _usersCol.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromFirestore(doc) : null,
        );
  }
}
