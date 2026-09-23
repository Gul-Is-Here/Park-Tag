import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A [GetView] replacement that resolves its controller **once**.
///
/// `GetView.controller` calls `Get.find<T>()` on every single rebuild. That
/// is fine until the controller is removed from GetX's registry while its
/// widget is still mounted — which is exactly what `Get.offAllNamed` does
/// on logout: the bindings for the outgoing route are deleted immediately,
/// but that route stays in the tree for the duration of the transition. Any
/// repaint in that window (a snackbar being inserted, an `Obx` firing, the
/// transition itself) re-runs `Get.find` against an empty registry and
/// throws `"DashboardController" not found`.
///
/// Holding the instance instead means the dying screen can finish painting
/// against the controller it was built with. The controller's `onClose` has
/// already run and its subscriptions are cancelled, so nothing new is
/// started — its `Rx` fields simply keep serving their last values until
/// the widget goes away.
abstract class BoundView<T> extends StatefulWidget {
  const BoundView({super.key});

  /// Same role as `build`, with the controller handed in.
  Widget buildWith(BuildContext context, T controller);

  @override
  State<BoundView<T>> createState() => _BoundViewState<T>();
}

class _BoundViewState<T> extends State<BoundView<T>> {
  late final T _controller = Get.find<T>();

  @override
  Widget build(BuildContext context) => widget.buildWith(context, _controller);
}
