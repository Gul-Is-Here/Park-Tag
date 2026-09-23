import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.unreadCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// Unread messages across every conversation, shown on the Messages tab.
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.directions_car_filled_outlined,
              selectedIcon: Icons.directions_car_filled,
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: 'Messages',
              isSelected: selectedIndex == 1,
              badgeCount: unreadCount,
              onTap: () => onTap(1),
            ),
            // Center gap for the docked scanner FAB.
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.yellow : AppColors.faint;
    return Semantics(
      button: true,
      selected: isSelected,
      label: badgeCount > 0
          ? '$label, $badgeCount unread message${badgeCount == 1 ? '' : 's'}'
          : label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconWithBadge(
                icon: isSelected ? selectedIcon : icon,
                color: color,
                badgeCount: badgeCount,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tab icon with its unread badge pinned to the top-right.
///
/// The badge overflows the icon's box deliberately, so adding it never
/// changes the icon's size and the three tabs stay evenly spaced whether
/// or not there are unread messages.
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({required this.icon, required this.color, required this.badgeCount});

  final IconData icon;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color, size: 24),
          if (badgeCount > 0)
            Positioned(
              top: -5,
              right: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(9),
                  // Matches the bar so the badge reads as sitting on top of
                  // the icon rather than merging into it.
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.overline.copyWith(
                    color: Colors.black,
                    fontSize: 9.5,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
