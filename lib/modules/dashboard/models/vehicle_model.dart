import 'package:flutter/material.dart';

class VehicleModel {
  const VehicleModel({
    required this.nickname,
    required this.makeModel,
    required this.plateNumber,
    required this.color,
    this.hasUnread = false,
    this.colorName = '',
    this.dateOfRegistration = '',
    this.engineNumber = '',
    this.chassisNumber = '',
    this.address = '',
    this.photoPaths = const [],
  });

  final String nickname;
  final String makeModel;
  final String plateNumber;
  final Color color;
  final bool hasUnread;

  final String colorName;
  final String dateOfRegistration;
  final String engineNumber;
  final String chassisNumber;
  final String address;
  final List<String> photoPaths;
}
