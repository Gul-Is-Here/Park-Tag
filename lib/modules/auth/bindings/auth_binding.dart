import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../controllers/signup_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(LoginController.new, fenix: true);
    Get.lazyPut<SignUpController>(SignUpController.new, fenix: true);
  }
}
