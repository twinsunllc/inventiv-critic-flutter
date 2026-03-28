import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:http/http.dart' as http;
import 'package:inventiv_critic_flutter/log_buffer.dart';
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:inventiv_critic_flutter/model/ping_request.dart';
import 'package:inventiv_critic_flutter/model/ping_response.dart';
import 'package:inventiv_critic_flutter/model/report_request.dart';
import 'package:system_info/system_info.dart';

const String _defaultApiUrl = 'https://critic.inventiv.io/api/v3';

typedef DeviceStatusProvider = Future<Map<String, String>> Function();

class Api {
  static String _apiUrl = _defaultApiUrl;
  static http.Client? _httpClient;
  static DeviceStatusProvider? _deviceStatusProvider;

  static void setBaseUrl(String url) {
    _apiUrl = url;
  }

  static void resetBaseUrl() {
    _apiUrl = _defaultApiUrl;
  }

  /// Sets a custom HTTP client (useful for testing).
  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  /// Resets the HTTP client to the default.
  static void resetHttpClient() {
    _httpClient = null;
  }

  /// Sets a custom device status provider (useful for testing).
  static void setDeviceStatusProvider(DeviceStatusProvider provider) {
    _deviceStatusProvider = provider;
  }

  /// Resets the device status provider to the default.
  static void resetDeviceStatusProvider() {
    _deviceStatusProvider = null;
  }

  static http.Client get _client => _httpClient ?? http.Client();

  static Future<AppInstall> ping(PingRequest pingRequest) async {
    final response = await _client.post(
      Uri.parse('$_apiUrl/ping'),
      body: json.encode(pingRequest.toJson()),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );

    if (response.statusCode == 200) {
      return AppInstall.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Response code: ${response.statusCode}, ${response.body}',
      );
    }
  }

  static Future<Map<String, String>> deviceStatus() async {
    final connectivityResults = await Connectivity().checkConnectivity();

    var battery = Battery();

    var returnVal = <String, String>{
      'device_status[network_cell_connected]':
          connectivityResults.contains(ConnectivityResult.mobile).toString(),
      'device_status[network_wifi_connected]':
          connectivityResults.contains(ConnectivityResult.wifi).toString(),
    };

    try {
      returnVal.addAll(<String, String>{
        'device_status[battery_charging]':
            ((await battery.onBatteryStateChanged.first) !=
                    BatteryState.discharging)
                .toString(),
        'device_status[battery_level]': (await battery.batteryLevel).toString(),
      });
    } catch (err) {
      print(err);
    }

    try {
      final diskSpacePlus = DiskSpacePlus();
      final freeMb = await diskSpacePlus.getFreeDiskSpace;
      final totalMb = await diskSpacePlus.getTotalDiskSpace;
      if (freeMb != null) {
        final freeBytes = (freeMb * 1024 * 1024).round();
        returnVal['device_status[disk_free]'] = freeBytes.toString();
        returnVal['device_status[disk_usable]'] = freeBytes.toString();
      }
      if (totalMb != null) {
        returnVal['device_status[disk_total]'] =
            (totalMb * 1024 * 1024).round().toString();
      }
    } catch (err) {
      print(err);
    }

    try {
      returnVal['device_status[memory_free]'] =
          SysInfo.getFreePhysicalMemory().toString();
      returnVal['device_status[memory_total]'] =
          SysInfo.getTotalPhysicalMemory().toString();
    } catch (err) {
      print(err);
    }

    return returnVal;
  }

  static Future<BugReport> submitReport(
    BugReportRequest submitReportRequest, {
    LogBuffer? logBuffer,
  }) async {
    final uri = Uri.parse('$_apiUrl/bug_reports');
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['api_token'] = submitReportRequest.apiToken
          ..fields['app_install[id]'] =
              submitReportRequest.appInstall.id.toString()
          ..fields['bug_report[description]'] =
              submitReportRequest.report.description ?? 'no description'
          ..fields['bug_report[steps_to_reproduce]'] =
              submitReportRequest.report.stepsToReproduce ??
              'no steps to reproduce'
          ..fields['bug_report[user_identifier]'] =
              submitReportRequest.report.userIdentifier ?? 'no user identifier'
          ..fields.addAll(await (_deviceStatusProvider ?? Api.deviceStatus)());

    if (submitReportRequest.report.attachments?.isNotEmpty ?? false) {
      await Future.wait(
        submitReportRequest.report.attachments!.map((attachment) async {
          if (attachment.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'bug_report[attachments][]',
                attachment.path!,
                filename: attachment.name,
              ),
            );
          }
        }),
      );
    }

    // Attach captured logs as a text file, if available.
    if (logBuffer != null && !logBuffer.isEmpty) {
      try {
        final logContent = logBuffer.export();
        request.files.add(
          http.MultipartFile.fromString(
            'bug_report[attachments][]',
            logContent,
            filename: 'console_log.txt',
          ),
        );
      } catch (_) {
        // Graceful failure — if log capture fails, the report still submits.
      }
    }

    final streamedResponse = await _client.send(request);
    print('Response: ${streamedResponse.statusCode}');
    final body = await streamedResponse.stream.bytesToString();
    print(body);

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      return BugReport.fromJson(json.decode(body));
    } else {
      throw Exception('Response code: ${streamedResponse.statusCode}, $body');
    }
  }
}
