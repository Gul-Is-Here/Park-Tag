abstract class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const otp = '/otp';
  static const commPreference = '/comm-preference';
  static const dashboard = '/dashboard';
  static const addVehicleScan = '/add-vehicle/scan';
  static const addVehicleReview = '/add-vehicle/review';
  static const vehicleDetails = '/vehicle-details';
  static const editVehicle = '/vehicle-details/edit';
  static const chatThread = '/chat-thread';
  static const qrScanner = '/qr-scanner';

  /// FR-04: the public page a QR sticker's scan URL opens — no sign-in
  /// required. `parktag.app/scan/{vehicleId}`.
  static const scanContact = '/scan/:vehicleId';
}
