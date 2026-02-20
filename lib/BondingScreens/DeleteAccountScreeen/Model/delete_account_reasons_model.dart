// lib/BondingScreens/DeleteAccount/Model/delete_account_reasons_model.dart

class DeleteAccountReasonsResponse {
  final bool status;
  final String message;
  final List<DeleteReasonOption> data;

  DeleteAccountReasonsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory DeleteAccountReasonsResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAccountReasonsResponse(
      status: json["status"] == true,
      message: (json["message"] ?? "").toString(),
      data: (json["data"] as List? ?? [])
          .map((e) => DeleteReasonOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DeleteReasonOption {
  final String code;
  final String label;

  DeleteReasonOption({
    required this.code,
    required this.label,
  });

  factory DeleteReasonOption.fromJson(Map<String, dynamic> json) {
    return DeleteReasonOption(
      code: (json["code"] ?? "").toString(),
      label: (json["label"] ?? "").toString(),
    );
  }
}
