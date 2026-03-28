import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:inventiv_critic_flutter/modal/bug_report.dart';
import 'package:inventiv_critic_flutter/modal/device.dart';
import 'package:inventiv_critic_flutter/modal/paginated_response.dart';
import 'package:inventiv_critic_flutter/modal/ping_request_modal.dart';
import 'package:inventiv_critic_flutter/modal/ping_response.dart';
import 'package:inventiv_critic_flutter/modal/report_request_modal.dart';

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
    return await http
        .post(
          Uri.parse('$_apiUrl/ping'),
          body: json.encode(pingRequest.toJson()),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        )
        .then((response) {
          if (response.statusCode == 200) {
            return AppInstall.fromJson(json.decode(response.body));
          } else {
            throw Exception(
              'Response code: ' +
                  response.statusCode.toString() +
                  ', ' +
                  response.body,
            );
          }
        });
  }

  static Future<Map<String, String>> deviceStatus() async {
    var connectivity = await Connectivity().checkConnectivity();

    var battery = Battery();

    var returnVal = <String, String>{
      'device_status[network_cell_connected]':
          (connectivity == ConnectivityResult.mobile).toString(),
      'device_status[network_wifi_connected]':
          (connectivity == ConnectivityResult.wifi).toString(),
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

    final Completer<BugReport> completer = Completer<BugReport>();

    request.send().then((response) {
      print('Response: ${response.statusCode}');
      final contents = StringBuffer();
      response.stream
          .transform(utf8.decoder)
          .listen(
            (data) {
              contents.write(data);
            },
            onDone: () {
              print(contents.toString());
              completer.complete(
                BugReport.fromJson(json.decode(contents.toString())),
              );
            },
          );
    });

    return completer.future;
  }

  static Future<PaginatedResponse<BugReport>> listBugReports(
    String appApiToken, {
    bool? archived,
    String? deviceId,
    String? since,
  }) async {
    final queryParams = <String, String>{'app_api_token': appApiToken};
    if (archived == true) queryParams['archived'] = 'true';
    if (deviceId != null) queryParams['device_id'] = deviceId;
    if (since != null) queryParams['since'] = since;

    final uri = Uri.parse(
      '$_apiUrl/bug_reports',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(
        data,
        'bug_reports',
        BugReport.fromJson,
      );
    } else {
      throw Exception(
        'Response code: ${response.statusCode}, ${response.body}',
      );
    }
  }

  static Future<BugReport> getBugReport(String appApiToken, String id) async {
    final uri = Uri.parse(
      '$_apiUrl/bug_reports/${Uri.encodeComponent(id)}',
    ).replace(queryParameters: {'app_api_token': appApiToken});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return BugReport.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Response code: ${response.statusCode}, ${response.body}',
      );
    }
  }

  static Future<PaginatedResponse<Device>> listDevices(
    String appApiToken,
  ) async {
    final uri = Uri.parse(
      '$_apiUrl/devices',
    ).replace(queryParameters: {'app_api_token': appApiToken});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return PaginatedResponse.fromJson(data, 'devices', Device.fromJson);
    } else {
      throw Exception(
        'Response code: ${response.statusCode}, ${response.body}',
      );
    }
  }
}
