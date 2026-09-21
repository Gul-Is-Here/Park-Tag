import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager: the controller drives navigation from onReady, so it must
    // exist even though the view never reads its state.
    Get.put<SplashController>(SplashController());
  }
}
