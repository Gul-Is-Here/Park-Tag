import 'package:flutter/material.dart';

/// Shared swatch lookup so the resident app and the public Scan Contact
/// Page (which only ever sees a vehicle's [colorName] string over Firestore)
/// render the same color dot for a vehicle.
Color vehicleColorForName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'white':
      return const Color(0xFFF5F1E8);
    case 'black':
      return const Color(0xFF2B2B2B);
    case 'silver':
      return const Color(0xFFC2C2BE);
    case 'grey':
    case 'gray':
      return const Color(0xFF8A8A85);
    case 'red':
      return const Color(0xFFC1443C);
    case 'blue':
      return const Color(0xFF3E6FB0);
    default:
      return const Color(0xFF8A8A85);
  }
}
