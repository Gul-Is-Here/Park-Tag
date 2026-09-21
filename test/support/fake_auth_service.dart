import 'package:parktag_app/app/services/auth_service.dart';

/// In-memory stand-in for [AuthService] so widget tests never touch the
/// real Firebase SDK. Defaults permissive (any phone is "registered") so
/// existing flows keep working; tests that specifically exercise the
/// register-before-login gate can flip [registerAllByDefault] off.
class FakeAuthService implements AuthService {
  bool registerAllByDefault = true;
  final Set<String> registeredPhones = {};
  final Map<String, Map<String, dynamic>> profiles = {};
  int _uidSeq = 0;

  bool _signedIn = false;
  String? _currentUid;
  String? _currentPhone;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get currentUid => _currentUid;

  @override
  String? get currentPhone => _currentPhone;

  /// Test helper: simulate an already-signed-in resident (e.g. across an app
  /// restart) without going through the OTP flow.
  void signInAs({required String uid, required String phone, Map<String, dynamic>? profile}) {
    _signedIn = true;
    _currentUid = uid;
    _currentPhone = phone;
    if (profile != null) profiles[uid] = profile;
  }

  @override
  Future<void> sendOtp({
    required String e164Phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    onCodeSent('fake-verification-id');
  }

  @override
  Future<String> confirmOtp({required String verificationId, required String smsCode}) async {
    _signedIn = true;
    _currentUid ??= 'fake-uid-${_uidSeq++}';
    return _currentUid!;
  }

  @override
  Future<bool> phoneIsRegistered(String e164Phone) async {
    if (registerAllByDefault) return true;
    return registeredPhones.contains(e164Phone);
  }

  @override
  Future<void> createResidentProfile({
    required String uid,
    required String name,
    required String phone,
    String? cnic,
  }) async {
    registeredPhones.add(phone);
    _currentPhone = phone;
    profiles[uid] = {'name': name, 'phone': phone, if (cnic != null && cnic.isNotEmpty) 'cnic': cnic};
  }

  @override
  Future<Map<String, dynamic>?> fetchResidentProfile(String uid) async => profiles[uid];

  @override
  Future<void> updateResidentProfile({required String uid, required String name}) async {
    profiles[uid] = {...?profiles[uid], 'name': name};
  }

  @override
  Future<void> deleteResidentAccount(String uid) async {
    profiles.remove(uid);
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _currentUid = null;
    _currentPhone = null;
  }
}
