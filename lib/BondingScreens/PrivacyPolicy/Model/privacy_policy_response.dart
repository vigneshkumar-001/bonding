class PrivacyPolicyResponse {
  final bool status;
  final String? message;
  final PrivacyPolicyData? data;

  PrivacyPolicyResponse({required this.status, this.message, this.data});

  factory PrivacyPolicyResponse.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyResponse(
      status: json["status"] == true,
      message: json["message"],
      data: json["data"] == null ? null : PrivacyPolicyData.fromJson(json["data"]),
    );
  }
}

class PrivacyPolicyData {
  final String? id;
  final String? title;
  final String? content;

  PrivacyPolicyData({this.id, this.title, this.content});

  factory PrivacyPolicyData.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyData(
      id: json["_id"],
      title: json["title"],
      content: json["content"],
    );
  }
}
