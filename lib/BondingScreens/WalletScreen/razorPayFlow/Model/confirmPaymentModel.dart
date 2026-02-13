class ConfirmPurchaseResponse {
  final bool status;
  final String message;
  final ConfirmPurchaseData? data;

  ConfirmPurchaseResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ConfirmPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmPurchaseResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? ConfirmPurchaseData.fromJson(json['data']) : null,
    );
  }
}

class ConfirmPurchaseData {
  final String userId;
  final String orderId;
  final String paymentId;
  final String signature;
  final int creditedCoins;
  final int newCoinBalance;
  final String status;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  ConfirmPurchaseData({
    required this.userId,
    required this.orderId,
    required this.paymentId,
    required this.signature,
    required this.creditedCoins,
    required this.newCoinBalance,
    required this.status,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory ConfirmPurchaseData.fromJson(Map<String, dynamic> json) {
    return ConfirmPurchaseData(
      userId: json['userId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      paymentId: json['paymentId'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      creditedCoins: json['creditedCoins'] as int? ?? 0,
      newCoinBalance: json['newCoinBalance'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: json['__v'] as int? ?? 0,
    );
  }
}