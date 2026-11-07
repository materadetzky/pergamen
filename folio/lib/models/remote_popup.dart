class RemotePopupButton {
  final String text;
  final String action; // 'open_url', 'dismiss'
  final String? url;
  final bool primary;

  const RemotePopupButton({
    required this.text,
    this.action = 'dismiss',
    this.url,
    this.primary = false,
  });

  factory RemotePopupButton.fromJson(Map<String, dynamic> json) {
    return RemotePopupButton(
      text: json['text'] ?? 'OK',
      action: json['action'] ?? 'dismiss',
      url: json['url'],
      primary: json['primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'action': action,
        if (url != null) 'url': url,
        'primary': primary,
      };
}

class RemotePopup {
  final String id;
  final bool enabled;
  final String title;
  final String message;
  final String? tag;
  final String? minAppVersion;
  final String? maxAppVersion;
  final String platform; // 'all', 'android', 'ios'
  final bool forceUpdate;
  final List<RemotePopupButton> buttons;

  const RemotePopup({
    required this.id,
    this.enabled = true,
    required this.title,
    required this.message,
    this.tag,
    this.minAppVersion,
    this.maxAppVersion,
    this.platform = 'all',
    this.forceUpdate = false,
    this.buttons = const [],
  });

  factory RemotePopup.fromJson(Map<String, dynamic> json) {
    var rawButtons = json['buttons'];
    List<RemotePopupButton> buttonsList = [];
    if (rawButtons is List) {
      buttonsList = rawButtons
          .whereType<Map>()
          .map((b) => RemotePopupButton.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    }

    return RemotePopup(
      id: json['id'] ?? json['popup_id'] ?? '',
      enabled: json['enabled'] ?? true,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      tag: json['tag'],
      minAppVersion: json['min_app_version'] ?? json['min_version'],
      maxAppVersion: json['max_app_version'] ?? json['max_version'],
      platform: (json['platform'] ?? 'all').toString().toLowerCase().trim(),
      forceUpdate: json['force_update'] ?? json['force'] ?? false,
      buttons: buttonsList,
    );
  }
}
