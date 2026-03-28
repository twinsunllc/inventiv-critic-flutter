import 'package:inventiv_critic_flutter/model/bug_report.dart';
import 'package:inventiv_critic_flutter/model/ping_response.dart';

class BugReportRequest {
  String apiToken;
  BugReport report;
  AppInstall appInstall;

  BugReportRequest({
    required this.appInstall,
    required this.apiToken,
    required this.report,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'api_token': apiToken,
    'bug_report': report,
    'app_install': appInstall,
  };
}
