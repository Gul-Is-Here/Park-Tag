import 'package:get/get.dart';

import '../controllers/scan_contact_controller.dart';

class ScanContactBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ScanContactController());
  }
}
