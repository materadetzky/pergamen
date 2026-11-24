import 'package:flutter/material.dart';

class NavItem {
  final String title;
  final Widget icon;
  final Widget activeIcon;

  const NavItem(
      {required this.title, required this.icon, required this.activeIcon});
}

class NavbarItem extends StatelessWidget {
  const NavbarItem({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
    this.itemsCount = 4,
  });

  final NavItem item;
  final bool active;
  final void Function() onTap;
  final int itemsCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.onSecondaryContainer;
    final inactiveColor = colorScheme.onSurfaceVariant;

    final double circleSize = itemsCount >= 5 ? 44.0 : 48.0;
    final double iconSize = itemsCount >= 5 ? 22.0 : 24.0;

    return Tooltip(
      message: item.title,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: active
                  ? colorScheme.secondaryContainer
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedScale(
                scale: active ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: IconTheme(
                  data: IconThemeData(
                    color: active ? activeColor : inactiveColor,
                    size: iconSize,
                  ),
                  child: active ? item.activeIcon : item.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

