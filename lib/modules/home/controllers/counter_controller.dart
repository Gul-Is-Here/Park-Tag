import 'package:get/get.dart';

import '../models/counter_model.dart';

class CounterController extends GetxController {
  final CounterModel _model = CounterModel();
  final RxInt counter = 0.obs;

  void incrementCounter() {
    _model.increment();
    counter.value = _model.value;
  }
}
