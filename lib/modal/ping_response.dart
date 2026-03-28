import 'package:inventiv_critic_flutter/modal/bug_report.dart';

class AppInstall {
  String id;
  String? createdAt;
  String? updatedAt;
  AppVersion? appVersion;

  AppInstall({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.appVersion,
  });

  factory AppInstall.fromJson(Map<String, dynamic> jsonBody) {
    Map<String, dynamic> json = jsonBody['app_install'];
    return AppInstall(id: json['id'].toString());
  }

  /// Parse a nested app_install object (e.g. within a device response).
  factory AppInstall.fromNestedJson(Map<String, dynamic> json) {
    return AppInstall(
      id: json['id'].toString(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      appVersion:
          json['app_version'] != null
              ? AppVersion.fromJson(json['app_version'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id};
}
