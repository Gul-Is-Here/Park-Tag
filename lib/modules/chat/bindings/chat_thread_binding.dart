import 'package:get/get.dart';

import '../../dashboard/models/message_thread_model.dart';
import '../controllers/chat_thread_controller.dart';

class ChatThreadBinding extends Bindings {
  @override
  void dependencies() {
    final thread = Get.arguments as MessageThreadModel;
    Get.put(ChatThreadController(thread: thread));
  }
}
