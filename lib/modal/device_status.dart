class DeviceStatus {
  String? id;
  bool? batteryCharging;
  num? batteryLevel;
  String? batteryHealth;
  num? diskFree;
  num? diskPlatform;
  num? diskTotal;
  num? diskUsable;
  num? memoryActive;
  num? memoryFree;
  num? memoryInactive;
  num? memoryPurgable;
  num? memoryTotal;
  num? memoryWired;
  Map<String, dynamic>? metadata;
  bool? networkCellConnected;
  int? networkCellSignalBars;
  bool? networkWifiConnected;
  int? networkWifiSignalBars;

  DeviceStatus({
    this.id,
    this.batteryCharging,
    this.batteryLevel,
    this.batteryHealth,
    this.diskFree,
    this.diskPlatform,
    this.diskTotal,
    this.diskUsable,
    this.memoryActive,
    this.memoryFree,
    this.memoryInactive,
    this.memoryPurgable,
    this.memoryTotal,
    this.memoryWired,
    this.metadata,
    this.networkCellConnected,
    this.networkCellSignalBars,
    this.networkWifiConnected,
    this.networkWifiSignalBars,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      id: json['id']?.toString(),
      batteryCharging: json['battery_charging'],
      batteryLevel: json['battery_level'],
      batteryHealth: json['battery_health'],
      diskFree: json['disk_free'],
      diskPlatform: json['disk_platform'],
      diskTotal: json['disk_total'],
      diskUsable: json['disk_usable'],
      memoryActive: json['memory_active'],
      memoryFree: json['memory_free'],
      memoryInactive: json['memory_inactive'],
      memoryPurgable: json['memory_purgable'],
      memoryTotal: json['memory_total'],
      memoryWired: json['memory_wired'],
      metadata:
          json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'])
              : null,
      networkCellConnected: json['network_cell_connected'],
      networkCellSignalBars: json['network_cell_signal_bars'],
      networkWifiConnected: json['network_wifi_connected'],
      networkWifiSignalBars: json['network_wifi_signal_bars'],
    );
  }

  static List<DeviceStatus> fromList(List<dynamic>? items) {
    if (items == null) return <DeviceStatus>[];
    return items
        .map((item) => DeviceStatus.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
