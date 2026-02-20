// lib/BondingScreens/DeleteAccountScreeen/ViewModel/delete_account_model.dart

class DeleteAccountResponse {
  final bool status;
  final String message;

  // user api returns: deletedReasonCodes: []
  final List<String> deletedReasonCodes;

  // staff api returns: deletedReason (string) maybe
  final String deletedReason;

  DeleteAccountResponse({
    required this.status,
    required this.message,
    required this.deletedReasonCodes,
    required this.deletedReason,
  });

  factory DeleteAccountResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponse(
      status: json["status"] == true,
      message: (json["message"] ?? "").toString(),
      deletedReasonCodes: (json["deletedReasonCodes"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      deletedReason: (json["deletedReason"] ?? "").toString(),
    );
  }
}
