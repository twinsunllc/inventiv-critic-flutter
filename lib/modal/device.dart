class Device {
  String? identifier,
      manufacturer,
      model,
      networkCarrier,
      platform,
      platformVersion;

  Device({
    this.identifier,
    this.manufacturer,
    this.model,
    this.networkCarrier,
    this.platform,
    this.platformVersion,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      identifier: json['identifier'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      networkCarrier: json['network_carrier'],
      platform: json['platform'],
      platformVersion: json['platform_version'],
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
