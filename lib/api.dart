import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:inventiv_critic_flutter/model/ping_request.dart';
import 'package:inventiv_critic_flutter/model/ping_response.dart';
import 'package:inventiv_critic_flutter/model/report_request.dart';

const String _defaultApiUrl = 'https://critic.inventiv.io/api/v3';

class Api {
  static String _apiUrl = _defaultApiUrl;

  static void setBaseUrl(String url) {
    _apiUrl = url;
  }

  static void resetBaseUrl() {
    _apiUrl = _defaultApiUrl;
  }

  static Future<AppInstall> ping(PingRequest pingRequest) async {
    final response = await http.post(
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

    return returnVal;
  }

  static Future<BugReport> submitReport(
    BugReportRequest submitReportRequest,
  ) async {
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
          ..fields.addAll(await Api.deviceStatus());

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

    final response = await request.send();
    print('Response: ${response.statusCode}');
    final body = await response.stream.bytesToString();
    print(body);
    return BugReport.fromJson(json.decode(body));
  }
}
