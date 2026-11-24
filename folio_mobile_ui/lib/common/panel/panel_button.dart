import 'dart:ui';

import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';

class PanelButton extends StatelessWidget {
  const PanelButton({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0),
    this.leading,
    this.title,
    this.trailing,
    this.background = false,
    this.trailingDivider = false,
    this.borderRadius,
    this.longPressInstead = false,
  });

  final void Function()? onPressed;
  final void Function()? onLongPress;
  final EdgeInsetsGeometry padding;
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final bool background;
  final bool trailingDivider;
  final BorderRadius? borderRadius;
  final bool longPressInstead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = RawMaterialButton(
      onPressed: !longPressInstead ? onPressed : null,
      onLongPress: longPressInstead ? onPressed : onLongPress,
      padding: padding,
      shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(24.0)),
      fillColor: background
          ? Colors.white.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.light ? .35 : .2)
          : null,
      child: ListTile(
        leading: leading != null
            ? Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                alignment: Alignment.center,
                child: Theme(
                  data: Theme.of(context).copyWith(
                      iconTheme: IconThemeData(
                          color: colorScheme.onSecondaryContainer, size: 20.0)),
                  child: leading!,
                ),
              )
            : null,
        trailing: trailingDivider
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    width: 1.5,
                    height: 28.0,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).text.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(45.0),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              )
            : trailing,
        title: title != null
            ? DefaultTextStyle(
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 15.5),
                child: title!)
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
        visualDensity: VisualDensity.compact,
      ),
    );

    if (!background) return button;

    return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12.0,
          sigmaY: 12.0,
        ),
        child: button);
  }
}
