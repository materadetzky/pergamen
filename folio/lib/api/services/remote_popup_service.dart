import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:folio/api/client.dart';
import 'package:folio/models/release.dart';
import 'package:folio/models/remote_popup.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_mobile_ui/common/widgets/remote_popup/remote_popup_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class RemotePopupService {
  static bool _hasChecked = false;

  /// Fetches the remote popup JSON from GitHub raw URL.
  static Future<RemotePopup?> fetchPopup() async {
    try {
      final response = await http
          .get(Uri.parse(FilcAPI.remotePopup))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return RemotePopup.fromJson(decoded);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[RemotePopupService] fetch error: $e');
      }
    }
    return null;
  }

  /// Evaluates whether the popup should be shown to the user on this device.
  static bool shouldShow({
    required RemotePopup popup,
    required String currentVersion,
    required List<String> seenIds,
  }) {
    if (!popup.enabled || popup.id.trim().isEmpty) return false;

    // Check if user already saw and dismissed this popup (unless forceUpdate is true)
    final popupSeenKey = 'popup_${popup.id.trim()}';
    if (!popup.forceUpdate && seenIds.contains(popupSeenKey)) {
      return false;
    }

    // Platform filter
    final p = popup.platform.toLowerCase();
    if (p != 'all') {
      if (p == 'android' && !Platform.isAndroid) return false;
      if (p == 'ios' && !Platform.isIOS) return false;
    }

    // Version filter (optional min/max)
    final curVer = Version.fromString(currentVersion);

    if (popup.minAppVersion != null && popup.minAppVersion!.trim().isNotEmpty) {
      final minVer = Version.fromString(popup.minAppVersion!);
      if (curVer.compareTo(minVer) < 0) return false;
    }

    if (popup.maxAppVersion != null && popup.maxAppVersion!.trim().isNotEmpty) {
      final maxVer = Version.fromString(popup.maxAppVersion!);
      if (curVer.compareTo(maxVer) > 0) return false;
    }

    return true;
  }

  /// Call after the first frame in NavigationScreen or Home.
  static Future<void> checkForPopup(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final popup = await fetchPopup();
      if (popup == null || !context.mounted) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final settings = Provider.of<SettingsProvider>(context, listen: false);

      if (shouldShow(
        popup: popup,
        currentVersion: packageInfo.version,
        seenIds: settings.seenNews,
      )) {
        if (!context.mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          RemotePopupDialog.show(
            context,
            popup: popup,
            onDismiss: () {
              settings.update(seenNewsId: 'popup_${popup.id.trim()}');
            },
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[RemotePopupService] check error: $e');
      }
    }
  }
}
