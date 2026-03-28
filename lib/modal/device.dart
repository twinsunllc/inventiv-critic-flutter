import 'package:inventiv_critic_flutter/modal/device_status.dart';
import 'package:inventiv_critic_flutter/modal/ping_response.dart';

class Device {
  String? id,
      identifier,
      manufacturer,
      model,
      networkCarrier,
      platform,
      platformVersion,
      createdAt,
      updatedAt;
  List<AppInstall>? appInstall;
  List<DeviceStatus>? deviceStatus;

  Device({
    this.id,
    this.identifier,
    this.manufacturer,
    this.model,
    this.networkCarrier,
    this.platform,
    this.platformVersion,
    this.createdAt,
    this.updatedAt,
    this.appInstall,
    this.deviceStatus,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString(),
      identifier: json['identifier'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      networkCarrier: json['network_carrier'],
      platform: json['platform'],
      platformVersion: json['platform_version'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      appInstall:
          json['app_install'] != null
              ? (json['app_install'] as List<dynamic>)
                  .map(
                    (item) =>
                        AppInstall.fromNestedJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : null,
      deviceStatus: DeviceStatus.fromList(json['device_status']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'identifier': identifier,
    'manufacturer': manufacturer,
    'model': model,
    'network_carrier': networkCarrier,
    'platform': platform,
    'platform_version': platformVersion,
  };
}
