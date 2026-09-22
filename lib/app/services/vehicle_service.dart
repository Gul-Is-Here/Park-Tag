import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Wraps Firestore/Storage for vehicle records (FR-02) so controllers never
/// touch the Firebase SDKs directly, and can be tested against a fake.
abstract class VehicleService {
  /// Uploads [localPhotoPaths] to Storage, writes the vehicle document under
  /// `users/{uid}/vehicles`, denormalizes a public-readable copy under the
  /// top-level `vehicles` collection for the Scan Contact Page (FR-04), and
  /// returns the new vehicle's id — used to build its QR scan URL
  /// (FR-03: `parktag.app/scan/{vehicleId}`).
  Future<String> saveVehicle({
    required String uid,
    required String ownerName,
    required String nickname,
    required String make,
    required String model,
    required String plateNumber,
    required String colorName,
    required String dateOfRegistration,
    required String engineNumber,
    required String chassisNumber,
    required String address,
    required List<String> localPhotoPaths,
  });

  /// Looks up the public-safe fields for a vehicle by its QR-scan id —
  /// backs the public Scan Contact Page, which anyone can open without
  /// signing in. Returns null when no vehicle has this id.
  Future<Map<String, dynamic>?> fetchPublicVehicle(String vehicleId);

  /// Real-time list of a resident's own vehicles (`users/{uid}/vehicles`),
  /// newest first — drives the Home tab so a freshly-saved vehicle (or an
  /// edit) shows up immediately without a manual refresh. Each map includes
  /// its Firestore document id under `id`.
  Stream<List<Map<String, dynamic>>> watchVehicles(String uid);
}

class FirebaseVehicleService implements VehicleService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Future<String> saveVehicle({
    required String uid,
    required String ownerName,
    required String nickname,
    required String make,
    required String model,
    required String plateNumber,
    required String colorName,
    required String dateOfRegistration,
    required String engineNumber,
    required String chassisNumber,
    required String address,
    required List<String> localPhotoPaths,
  }) async {
    final doc = _firestore.collection('users').doc(uid).collection('vehicles').doc();

    final photoUrls = <String>[];
    for (var i = 0; i < localPhotoPaths.length; i++) {
      final ref = _storage.ref('vehicle_photos/$uid/${doc.id}/$i.jpg');
      await ref.putFile(File(localPhotoPaths[i]));
      photoUrls.add(await ref.getDownloadURL());
    }

    await doc.set({
      'nickname': nickname,
      'make': make,
      'model': model,
      'plateNumber': plateNumber,
      'colorName': colorName,
      'dateOfRegistration': dateOfRegistration,
      'engineNumber': engineNumber,
      'chassisNumber': chassisNumber,
      'address': address,
      'photoUrls': photoUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('vehicles').doc(doc.id).set({
      'ownerUid': uid,
      'ownerName': ownerName,
      'nickname': nickname,
      'makeModel': '$make $model'.trim(),
      'plateNumber': plateNumber,
      'colorName': colorName,
      'photoUrl': photoUrls.isNotEmpty ? photoUrls.first : '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  @override
  Future<Map<String, dynamic>?> fetchPublicVehicle(String vehicleId) async {
    final doc = await _firestore.collection('vehicles').doc(vehicleId).get();
    return doc.data();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchVehicles(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}
