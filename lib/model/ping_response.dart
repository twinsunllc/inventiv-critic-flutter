class AppInstall {
  String id;

  AppInstall({required this.id});

  factory AppInstall.fromJson(Map<String, dynamic> jsonBody) {
    Map<String, dynamic> json = jsonBody['app_install'];
    return AppInstall(id: json['id'].toString());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id};
}
