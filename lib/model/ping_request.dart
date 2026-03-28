import 'package:inventiv_critic_flutter/model/app.dart';
import 'package:inventiv_critic_flutter/model/device.dart';

class PingRequest {
  String apiToken;
  App app;
  Device device;

  PingRequest({
    required this.apiToken,
    required this.app,
    required this.device,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'api_token': apiToken,
    'app': app.toJson(),
    'device': device.toJson(),
  };
}
