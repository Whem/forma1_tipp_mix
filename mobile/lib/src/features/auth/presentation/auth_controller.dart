import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/services/push_notification_service.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/auth/domain/app_user.dart';

void _log(String msg) {
  if (kDebugMode) print(msg);
}

class AuthState {
  const AuthState({this.firebaseUser, this.appUser});

  final User? firebaseUser;
  final AppUser? appUser;

  bool get isAuthenticated => firebaseUser != null;
  AppUser? get user => appUser;

  @override
  String toString() =>
      'AuthState(authenticated=$isAuthenticated, user=${appUser?.displayName})';
}

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUserProfile(firebaseUser.uid);
});

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    _log('AuthController.build() starting...');

    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      next.whenData((user) {
        _log('authStateProvider changed: user=${user?.uid}');
        if (user == null && state.valueOrNull?.isAuthenticated == true) {
          state = const AsyncData(AuthState());
        }
      });
    });

    final user = ref.read(firebaseAuthProvider).currentUser;
    _log('currentUser: ${user?.uid} / ${user?.email}');

    if (user == null) {
      return const AuthState();
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      var profile = await repo.getUserProfile(user.uid);

      if (profile == null) {
        _log('Creating missing profile for ${user.uid}');
        profile = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          language: 'hu',
          createdAt: DateTime.now(),
        );
        await repo.updateUserProfile(user.uid, profile.toFirestore());
      }

      _initPush(user.uid);
      return AuthState(firebaseUser: user, appUser: profile);
    } catch (e, st) {
      _log('build() ERROR: $e\n$st');
      rethrow;
    }
  }

  void _initPush(String uid) {
    try {
      ref.read(pushNotificationServiceProvider).init(uid);
    } catch (e) {
      _log('FCM init error: $e');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _log('login() called with $email');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final credential =
          await repo.login(email: email, password: password);
      final user = credential.user!;
      _log('Firebase signIn OK: ${user.uid}');

      var profile = await repo.getUserProfile(user.uid);

      if (profile == null) {
        profile = AppUser(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? email.split('@').first,
          language: 'hu',
          createdAt: DateTime.now(),
        );
        await repo.updateUserProfile(user.uid, profile.toFirestore());
      }

      _initPush(user.uid);
      return AuthState(firebaseUser: user, appUser: profile);
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String language,
    bool isAIAssisted = false,
  }) async {
    _log('register() called with $email');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final credential = await repo.register(
        email: email,
        password: password,
        displayName: displayName,
        language: language,
        isAIAssisted: isAIAssisted,
      );
      final profile = await repo.getUserProfile(credential.user!.uid);
      _initPush(credential.user!.uid);
      return AuthState(firebaseUser: credential.user, appUser: profile);
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(AuthState());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
