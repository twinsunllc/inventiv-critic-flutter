import 'package:inventiv_critic_flutter/model/app.dart';
import 'package:inventiv_critic_flutter/model/device.dart';

class BugReport {
  String? id,
      description,
      stepsToReproduce,
      userIdentifier,
      createdAt,
      updatedAt;
  List<Attachment>? attachments;
  Device? device;
  App? app;
  AppVersion? appVersion;

  BugReport({
    this.id,
    this.description = '',
    this.stepsToReproduce,
    this.userIdentifier,
    this.createdAt,
    this.updatedAt,
    this.attachments,
    this.device,
    this.app,
    this.appVersion,
  });

  BugReport.create({
    required this.description,
    required this.stepsToReproduce,
    this.userIdentifier = 'No user id provided',
  }) : assert(description != null),
       assert(stepsToReproduce != null),
       assert(userIdentifier != null);

  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id']?.toString(),
      description: json['description'],
      stepsToReproduce: json['steps_to_reproduce'],
      userIdentifier: json['user_identifier'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      attachments: Attachment.fromList(json['attachments']),
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
      app: json['app'] != null ? App.fromJson(json['app']) : null,
      appVersion:
          json['app_version'] != null
              ? AppVersion.fromJson(json['app_version'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'description': description,
    'steps_to_reproduce': stepsToReproduce,
    'user_identifier': userIdentifier,
  };
}

class AppVersion {
  String? id, name, code;

  AppVersion({this.id, this.name, this.code});

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id']?.toString(),
      name: json['name'],
      code: json['code'],
    );
  }
}

class Attachment {
  String? name, size, type, uploadedAt, url, path;

  Attachment({
    this.name,
    this.size,
    this.type,
    this.uploadedAt,
    this.url,
    this.path,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      name: json['file_file_name'],
      size: json['file_file_size']?.toString(),
      type: json['file_content_type'],
      uploadedAt: json['file_updated_at'],
      url: json['url'],
    );
  }

  static List<Attachment> fromList(List<dynamic>? items) {
    final List<Attachment> attachments = <Attachment>[];
    if (items == null) {
      return attachments;
    }
    for (final dynamic item in items) {
      attachments.add(Attachment.fromJson(item));
    }
    return attachments;
  }
}
