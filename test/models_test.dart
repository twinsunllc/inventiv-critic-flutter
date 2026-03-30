import 'package:flutter_test/flutter_test.dart';
import 'package:inventiv_critic_flutter/model/ping_response.dart';
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:inventiv_critic_flutter/model/app.dart';
import 'package:inventiv_critic_flutter/model/device.dart';

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

    test(
      'fromJson uses empty string when package is null (v3 ping response)',
      () {
        final json = {
          'name': 'MyApp',
          'package': null,
          'platform': 'Android',
          'version': {'code': '5', 'name': '1.0.0'},
        };

        final app = App.fromJson(json);
        expect(app.package, '');
      },
    );

    test(
      'fromJson uses empty _Version when version is null (v3 ping response)',
      () {
        final json = {
          'name': 'MyApp',
          'package': 'com.example.myapp',
          'platform': 'Android',
          'version': null,
        };

        final app = App.fromJson(json);
        expect(app.version.code, '');
        expect(app.version.name, '');
      },
    );

    test('fromJson handles both package and version null without crashing', () {
      final json = {
        'name': 'MyApp',
        'package': null,
        'platform': 'Android',
        'version': null,
      };

      final app = App.fromJson(json);
      expect(app.package, '');
      expect(app.version.code, '');
      expect(app.version.name, '');
    });
  });
}
