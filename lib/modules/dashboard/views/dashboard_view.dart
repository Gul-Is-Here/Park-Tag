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
        onPressed: controller.openScanner,
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.background,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, size: 28),
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
