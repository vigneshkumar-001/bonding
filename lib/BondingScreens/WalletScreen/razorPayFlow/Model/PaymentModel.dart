class PlaceOrderResponse {
  final bool status;
  final String message;
  final PlaceOrderData? data;

  PlaceOrderResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PlaceOrderResponse.fromJson(Map<String, dynamic> json) {
    return PlaceOrderResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? PlaceOrderData.fromJson(json['data']) : null,
    );
  }
}

class PlaceOrderData {
  final String userId;
  final String userName;
  final String userPhone;
  final String razorpayOrderId;
  final int totalAmount;
  final String currency;
  final String paymentStatus;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  PlaceOrderData({
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.razorpayOrderId,
    required this.totalAmount,
    required this.currency,
    required this.paymentStatus,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory PlaceOrderData.fromJson(Map<String, dynamic> json) {
    return PlaceOrderData(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      totalAmount: json['totalAmount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      paymentStatus: json['paymentStatus'] as String? ?? 'created',
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: json['__v'] as int? ?? 0,
    );
  }
}