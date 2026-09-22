import 'dart:async';

import 'package:parktag_app/app/services/vehicle_service.dart';

class FakeVehicleService implements VehicleService {
  final List<Map<String, dynamic>> saved = [];
  final _vehiclesController = StreamController<List<Map<String, dynamic>>>.broadcast();
  int _idSeq = 0;

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
    final id = 'fake-vehicle-${_idSeq++}';
    saved.add({
      'id': id,
      'uid': uid,
      'ownerName': ownerName,
      'nickname': nickname,
      'make': make,
      'model': model,
      'plateNumber': plateNumber,
      'colorName': colorName,
      'dateOfRegistration': dateOfRegistration,
      'engineNumber': engineNumber,
      'chassisNumber': chassisNumber,
      'address': address,
      'photoPaths': localPhotoPaths,
    });
    _vehiclesController.add(List.of(saved));
    return id;
  }

  @override
  Future<Map<String, dynamic>?> fetchPublicVehicle(String vehicleId) async {
    final match = saved.where((v) => v['id'] == vehicleId);
    if (match.isEmpty) return null;
    final v = match.first;
    return {
      'ownerUid': v['uid'],
      'ownerName': v['ownerName'],
      'nickname': v['nickname'],
      'makeModel': '${v['make']} ${v['model']}',
      'plateNumber': v['plateNumber'],
      'colorName': v['colorName'],
      'photoUrl': (v['photoPaths'] as List).isNotEmpty ? (v['photoPaths'] as List).first : '',
    };
  }

  @override
  Stream<List<Map<String, dynamic>>> watchVehicles(String uid) async* {
    List<Map<String, dynamic>> forUid(List<Map<String, dynamic>> all) =>
        all.where((v) => v['uid'] == uid).map((v) => {...v, 'photoUrls': v['photoPaths']}).toList();

    yield forUid(saved);
    yield* _vehiclesController.stream.map(forUid);
  }
}
