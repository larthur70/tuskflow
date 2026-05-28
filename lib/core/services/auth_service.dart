import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tuskflow/core/services/user_service.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';

class AuthService {
  AuthService(this._userService);

  final UserService _userService;
  final auth = FirebaseAuth.instance;

  /// Web client ID (client_type 3) from `android/app/google-services.json` –
  /// required on Android so Google returns an ID token for Firebase Auth.
  static const String _googleWebClientId =
      '921186863628-n9aa2t0d15q4smp4trfrg8k0kp26b469.apps.googleusercontent.com';

  Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleSignInInitialized() {
    _googleInitFuture ??= GoogleSignIn.instance.initialize(
      serverClientId: _googleWebClientId,
    );
    return _googleInitFuture!;
  }

  Future<void> signIn() async {
    try {
      await auth.signInAnonymously();
      debugPrint('sign in feito com sucesso');
    } catch (e) {
      debugPrint('erro no login silencioso $e');
    }
  }

  Future<void> logOut() async {
    try {
      await NotificationService.instance.removeCurrentDeviceToken();
      await auth.signOut();
      await GoogleSignIn.instance.signOut();
      debugPrint('logou feito!');
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> setDisplayName(String name) async {
    await auth.currentUser?.updateDisplayName(name);
  }

  AppleAuthProvider _appleProvider() {
    return AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
  }

  bool _isAuthCanceled(FirebaseAuthException e) {
    return e.code == 'cancelled-popup-request' ||
        e.code == 'web-context-canceled' ||
        e.code == 'user-cancelled';
  }

  Future<OAuthCredential?> _googleOAuthCredential() async {
    await _ensureGoogleSignInInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError(
        'Este dispositivo/plataforma não suporta Google Sign-In interativo aqui '
        '(ex.: fluxo Web com renderButton).',
      );
    }

    try {
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'openid'],
      );

      final GoogleSignInAuthentication googleAuth = account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google sign-in returned no ID token.',
        );
      }

      return GoogleAuthProvider.credential(
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserCredential?> _linkOrSignInWithCredential(
    OAuthCredential credential,
  ) async {
    final User? user = auth.currentUser;

    if (user != null && user.isAnonymous) {
      try {
        return await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          return auth.signInWithCredential(credential);
        }
        if (e.code == 'provider-already-linked') {
          return null;
        }
        rethrow;
      }
    }

    return auth.signInWithCredential(credential);
  }

  Future<void> _persistAppleProfile(UserCredential userCredential) async {
    final String? uid = userCredential.user?.uid;
    if (uid == null) return;

    final Map<String, dynamic>? profile =
        userCredential.additionalUserInfo?.profile;

    String? email = userCredential.user?.email;
    String? displayName = userCredential.user?.displayName;

    if (profile != null) {
      final dynamic profileEmail = profile['email'];
      if (profileEmail is String && profileEmail.isNotEmpty) {
        email = profileEmail;
      }

      final String? givenName = profile['given_name'] as String?;
      final String? familyName = profile['family_name'] as String?;
      final String fullName = [
        if (givenName != null && givenName.isNotEmpty) givenName,
        if (familyName != null && familyName.isNotEmpty) familyName,
      ].join(' ').trim();

      if (fullName.isNotEmpty) {
        displayName = displayName ?? fullName;
      }
    }

    if (displayName != null && displayName.isNotEmpty) {
      await userCredential.user?.updateDisplayName(displayName);
    }

    await _userService.saveLinkedAccountProfile(
      uid: uid,
      email: email,
      displayName: displayName,
    );
  }

  /// If the user is anonymous, links Google to the current account (same UID).
  /// On [credential-already-in-use], signs in with that account instead.
  ///
  /// Returns `null` if the user canceled Google sign-in.
  Future<UserCredential?> linkOrSignInWithGoogle() async {
    final OAuthCredential? credential = await _googleOAuthCredential();
    if (credential == null) return null;
    return _linkOrSignInWithCredential(credential);
  }

  /// Native Apple sign-in via Firebase Auth. Links when anonymous; on
  /// [credential-already-in-use], signs in to recover the existing account.
  /// Persists name/email to Firestore (Apple only returns them once).
  Future<UserCredential?> linkOrSignInWithApple() async {
    final AppleAuthProvider provider = _appleProvider();
    final User? user = auth.currentUser;

    try {
      final UserCredential result;
      if (user != null && user.isAnonymous) {
        result = await user.linkWithProvider(provider);
      } else {
        result = await auth.signInWithProvider(provider);
      }
      await _persistAppleProfile(result);
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        final UserCredential result = await auth.signInWithProvider(provider);
        await _persistAppleProfile(result);
        return result;
      }
      if (e.code == 'provider-already-linked') {
        return null;
      }
      if (_isAuthCanceled(e)) {
        return null;
      }
      rethrow;
    }
  }
}
