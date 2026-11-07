import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:folio/models/remote_popup.dart';
import 'package:url_launcher/url_launcher.dart';

class RemotePopupDialog extends StatelessWidget {
  final RemotePopup popup;
  final VoidCallback? onDismiss;

  const RemotePopupDialog({
    super.key,
    required this.popup,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required RemotePopup popup,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: !popup.forceUpdate,
      enableDrag: !popup.forceUpdate,
      useRootNavigator: true,
      builder: (_) => RemotePopupDialog(
        popup: popup,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return PopScope(
      canPop: !popup.forceUpdate,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar (only if dismissible)
                if (!popup.forceUpdate)
                  Center(
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),

                // Header: Icon + Title + optional tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Icon(
                        popup.forceUpdate
                            ? Icons.warning_amber_rounded
                            : Icons.campaign_rounded,
                        size: 24.0,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            popup.title,
                            style: tt.titleMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          if (popup.tag != null && popup.tag!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                popup.tag!,
                                style: tt.bodySmall!.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                // Message body
                if (popup.message.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 280.0),
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: MarkdownBody(
                        data: popup.message.trim(),
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: tt.bodyMedium!.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                          h1: tt.titleSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          h2: tt.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          listBullet: tt.bodyMedium!.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          code: tt.bodySmall!.copyWith(
                            fontFamily: 'monospace',
                            color: cs.primary,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20.0),

                // Buttons
                if (popup.buttons.isNotEmpty)
                  _buildButtons(context, cs, tt)
                else
                  // Fallback close button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onDismiss?.call();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: const Text('Rendben'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, ColorScheme cs, TextTheme tt) {
    if (popup.buttons.length == 1) {
      final btn = popup.buttons.first;
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => _handleButtonAction(context, btn),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: Text(
            btn.text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Multiple buttons
    return Row(
      children: popup.buttons.map((btn) {
        final isLast = btn == popup.buttons.last;
        final child = btn.primary
            ? FilledButton(
                onPressed: () => _handleButtonAction(context, btn),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: Text(
                  btn.text,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            : OutlinedButton(
                onPressed: () => _handleButtonAction(context, btn),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: Text(btn.text),
              );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0.0 : 10.0),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleButtonAction(
      BuildContext context, RemotePopupButton btn) async {
    if (btn.action == 'open_url' && btn.url != null && btn.url!.isNotEmpty) {
      final uri = Uri.tryParse(btn.url!);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!popup.forceUpdate || btn.action == 'dismiss') {
      onDismiss?.call();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
