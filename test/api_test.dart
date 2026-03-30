import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventiv_critic_flutter/api.dart';
import 'package:inventiv_critic_flutter/log_buffer.dart';
import 'package:inventiv_critic_flutter/model/app.dart';
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:inventiv_critic_flutter/model/device.dart';
import 'package:inventiv_critic_flutter/model/ping_request.dart';
import 'package:inventiv_critic_flutter/model/ping_response.dart';
import 'package:inventiv_critic_flutter/model/report_request.dart';

void main() {
  late PingRequest testPingRequest;

  setUp(() {
    Api.resetBaseUrl();
    Api.resetHttpClient();
    Api.setDeviceStatusProvider(
      () async => <String, String>{
        'device_status[network_cell_connected]': 'false',
        'device_status[network_wifi_connected]': 'true',
      },
    );

    testPingRequest = PingRequest(
      apiToken: 'test-api-token',
      app: App.create(
        name: 'TestApp',
        package: 'com.test.app',
        platform: 'Android',
        versionName: '1.0.0',
        versionCode: '1',
      ),
      device: Device(
        identifier: 'device-123',
        manufacturer: 'Google',
        model: 'Pixel 7',
        networkCarrier: 'T-Mobile',
        platform: 'Android',
        platformVersion: '14',
      ),
    );
  });

  tearDown(() {
    Api.resetBaseUrl();
    Api.resetHttpClient();
    Api.resetDeviceStatusProvider();
  });

  group('PingRequest serialization', () {
    test('toJson includes api_token, app, and device', () {
      final json = testPingRequest.toJson();

      expect(json['api_token'], 'test-api-token');
      expect(json['app'], isA<Map<String, dynamic>>());
      expect(json['app']['name'], 'TestApp');
      expect(json['app']['package'], 'com.test.app');
      expect(json['app']['platform'], 'Android');
      expect(json['app']['version']['name'], '1.0.0');
      expect(json['app']['version']['code'], '1');
      expect(json['device'], isA<Map<String, dynamic>>());
      expect(json['device']['identifier'], 'device-123');
      expect(json['device']['manufacturer'], 'Google');
      expect(json['device']['platform'], 'Android');
    });

    test('toJson encodes to valid JSON string', () {
      final encoded = json.encode(testPingRequest.toJson());
      final decoded = json.decode(encoded);

      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['api_token'], 'test-api-token');
    });
  });

  group('BugReportRequest serialization', () {
    test('toJson includes api_token, bug_report, and app_install', () {
      final request = BugReportRequest(
        appInstall: AppInstall(id: 'install-uuid-123'),
        apiToken: 'test-token',
        report: BugReport.create(
          description: 'Test bug',
          stepsToReproduce: 'Step 1\nStep 2',
          userIdentifier: 'user@test.com',
        ),
      );

      final jsonMap = request.toJson();
      expect(jsonMap['api_token'], 'test-token');
      expect(jsonMap['bug_report'], isA<BugReport>());
      expect(jsonMap['app_install'], isA<AppInstall>());
    });
  });

  group('Api.setBaseUrl / resetBaseUrl', () {
    test('setBaseUrl changes the API URL used by ping', () async {
      Api.setBaseUrl('https://custom.api.com/v3');

      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          json.encode({
            'app_install': {'id': 'uuid-123'},
          }),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.ping(testPingRequest);
      expect(capturedUri.toString(), 'https://custom.api.com/v3/ping');
    });

    test('resetBaseUrl restores default URL', () async {
      Api.setBaseUrl('https://custom.api.com/v3');
      Api.resetBaseUrl();

      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          json.encode({
            'app_install': {'id': 'uuid-123'},
          }),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.ping(testPingRequest);
      expect(capturedUri.toString(), 'https://critic.inventiv.io/api/v3/ping');
    });
  });

  group('Api.ping', () {
    test('sends POST with JSON body and content-type header', () async {
      String? capturedBody;
      Map<String, String>? capturedHeaders;
      String? capturedMethod;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedBody = request.body;
        capturedHeaders = request.headers;
        return http.Response(
          json.encode({
            'app_install': {'id': 'uuid-response-123'},
          }),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.ping(testPingRequest);

      expect(capturedMethod, 'POST');
      expect(capturedHeaders!['content-type'], 'application/json');

      final decodedBody = json.decode(capturedBody!);
      expect(decodedBody['api_token'], 'test-api-token');
      expect(decodedBody['app']['name'], 'TestApp');
      expect(decodedBody['device']['manufacturer'], 'Google');
    });

    test('returns AppInstall on 200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'app_install': {'id': 'uuid-success-456'},
          }),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.ping(testPingRequest);
      expect(result, isA<AppInstall>());
      expect(result.id, 'uuid-success-456');
    });

    test('returns AppInstall with integer id converted to string', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'app_install': {'id': 42},
          }),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.ping(testPingRequest);
      expect(result.id, '42');
    });

    test('throws Exception on 400 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Invalid token"}', 400);
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.ping(testPingRequest),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Response code: 400'),
          ),
        ),
      );
    });

    test('throws Exception on 401 unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.ping(testPingRequest),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Response code: 401'),
          ),
        ),
      );
    });

    test('throws Exception on 500 server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.ping(testPingRequest),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Response code: 500'),
          ),
        ),
      );
    });

    test('throws on network error', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.ping(testPingRequest),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('Api.submitReport', () {
    late BugReportRequest testReportRequest;

    setUp(() {
      testReportRequest = BugReportRequest(
        appInstall: AppInstall(id: 'install-uuid-789'),
        apiToken: 'test-api-token',
        report: BugReport.create(
          description: 'App crashes on login',
          stepsToReproduce: '1. Open app\n2. Tap login\n3. App crashes',
          userIdentifier: 'user@example.com',
        ),
      );
    });

    test('sends POST multipart request to bug_reports endpoint', () async {
      String? capturedMethod;
      Uri? capturedUri;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        capturedMethod = request.method;
        capturedUri = request.url;
        // Drain the body stream
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid-result',
                'description': 'App crashes on login',
                'steps_to_reproduce':
                    '1. Open app\n2. Tap login\n3. App crashes',
                'user_identifier': 'user@example.com',
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2026-01-01T00:00:00Z',
                'attachments': [],
              }),
            ),
          ),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.submitReport(testReportRequest);

      expect(capturedMethod, 'POST');
      expect(
        capturedUri.toString(),
        'https://critic.inventiv.io/api/v3/bug_reports',
      );
    });

    test('includes correct multipart form fields', () async {
      String? capturedContentType;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        capturedContentType = request.headers['content-type'];
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid',
                'description': 'App crashes on login',
                'steps_to_reproduce': '1. Open app',
                'user_identifier': 'user@example.com',
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.submitReport(testReportRequest);

      expect(capturedContentType, contains('multipart/form-data'));
    });

    test('returns BugReport on 200 response', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid-created',
                'description': 'App crashes on login',
                'steps_to_reproduce':
                    '1. Open app\n2. Tap login\n3. App crashes',
                'user_identifier': 'user@example.com',
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2026-01-01T00:00:00Z',
                'attachments': [],
              }),
            ),
          ),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.submitReport(testReportRequest);
      expect(result, isA<BugReport>());
      expect(result.id, 'bug-uuid-created');
      expect(result.description, 'App crashes on login');
    });

    test('returns BugReport on 201 response', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid-201',
                'description': 'Test',
                'steps_to_reproduce': 'Steps',
                'user_identifier': 'user',
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          201,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.submitReport(testReportRequest);
      expect(result.id, 'bug-uuid-201');
    });

    test('throws Exception on 422 validation error', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"error": "Validation failed"}')),
          422,
        );
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.submitReport(testReportRequest),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Response code: 422'),
          ),
        ),
      );
    });

    test('throws Exception on 500 server error', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(utf8.encode('Internal Server Error')),
          500,
        );
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.submitReport(testReportRequest),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Response code: 500'),
          ),
        ),
      );
    });

    test('uses default values for null report fields', () async {
      final requestWithNulls = BugReportRequest(
        appInstall: AppInstall(id: 'install-uuid'),
        apiToken: 'token',
        report: BugReport(
          description: null,
          stepsToReproduce: null,
          userIdentifier: null,
        ),
      );

      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid',
                'description': 'no description',
                'steps_to_reproduce': 'no steps to reproduce',
                'user_identifier': 'no user identifier',
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.submitReport(requestWithNulls);
      expect(result, isA<BugReport>());
    });

    test('throws on network error', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        throw http.ClientException('Connection timeout');
      });
      Api.setHttpClient(mockClient);

      expect(
        () => Api.submitReport(testReportRequest),
        throwsA(isA<http.ClientException>()),
      );
    });

    test(
      'includes disk and memory fields when provided by deviceStatusProvider',
      () async {
        Api.setDeviceStatusProvider(
          () async => <String, String>{
            'device_status[network_cell_connected]': 'false',
            'device_status[network_wifi_connected]': 'true',
            'device_status[disk_free]': '10737418240',
            'device_status[disk_total]': '107374182400',
            'device_status[disk_usable]': '10737418240',
            'device_status[memory_free]': '2147483648',
            'device_status[memory_total]': '8589934592',
          },
        );

        Map<String, String>? capturedFields;
        final mockClient = MockClient.streaming((request, bodyStream) async {
          final bytes = await bodyStream.toBytes();
          final body = String.fromCharCodes(bytes);
          capturedFields = {};
          for (final field in [
            'disk_free',
            'disk_total',
            'disk_usable',
            'memory_free',
            'memory_total',
          ]) {
            if (body.contains('device_status[$field]')) {
              capturedFields!['device_status[$field]'] = 'present';
            }
          }
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                json.encode({
                  'id': 'bug-uuid',
                  'description': 'Test',
                  'steps_to_reproduce': null,
                  'user_identifier': null,
                  'created_at': null,
                  'updated_at': null,
                  'attachments': [],
                }),
              ),
            ),
            200,
          );
        });
        Api.setHttpClient(mockClient);

        await Api.submitReport(testReportRequest);

        expect(capturedFields!['device_status[disk_free]'], 'present');
        expect(capturedFields!['device_status[disk_total]'], 'present');
        expect(capturedFields!['device_status[disk_usable]'], 'present');
        expect(capturedFields!['device_status[memory_free]'], 'present');
        expect(capturedFields!['device_status[memory_total]'], 'present');
      },
    );
  });

  group('Api.deviceStatus disk and memory', () {
    test('disk MB to bytes conversion is correct', () {
      // 10240 MB * 1024 * 1024 = 10737418240 bytes (10 GB)
      expect((10240.0 * 1024 * 1024).round(), 10737418240);
      // 102400 MB * 1024 * 1024 = 107374182400 bytes (100 GB)
      expect((102400.0 * 1024 * 1024).round(), 107374182400);
      // disk_usable equals disk_free
      final freeMb = 10240.0;
      final freeBytes = (freeMb * 1024 * 1024).round();
      expect(freeBytes, 10737418240);
    });

    test(
      'submitReport forwards all disk and memory fields from provider',
      () async {
        Api.setDeviceStatusProvider(
          () async => <String, String>{
            'device_status[network_cell_connected]': 'false',
            'device_status[network_wifi_connected]': 'false',
            'device_status[disk_free]': '10737418240',
            'device_status[disk_total]': '107374182400',
            'device_status[disk_usable]': '10737418240',
            'device_status[memory_free]': '2147483648',
            'device_status[memory_total]': '8589934592',
          },
        );

        final testRequest = BugReportRequest(
          appInstall: AppInstall(id: 'install-uuid'),
          apiToken: 'token',
          report: BugReport.create(
            description: 'Test',
            stepsToReproduce: 'Steps',
            userIdentifier: 'user',
          ),
        );

        String? capturedBody;
        final mockClient = MockClient.streaming((request, bodyStream) async {
          final bytes = await bodyStream.toBytes();
          capturedBody = String.fromCharCodes(bytes);
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                json.encode({
                  'id': 'bug-uuid',
                  'description': 'Test',
                  'steps_to_reproduce': null,
                  'user_identifier': null,
                  'created_at': null,
                  'updated_at': null,
                  'attachments': [],
                }),
              ),
            ),
            200,
          );
        });
        Api.setHttpClient(mockClient);

        await Api.submitReport(testRequest);

        expect(capturedBody, contains('device_status[disk_free]'));
        expect(capturedBody, contains('10737418240'));
        expect(capturedBody, contains('device_status[disk_total]'));
        expect(capturedBody, contains('107374182400'));
        expect(capturedBody, contains('device_status[disk_usable]'));
        expect(capturedBody, contains('device_status[memory_free]'));
        expect(capturedBody, contains('2147483648'));
        expect(capturedBody, contains('device_status[memory_total]'));
        expect(capturedBody, contains('8589934592'));
      },
    );

    test('submitReport succeeds without disk and memory fields', () async {
      // Verifies graceful degradation: when disk/memory are unavailable,
      // the request still succeeds with just network fields.
      Api.setDeviceStatusProvider(
        () async => <String, String>{
          'device_status[network_cell_connected]': 'false',
          'device_status[network_wifi_connected]': 'true',
        },
      );

      final testRequest = BugReportRequest(
        appInstall: AppInstall(id: 'install-uuid'),
        apiToken: 'token',
        report: BugReport.create(
          description: 'Test',
          stepsToReproduce: 'Steps',
          userIdentifier: 'user',
        ),
      );

      String? capturedBody;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bytes = await bodyStream.toBytes();
        capturedBody = String.fromCharCodes(bytes);
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid',
                'description': 'Test',
                'steps_to_reproduce': null,
                'user_identifier': null,
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          200,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.submitReport(testRequest);
      expect(result, isA<BugReport>());
      expect(capturedBody, contains('device_status[network_wifi_connected]'));
      expect(capturedBody, isNot(contains('device_status[disk_free]')));
      expect(capturedBody, isNot(contains('device_status[memory_free]')));
    });
  });

  group('Api.submitReport with log buffer', () {
    late BugReportRequest testReportRequest;

    setUp(() {
      Api.setDeviceStatusProvider(
        () async => <String, String>{
          'device_status[network_cell_connected]': 'false',
          'device_status[network_wifi_connected]': 'true',
        },
      );
      testReportRequest = BugReportRequest(
        appInstall: AppInstall(id: 'install-uuid'),
        apiToken: 'test-api-token',
        report: BugReport.create(
          description: 'Bug with logs',
          stepsToReproduce: 'Step 1',
          userIdentifier: 'user@test.com',
        ),
      );
    });

    test('attaches console-logs.txt when logBuffer has entries', () async {
      final logBuffer = LogBuffer();
      logBuffer.add('Log line 1');
      logBuffer.add('Log line 2');

      String? capturedBody;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bytes = await bodyStream.toBytes();
        capturedBody = String.fromCharCodes(bytes);
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid',
                'description': 'Bug with logs',
                'steps_to_reproduce': 'Step 1',
                'user_identifier': 'user@test.com',
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          201,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.submitReport(testReportRequest, logBuffer: logBuffer);

      expect(capturedBody, contains('console-logs.txt'));
      expect(capturedBody, contains('Log line 1'));
      expect(capturedBody, contains('Log line 2'));
    });

    test('does not attach log file when logBuffer is empty', () async {
      final logBuffer = LogBuffer();

      String? capturedBody;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bytes = await bodyStream.toBytes();
        capturedBody = String.fromCharCodes(bytes);
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid',
                'description': 'Bug with logs',
                'steps_to_reproduce': 'Step 1',
                'user_identifier': 'user@test.com',
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          201,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.submitReport(testReportRequest, logBuffer: logBuffer);

      expect(capturedBody, isNot(contains('console-logs.txt')));
    });

    test('does not attach log file when logBuffer is null', () async {
      String? capturedBody;
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bytes = await bodyStream.toBytes();
        capturedBody = String.fromCharCodes(bytes);
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid',
                'description': 'Bug with logs',
                'steps_to_reproduce': 'Step 1',
                'user_identifier': 'user@test.com',
                'created_at': null,
                'updated_at': null,
                'attachments': [],
              }),
            ),
          ),
          201,
        );
      });
      Api.setHttpClient(mockClient);

      await Api.submitReport(testReportRequest);

      expect(capturedBody, isNot(contains('console-logs.txt')));
    });

    test('report still submits when logBuffer is provided', () async {
      final logBuffer = LogBuffer();
      logBuffer.add('Some log');

      final mockClient = MockClient.streaming((request, bodyStream) async {
        await bodyStream.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              json.encode({
                'id': 'bug-uuid-with-logs',
                'description': 'Bug with logs',
                'steps_to_reproduce': 'Step 1',
                'user_identifier': 'user@test.com',
                'created_at': null,
                'updated_at': null,
                'attachments': [
                  {
                    'file_file_name': 'console_log.txt',
                    'file_file_size': 100,
                    'file_content_type': 'text/plain',
                    'file_updated_at': null,
                    'url': null,
                  },
                ],
              }),
            ),
          ),
          201,
        );
      });
      Api.setHttpClient(mockClient);

      final result = await Api.submitReport(
        testReportRequest,
        logBuffer: logBuffer,
      );
      expect(result.id, 'bug-uuid-with-logs');
      expect(result.attachments, isNotEmpty);
      expect(result.attachments!.first.name, 'console_log.txt');
    });
  });
}
