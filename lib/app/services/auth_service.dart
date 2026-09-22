import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Phone Auth + the Firestore `users` collection so
/// controllers never touch the Firebase SDKs directly (and can be tested
/// against a fake implementation instead).
abstract class AuthService {
  /// Starts Firebase's phone verification for [e164Phone] (e.g. "+923001234567").
  /// Calls [onCodeSent] with the verification id once the SMS goes out, or
  /// [onError] if Firebase rejects the number / send attempt.
  Future<void> sendOtp({
    required String e164Phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  });

  /// Confirms the code the resident typed and signs them in, returning the
  /// Firebase Auth uid.
  Future<String> confirmOtp({required String verificationId, required String smsCode});

  /// Whether a resident already exists for this phone number — used to
  /// route sign-up vs. login: FR-01 expects residents to register once and
  /// log back in afterwards, not re-register every time.
  Future<bool> phoneIsRegistered(String e164Phone);

  /// Creates the resident's Firestore profile after their first successful
  /// sign-up verification. [cnic] is optional — Sign Up may not always
  /// collect it — and is stored as supplied (FR-01.1: identity verification).
  Future<void> createResidentProfile({
    required String uid,
    required String name,
    required String phone,
    String? cnic,
  });

  /// Reads the signed-in resident's Firestore profile (FR-08), or null if
  /// there's no document yet.
  Future<Map<String, dynamic>?> fetchResidentProfile(String uid);

  /// Persists edits made on the Profile screen.
  Future<void> updateResidentProfile({required String uid, required String name});

  /// Registers this device for chat push notifications (FR-05/FR-06) by
  /// adding its FCM token to the resident's profile — a resident may have
  /// more than one device signed in, so tokens accumulate in a set rather
  /// than overwriting a single field.
  Future<void> saveFcmToken({required String uid, required String token});

  /// Called on sign-out so a stale token on a shared/reset device doesn't
  /// keep receiving another resident's notifications.
  Future<void> removeFcmToken({required String uid, required String token});

  /// Saves the choice made on the one-time "app or web?" prompt shown right
  /// after registration (FR-09) — 'app' or 'web'. Drives whether Splash
  /// pushes hard for FCM/push UX or keeps steering the resident back to the
  /// web chat link.
  Future<void> saveCommunicationPreference({required String uid, required String preference});

  /// Permanently removes the resident's Firestore profile and Firebase Auth
  /// account (FR-01.4).
  Future<void> deleteResidentAccount(String uid);

  /// Whether a resident is currently signed in — drives Splash's decision
  /// to skip straight to Dashboard on app restart instead of Onboarding/Login.
  bool get isSignedIn;

  /// The signed-in resident's Firebase Auth uid, or null if signed out.
  String? get currentUid;

  /// The signed-in resident's verified E.164 phone number, or null if signed out.
  String? get currentPhone;

  Future<void> signOut();
}

/// Turns a [FirebaseAuthException] into something a resident (or a developer
/// reading a snackbar) can act on. Firebase's own copy is actively misleading
/// for the region case: a blocked SMS region reports `operation-not-allowed`
/// with a message telling you to enable the Phone provider, even when that
/// provider is already enabled — the real cause is only in the bracketed tail.
String describeAuthFailure(FirebaseAuthException e) {
  final raw = e.message ?? '';

  if (raw.contains('region enabled by the app developer')) {
    return 'SMS to this country is blocked for this Firebase project. '
        'Enable it under Authentication > Settings > SMS region policy.';
  }

  switch (e.code) {
    case 'invalid-phone-number':
      return "That phone number doesn't look right. Check it and try again.";
    case 'too-many-requests':
      return 'Too many attempts from this device — Firebase has temporarily '
          'blocked it. Wait a while, or use a Firebase test phone number.';
    case 'quota-exceeded':
      return "This project's SMS quota is used up. Try again later.";
    case 'app-not-authorized':
      return "This app build isn't authorized for phone sign-in. Check the "
          "SHA-1/SHA-256 fingerprints registered in the Firebase console.";
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    case 'operation-not-allowed':
      return 'Phone sign-in is not enabled for this Firebase project.';
    default:
      return raw.isEmpty ? 'Verification failed. Please try again.' : raw;
  }
}

class FirebaseAuthService implements AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendOtp({
    required String e164Phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android instant/auto verification — sign in right away; the
        // resident may already have moved on to the OTP screen, which is
        // fine, Get.offAllNamed from there just becomes a no-op re-entry.
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {
          // Fall through — the resident still completes verification
          // manually on the OTP screen.
        }
      },
      verificationFailed: (e) => onError(describeAuthFailure(e)),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<String> confirmOtp({required String verificationId, required String smsCode}) async {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    final result = await _auth.signInWithCredential(credential);
    final uid = result.user?.uid;
    if (uid == null) throw Exception('Sign-in failed. Please try again.');
    return uid;
  }

  @override
  Future<bool> phoneIsRegistered(String e164Phone) async {
    final snapshot = await _firestore.collection('users').where('phone', isEqualTo: e164Phone).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> createResidentProfile({
    required String uid,
    required String name,
    required String phone,
    String? cnic,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      if (cnic != null && cnic.isNotEmpty) 'cnic': cnic,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>?> fetchResidentProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Future<void> updateResidentProfile({required String uid, required String name}) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveFcmToken({required String uid, required String token}) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeFcmToken({required String uid, required String token}) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveCommunicationPreference({required String uid, required String preference}) async {
    await _firestore.collection('users').doc(uid).set({
      'communicationPreference': preference,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteResidentAccount(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    await _auth.currentUser?.delete();
  }

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentPhone => _auth.currentUser?.phoneNumber;

  @override
  Future<void> signOut() => _auth.signOut();
}
