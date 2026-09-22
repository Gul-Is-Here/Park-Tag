import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_bottom_nav.dart';
import 'home_tab_view.dart';
import 'inbox_view.dart';
import 'profile_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  static const _tabs = [HomeTabView(), InboxView(), ProfileView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() => IndexedStack(index: controller.tabIndex.value, children: _tabs)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openAddVehicle,
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.background,
        elevation: 2,
        shape: const CircleBorder(),
        // Adding a vehicle (RC card capture -> OCR) — the QR-to-chat
        // scanner is the separate icon at the top of the Home tab, so this
        // one intentionally isn't a QR icon.
        child: const Icon(Icons.add_a_photo_outlined, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(
        () => DashboardBottomNav(
          selectedIndex: controller.tabIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }
}
