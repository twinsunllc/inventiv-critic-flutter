import 'dart:async';
import 'dart:io';

import 'package:inventiv_critic_flutter/api.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:inventiv_critic_flutter/modal/app.dart';
import 'package:inventiv_critic_flutter/modal/bug_report.dart';
import 'package:inventiv_critic_flutter/modal/device.dart';
import 'package:inventiv_critic_flutter/modal/ping_request_modal.dart';
import 'package:inventiv_critic_flutter/modal/ping_response.dart';
import 'package:inventiv_critic_flutter/modal/report_request_modal.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Critic {
  //singleton set-up
  static final Critic _singleton = new Critic._internal();
  Critic._internal();

  factory Critic() {
    return _singleton;
  }

  String? _apiToken;
  String? _appId;

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

    App appData = await _createAppData();
    Device deviceData = await _createDeviceData();
    AppInstall response = await Api.ping(
      PingRequest(apiToken: _apiToken!, app: appData, device: deviceData),
    ).catchError((Object error) {
      print('Ping to critic failed: ' + error.toString());
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
    return await Api.submitReport(requestData);
  }
}
