import 'package:flutter_test/flutter_test.dart';
import 'package:inventiv_critic_flutter/modal/bug_report.dart';
import 'package:inventiv_critic_flutter/modal/device.dart';
import 'package:inventiv_critic_flutter/modal/device_status.dart';
import 'package:inventiv_critic_flutter/modal/paginated_response.dart';
import 'package:inventiv_critic_flutter/modal/ping_response.dart';
import 'package:inventiv_critic_flutter/modal/app.dart';

void main() {
  group('AppInstall', () {
    test('fromJson parses UUID string id', () {
      final json = {
        'app_install': {'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'},
      };
      final appInstall = AppInstall.fromJson(json);
      expect(appInstall.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
    });

    test('fromJson handles integer id by converting to string', () {
      final json = {
        'app_install': {'id': 42},
      };
      final appInstall = AppInstall.fromJson(json);
      expect(appInstall.id, '42');
    });

    test('toJson returns id as string', () {
      final appInstall = AppInstall(id: 'uuid-123');
      expect(appInstall.toJson(), {'id': 'uuid-123'});
    });
  });

  group('BugReport', () {
    test('fromJson parses v3 response with nested objects', () {
      final json = {
        'id': 'bug-uuid-123',
        'description': 'Test bug',
        'steps_to_reproduce': 'Step 1',
        'user_identifier': 'user@test.com',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'attachments': [],
        'device': {
          'identifier': 'device-uuid',
          'manufacturer': 'Google',
          'model': 'Pixel 7',
          'network_carrier': 'T-Mobile',
          'platform': 'Android',
          'platform_version': '14',
        },
        'app': {
          'name': 'TestApp',
          'package': 'com.test.app',
          'platform': 'Android',
          'version': {'code': '1', 'name': '1.0.0'},
        },
        'app_version': {'id': 'av-uuid-123', 'name': '1.0.0', 'code': '1'},
      };

      final report = BugReport.fromJson(json);
      expect(report.id, 'bug-uuid-123');
      expect(report.description, 'Test bug');
      expect(report.stepsToReproduce, 'Step 1');
      expect(report.userIdentifier, 'user@test.com');
      expect(report.device, isNotNull);
      expect(report.device!.manufacturer, 'Google');
      expect(report.device!.model, 'Pixel 7');
      expect(report.app, isNotNull);
      expect(report.app!.name, 'TestApp');
      expect(report.appVersion, isNotNull);
      expect(report.appVersion!.id, 'av-uuid-123');
      expect(report.appVersion!.name, '1.0.0');
    });

    test('fromJson handles null nested objects', () {
      final json = {
        'id': 'bug-uuid-456',
        'description': 'Minimal bug',
        'steps_to_reproduce': null,
        'user_identifier': null,
        'created_at': null,
        'updated_at': null,
        'attachments': null,
        'device': null,
        'app': null,
        'app_version': null,
      };

      final report = BugReport.fromJson(json);
      expect(report.id, 'bug-uuid-456');
      expect(report.description, 'Minimal bug');
      expect(report.device, isNull);
      expect(report.app, isNull);
      expect(report.appVersion, isNull);
      expect(report.attachments, isEmpty);
    });

    test('fromJson handles integer id by converting to string', () {
      final json = {
        'id': 999,
        'description': 'Legacy',
        'steps_to_reproduce': null,
        'user_identifier': null,
        'created_at': null,
        'updated_at': null,
        'attachments': null,
      };

      final report = BugReport.fromJson(json);
      expect(report.id, '999');
    });
  });

  group('Attachment', () {
    test('fromJson parses v3 field names', () {
      final json = {
        'file_file_name': 'screenshot.png',
        'file_file_size': 12345,
        'file_content_type': 'image/png',
        'file_updated_at': '2026-01-01T00:00:00Z',
        'url': 'https://example.com/screenshot.png',
      };

      final attachment = Attachment.fromJson(json);
      expect(attachment.name, 'screenshot.png');
      expect(attachment.size, '12345');
      expect(attachment.type, 'image/png');
      expect(attachment.uploadedAt, '2026-01-01T00:00:00Z');
      expect(attachment.url, 'https://example.com/screenshot.png');
    });

    test('fromJson handles null file_file_size', () {
      final json = {
        'file_file_name': 'test.txt',
        'file_file_size': null,
        'file_content_type': 'text/plain',
        'file_updated_at': null,
        'url': null,
      };

      final attachment = Attachment.fromJson(json);
      expect(attachment.name, 'test.txt');
      expect(attachment.size, isNull);
      expect(attachment.url, isNull);
    });

    test('fromList handles null input', () {
      final attachments = Attachment.fromList(null);
      expect(attachments, isEmpty);
    });

    test('fromList parses multiple attachments', () {
      final items = [
        {
          'file_file_name': 'file1.png',
          'file_file_size': 100,
          'file_content_type': 'image/png',
          'file_updated_at': '2026-01-01',
          'url': 'https://example.com/file1.png',
        },
        {
          'file_file_name': 'file2.txt',
          'file_file_size': 200,
          'file_content_type': 'text/plain',
          'file_updated_at': '2026-01-02',
          'url': 'https://example.com/file2.txt',
        },
      ];

      final attachments = Attachment.fromList(items);
      expect(attachments.length, 2);
      expect(attachments[0].name, 'file1.png');
      expect(attachments[1].name, 'file2.txt');
    });
  });

  group('AppVersion', () {
    test('fromJson parses correctly', () {
      final json = {'id': 'av-uuid-789', 'name': '2.0.0', 'code': '42'};

      final version = AppVersion.fromJson(json);
      expect(version.id, 'av-uuid-789');
      expect(version.name, '2.0.0');
      expect(version.code, '42');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{'id': null, 'name': null, 'code': null};

      final version = AppVersion.fromJson(json);
      expect(version.id, isNull);
      expect(version.name, isNull);
      expect(version.code, isNull);
    });
  });

  group('Device', () {
    test('fromJson parses correctly', () {
      final json = {
        'identifier': 'dev-uuid',
        'manufacturer': 'Samsung',
        'model': 'Galaxy S24',
        'network_carrier': 'Verizon',
        'platform': 'Android',
        'platform_version': '14',
      };

      final device = Device.fromJson(json);
      expect(device.identifier, 'dev-uuid');
      expect(device.manufacturer, 'Samsung');
      expect(device.model, 'Galaxy S24');
      expect(device.platform, 'Android');
    });
  });

  group('App', () {
    test('fromJson parses correctly', () {
      final json = {
        'name': 'MyApp',
        'package': 'com.example.myapp',
        'platform': 'iOS',
        'version': {'code': '10', 'name': '2.1.0'},
      };

      final app = App.fromJson(json);
      expect(app.name, 'MyApp');
      expect(app.package, 'com.example.myapp');
      expect(app.platform, 'iOS');
      expect(app.version.code, '10');
      expect(app.version.name, '2.1.0');
    });
  });

  group('DeviceStatus', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'ds-uuid-123',
        'battery_charging': true,
        'battery_level': 85,
        'battery_health': 'Good',
        'disk_free': 1073741824,
        'disk_platform': 2147483648,
        'disk_total': 137438953472,
        'disk_usable': 128849018880,
        'memory_active': 1073741824,
        'memory_free': 536870912,
        'memory_inactive': 536870912,
        'memory_purgable': 2147483648,
        'memory_total': 8589934592,
        'memory_wired': 134217728,
        'metadata': {'latitude': 31.98, 'longitude': -23.56},
        'network_cell_connected': true,
        'network_cell_signal_bars': 3,
        'network_wifi_connected': true,
        'network_wifi_signal_bars': 4,
      };

      final status = DeviceStatus.fromJson(json);
      expect(status.id, 'ds-uuid-123');
      expect(status.batteryCharging, true);
      expect(status.batteryLevel, 85);
      expect(status.batteryHealth, 'Good');
      expect(status.diskFree, 1073741824);
      expect(status.diskTotal, 137438953472);
      expect(status.memoryTotal, 8589934592);
      expect(status.metadata, {'latitude': 31.98, 'longitude': -23.56});
      expect(status.networkCellConnected, true);
      expect(status.networkCellSignalBars, 3);
      expect(status.networkWifiConnected, true);
      expect(status.networkWifiSignalBars, 4);
    });

    test('fromJson handles all null fields', () {
      final json = <String, dynamic>{
        'id': null,
        'battery_charging': null,
        'battery_level': null,
        'battery_health': null,
        'disk_free': null,
        'disk_platform': null,
        'disk_total': null,
        'disk_usable': null,
        'memory_active': null,
        'memory_free': null,
        'memory_inactive': null,
        'memory_purgable': null,
        'memory_total': null,
        'memory_wired': null,
        'metadata': null,
        'network_cell_connected': null,
        'network_cell_signal_bars': null,
        'network_wifi_connected': null,
        'network_wifi_signal_bars': null,
      };

      final status = DeviceStatus.fromJson(json);
      expect(status.id, isNull);
      expect(status.batteryCharging, isNull);
      expect(status.metadata, isNull);
    });

    test('fromList parses list of statuses', () {
      final items = [
        {'id': 'ds-1', 'battery_level': 50},
        {'id': 'ds-2', 'battery_level': 75},
      ];
      final statuses = DeviceStatus.fromList(items);
      expect(statuses.length, 2);
      expect(statuses[0].id, 'ds-1');
      expect(statuses[1].batteryLevel, 75);
    });

    test('fromList handles null input', () {
      final statuses = DeviceStatus.fromList(null);
      expect(statuses, isEmpty);
    });
  });

  group('PaginatedResponse', () {
    test('fromJson parses bug_reports response', () {
      final json = {
        'count': 42,
        'current_page': 1,
        'total_pages': 5,
        'bug_reports': [
          {
            'id': 'bug-1',
            'description': 'First bug',
            'steps_to_reproduce': null,
            'user_identifier': null,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'attachments': null,
          },
          {
            'id': 'bug-2',
            'description': 'Second bug',
            'steps_to_reproduce': null,
            'user_identifier': null,
            'created_at': null,
            'updated_at': null,
            'attachments': null,
          },
        ],
      };

      final response = PaginatedResponse.fromJson(
        json,
        'bug_reports',
        BugReport.fromJson,
      );
      expect(response.count, 42);
      expect(response.currentPage, 1);
      expect(response.totalPages, 5);
      expect(response.items.length, 2);
      expect(response.items[0].id, 'bug-1');
      expect(response.items[1].description, 'Second bug');
    });

    test('fromJson parses devices response', () {
      final json = {
        'count': 2,
        'current_page': 1,
        'total_pages': 1,
        'devices': [
          {
            'id': 'dev-uuid-1',
            'identifier': 'device-1',
            'manufacturer': 'Google',
            'model': 'Pixel 7',
            'platform': 'Android',
            'platform_version': '14',
          },
        ],
      };

      final response = PaginatedResponse.fromJson(
        json,
        'devices',
        Device.fromJson,
      );
      expect(response.count, 2);
      expect(response.items.length, 1);
      expect(response.items[0].id, 'dev-uuid-1');
      expect(response.items[0].manufacturer, 'Google');
    });

    test('fromJson handles empty items list', () {
      final json = {
        'count': 0,
        'current_page': 1,
        'total_pages': 0,
        'bug_reports': <dynamic>[],
      };

      final response = PaginatedResponse.fromJson(
        json,
        'bug_reports',
        BugReport.fromJson,
      );
      expect(response.count, 0);
      expect(response.items, isEmpty);
    });
  });

  group('Device (v3 fields)', () {
    test('fromJson parses id, timestamps, and nested associations', () {
      final json = {
        'id': 'dev-uuid-abc',
        'identifier': 'device-id-123',
        'manufacturer': 'Samsung',
        'model': 'Galaxy S24',
        'network_carrier': 'Verizon',
        'platform': 'Android',
        'platform_version': '14',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'app_install': [
          {
            'id': 'ai-uuid-1',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
            'app_version': {'id': 'av-uuid-1', 'name': '1.0.0', 'code': '1'},
          },
        ],
        'device_status': [
          {'id': 'ds-uuid-1', 'battery_level': 90},
        ],
      };

      final device = Device.fromJson(json);
      expect(device.id, 'dev-uuid-abc');
      expect(device.identifier, 'device-id-123');
      expect(device.manufacturer, 'Samsung');
      expect(device.createdAt, '2026-01-01T00:00:00Z');
      expect(device.updatedAt, '2026-01-02T00:00:00Z');
      expect(device.appInstall, isNotNull);
      expect(device.appInstall!.length, 1);
      expect(device.appInstall![0].id, 'ai-uuid-1');
      expect(device.appInstall![0].appVersion, isNotNull);
      expect(device.appInstall![0].appVersion!.id, 'av-uuid-1');
      expect(device.appInstall![0].appVersion!.name, '1.0.0');
      expect(device.deviceStatus, isNotNull);
      expect(device.deviceStatus!.length, 1);
      expect(device.deviceStatus![0].id, 'ds-uuid-1');
      expect(device.deviceStatus![0].batteryLevel, 90);
    });

    test('fromJson handles null nested associations', () {
      final json = {
        'id': 'dev-uuid-xyz',
        'identifier': 'device-id-456',
        'manufacturer': 'Apple',
        'model': 'iPhone 16',
        'platform': 'iOS',
        'platform_version': '18',
        'app_install': null,
        'device_status': null,
      };

      final device = Device.fromJson(json);
      expect(device.id, 'dev-uuid-xyz');
      expect(device.appInstall, isNull);
      expect(device.deviceStatus, isEmpty);
    });

    test('toJson still works for ping request (no new fields)', () {
      final device = Device(
        identifier: 'id-123',
        manufacturer: 'Google',
        model: 'Pixel',
        platform: 'Android',
        platformVersion: '14',
      );
      final json = device.toJson();
      expect(json['identifier'], 'id-123');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('app_install'), false);
    });
  });

  group('AppInstall', () {
    test('fromNestedJson parses with app_version', () {
      final json = {
        'id': 'ai-uuid-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'app_version': {'id': 'av-uuid-1', 'name': '2.0.0', 'code': '42'},
      };

      final install = AppInstall.fromNestedJson(json);
      expect(install.id, 'ai-uuid-1');
      expect(install.createdAt, '2026-01-01T00:00:00Z');
      expect(install.updatedAt, '2026-01-02T00:00:00Z');
      expect(install.appVersion, isNotNull);
      expect(install.appVersion!.id, 'av-uuid-1');
      expect(install.appVersion!.name, '2.0.0');
    });

    test('fromNestedJson handles null app_version', () {
      final json = {
        'id': 'ai-uuid-2',
        'created_at': null,
        'updated_at': null,
        'app_version': null,
      };

      final install = AppInstall.fromNestedJson(json);
      expect(install.id, 'ai-uuid-2');
      expect(install.appVersion, isNull);
    });
  });
}
