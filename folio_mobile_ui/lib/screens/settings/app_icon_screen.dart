import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'package:folio_mobile_ui/screens/settings/app_icon_data.dart';
import 'package:folio_mobile_ui/screens/settings/app_icon_service.dart';
import 'package:provider/provider.dart';

class MenuAppIcon extends StatelessWidget {
  const MenuAppIcon({
    super.key,
    this.borderRadius = const BorderRadius.vertical(
      top: Radius.circular(4.0),
      bottom: Radius.circular(4.0),
    ),
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final currentOption = AppIconData.getById(settings.appIcon);

    return PanelButton(
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (context) => const AppIconScreen()),
      ),
      title: const Text("Alkalmazásikon"),
      leading: AppIconWidget(
        option: currentOption,
        size: 26.0,
        borderRadius: 7.0,
        showShadow: false,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              currentOption.name,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          Icon(
            Icons.keyboard_arrow_right_rounded,
            size: 22.0,
            color: AppColors.of(context).text.withValues(alpha: 0.95),
          ),
        ],
      ),
      borderRadius: borderRadius,
    );
  }
}

class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key});

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final activeOption = AppIconData.getById(settings.appIcon);

    List<AppIconOption> filteredIcons;
    if (_selectedCategory == 'all') {
      filteredIcons = AppIconData.allIcons;
    } else {
      filteredIcons = AppIconData.allIcons
          .where((icon) => icon.category == _selectedCategory)
          .toList();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        leading: BackButton(color: AppColors.of(context).text),
        title: Text(
          "Alkalmazásikon",
          style: TextStyle(
            color: AppColors.of(context).text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Active Hero Preview Card ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    AppIconWidget(
                      option: activeOption,
                      size: 68.0,
                      borderRadius: 16.0,
                      showShadow: true,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 13.0, color: primaryColor),
                                const SizedBox(width: 4.0),
                                Text(
                                  "Jelenleg kiválasztva",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            activeOption.name,
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.of(context).text,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            "${activeOption.categoryName} • ${activeOption.subtitle}",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category Selector Pills ───────────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildCategoryChip(
                    id: 'all',
                    label: 'Összes (${AppIconData.allIcons.length})',
                  ),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip(
                    id: 'default',
                    label: 'Alapértelmezett (3)',
                  ),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip(
                    id: 'colors',
                    label: 'Színek (20)',
                  ),
                  const SizedBox(width: 8.0),
                  _buildCategoryChip(
                    id: 'special',
                    label: 'Egyedi stílusok (10)',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8.0)),

          // ── Icon Grid ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 14.0,
                childAspectRatio: 0.80,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final option = filteredIcons[index];
                  final isSelected = (option.id == settings.appIcon) ||
                      (settings.appIcon == 'folio_default' &&
                          option.id == 'default');

                  return InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      settings.update(appIcon: option.id);
                      await AppIconService.setAppIcon(option.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            content: Row(
                              children: [
                                AppIconWidget(
                                  option: option,
                                  size: 24.0,
                                  borderRadius: 6.0,
                                  showShadow: false,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text("Alkalmazásikon beállítva: ${option.name}"),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.12)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 6.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIconWidget(
                                option: option,
                                size: 54.0,
                                borderRadius: 13.0,
                                showShadow: true,
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                option.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? primaryColor
                                      : AppColors.of(context).text,
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            Positioned(
                              top: -2.0,
                              right: -2.0,
                              child: Container(
                                padding: const EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 11.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredIcons.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32.0)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({required String id, required String label}) {
    final isSelected = _selectedCategory == id;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.of(context).text,
      ),
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.4),
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.transparent,
        ),
      ),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = id;
        });
      },
    );
  }
}
