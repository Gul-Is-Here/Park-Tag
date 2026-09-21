import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Wraps Firestore/Storage for vehicle records (FR-02) so controllers never
/// touch the Firebase SDKs directly, and can be tested against a fake.
abstract class VehicleService {
  /// Uploads [localPhotoPaths] to Storage, writes the vehicle document under
  /// `users/{uid}/vehicles`, and returns the new vehicle's id — used to build
  /// its QR scan URL (FR-03: `parktag.app/scan/{vehicleId}`).
  Future<String> saveVehicle({
    required String uid,
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
}

class FirebaseVehicleService implements VehicleService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Future<String> saveVehicle({
    required String uid,
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

    return doc.id;
  }
}
