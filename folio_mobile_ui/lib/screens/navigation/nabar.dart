import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/screens/navigation/navbar_item.dart';

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final void Function(int index) onSelected;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Separate the main navigation destinations from the trailing "More" action button
    final bool hasActionItem = items.length > 1;
    final List<NavItem> mainItems =
        hasActionItem ? items.sublist(0, items.length - 1) : items;
    final NavItem? actionItem = hasActionItem ? items.last : null;
    final int actionIndex = items.length - 1;

    final Color pillBgColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
      colorScheme.surfaceContainerHigh,
    );

    final Color actionBgColor = Color.alphaBlend(
      colorScheme.tertiary.withValues(alpha: isDark ? 0.28 : 0.22),
      colorScheme.surfaceContainerHigh,
    );

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main Material 3 Expressive Floating Pill Toolbar
            Expanded(
              child: Container(
                height: 64.0,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: pillBgColor,
                  borderRadius: BorderRadius.circular(32.0),
                  border: Border.all(
                    color: colorScheme.outlineVariant
                        .withValues(alpha: isDark ? 0.18 : 0.35),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    mainItems.length,
                    (index) => Expanded(
                      child: NavbarItem(
                        item: mainItems[index],
                        active: index == selectedIndex,
                        onTap: () => onSelected(index),
                        itemsCount: mainItems.length,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Separate Material 3 Expressive Squircle Action Button
            if (actionItem != null) ...[
              const SizedBox(width: 10.0),
              Tooltip(
                message: actionItem.title,
                waitDuration: const Duration(milliseconds: 500),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(actionIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 58.0,
                    height: 58.0,
                    decoration: BoxDecoration(
                      color: actionBgColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: colorScheme.tertiary
                            .withValues(alpha: isDark ? 0.25 : 0.35),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.30 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: colorScheme.onTertiaryContainer,
                          size: 24.0,
                        ),
                        child: actionItem.icon,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

