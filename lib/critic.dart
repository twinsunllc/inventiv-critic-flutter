import 'dart:async';
import 'dart:io';

import 'package:inventiv_critic_flutter/api.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:inventiv_critic_flutter/log_buffer.dart';
import 'package:inventiv_critic_flutter/log_capture.dart';
import 'package:inventiv_critic_flutter/model/app.dart';
import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:inventiv_critic_flutter/model/device.dart';
import 'package:inventiv_critic_flutter/model/ping_request.dart';
import 'package:inventiv_critic_flutter/model/ping_response.dart';
import 'package:inventiv_critic_flutter/model/report_request.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Critic {
  //singleton set-up
  static final Critic _singleton = Critic._internal();
  Critic._internal();

  factory Critic() {
    return _singleton;
  }

  String? _apiToken;
  String? _appId;

  /// Log capture instance. Access the underlying [LogBuffer] via
  /// `Critic().logCapture.buffer` if you need to add custom entries.
  final LogCapture logCapture = LogCapture();

  Future<App> _createAppData() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return App.create(
      name: (info.appName.isEmpty) ? 'Unavailable' : info.appName,
      package: info.packageName,
      platform: Platform.isAndroid ? 'Android' : 'iOS',
      versionName: info.version,
      versionCode: info.buildNumber,
    );
  }

  Future<Device> _createDeviceData() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return Device(
        identifier: androidInfo.id,
        manufacturer: androidInfo.manufacturer,
        model: androidInfo.model,
        networkCarrier: 'Not available',
        platform: 'Android',
        platformVersion: androidInfo.version.release,
      );
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return Device(
        identifier: iosInfo.identifierForVendor ?? '',
        manufacturer: 'Apple',
        model: iosInfo.model,
        networkCarrier: 'Not available',
        platform: 'iOS',
        platformVersion: iosInfo.systemVersion,
      );
    }
    return Device(
      identifier: 'unknown',
      manufacturer: 'unknown',
      model: 'unknown',
      networkCarrier: 'Not available',
      platform: 'Unknown',
      platformVersion: Platform.version,
    );
  }

  Future<bool> initialize(String apiToken, {String? baseUrl}) async {
    _apiToken = apiToken;
    if (baseUrl != null) {
      Api.setBaseUrl(baseUrl);
    } else {
      Api.resetBaseUrl();
    }

    // Start log capture so print() and FlutterError output is buffered.
    // The returned Zone must wrap the caller's app for print interception;
    // however initialize() is typically called from within the app already,
    // so we install here to at least capture FlutterError.onError. Callers
    // who want full print() interception should use
    // `Critic().logCapture.runZoned(() => runApp(...))`.
    logCapture.install();

    App appData = await _createAppData();
    Device deviceData = await _createDeviceData();
    AppInstall response = await Api.ping(
      PingRequest(apiToken: _apiToken!, app: appData, device: deviceData),
    ).catchError((Object error) {
      print('Ping to critic failed: $error');
      return Future<AppInstall>.error(false);
    });
    _appId = response.id;
    return true;
  }

  Future<BugReport> submitReport(BugReport report) async {
    assert(
      _apiToken != null,
      'The API Token must be initialized using the initialize(String) call.',
    );
    assert(
      _appId != null,
      'The App ID must be initialized. Make sure to call initialize(String). If you have done this, please check the logs to see why it failed.',
    );
    BugReportRequest requestData = BugReportRequest(
      appInstall: AppInstall(id: _appId!),
      apiToken: _apiToken!,
      report: report,
    );
    return await Api.submitReport(requestData, logBuffer: logCapture.buffer);
  }
}
