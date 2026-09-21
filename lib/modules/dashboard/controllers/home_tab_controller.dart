import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../models/vehicle_model.dart';

class HomeTabController extends GetxController {
  // TODO(FR-02): replace with the resident's real name and Firestore-backed
  // vehicle list once auth/vehicle storage is implemented.
  final residentFirstName = 'Ayesha';

  final vehicles = <VehicleModel>[
    const VehicleModel(
      nickname: 'White Corolla',
      makeModel: 'Toyota Corolla Altis',
      plateNumber: 'LEA-2231',
      color: Color(0xFFF5F1E8),
      colorName: 'White',
      hasUnread: true,
      dateOfRegistration: '14 Mar 2022',
      engineNumber: '2ZR-4498231',
      chassisNumber: 'MR053CE3204119876',
      address: '123-B, Model Town, Lahore',
    ),
    const VehicleModel(
      nickname: 'LEB-4470',
      makeModel: 'Honda Civic',
      plateNumber: 'LEB-4470',
      color: Color(0xFF2B2B2B),
      colorName: 'Black',
      dateOfRegistration: '02 Jul 2021',
      engineNumber: 'R18Z1-5510234',
      chassisNumber: 'MRHFB1970MP009812',
      address: '123-B, Model Town, Lahore',
    ),
    const VehicleModel(
      nickname: 'Office Ride',
      makeModel: 'Suzuki Cultus',
      plateNumber: 'LEC-9102',
      color: Color(0xFFC2C2BE),
      colorName: 'Silver',
      dateOfRegistration: '19 Nov 2023',
      engineNumber: 'K10B-3389217',
      chassisNumber: 'MHFDA1CS0P0003345',
      address: '123-B, Model Town, Lahore',
    ),
  ].obs;

  void addVehicle() {
    Get.toNamed(AppRoutes.addVehicleScan);
  }
}
