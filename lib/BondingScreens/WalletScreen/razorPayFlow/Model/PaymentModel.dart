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
      data: json['data'] != null
          ? PlaceOrderData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlaceOrderData {
  final Deposit? deposit;
  final Checkout? checkout;

  PlaceOrderData({this.deposit, this.checkout});

  factory PlaceOrderData.fromJson(Map<String, dynamic> json) {
    return PlaceOrderData(
      deposit: json['deposit'] != null
          ? Deposit.fromJson(json['deposit'] as Map<String, dynamic>)
          : null,
      checkout: json['checkout'] != null
          ? Checkout.fromJson(json['checkout'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Deposit {
  final String userId;
  final String userName;
  final String userPhone;
  final String razorpayOrderId;
  final int totalAmount;
  final int coin;
  final String currency;
  final String paymentStatus;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  Deposit({
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.razorpayOrderId,
    required this.totalAmount,
    required this.coin,
    required this.currency,
    required this.paymentStatus,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      coin: (json['coin'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      paymentStatus: json['paymentStatus'] as String? ?? 'created',
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }
}

class Checkout {
  final String key;
  final String keyId;
  final String orderId;
  final int amount;
  final String currency;
  final String name;
  final Prefill? prefill;

  Checkout({
    required this.key,
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.name,
    this.prefill,
  });

  factory Checkout.fromJson(Map<String, dynamic> json) {
    return Checkout(
      key: json['key'] as String? ?? '',
      keyId: json['keyId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      name: json['name'] as String? ?? '',
      prefill: json['prefill'] != null
          ? Prefill.fromJson(json['prefill'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Prefill {
  final String name;
  final String contact;
  final String email;

  Prefill({
    required this.name,
    required this.contact,
    required this.email,
  });

  factory Prefill.fromJson(Map<String, dynamic> json) {
    return Prefill(
      name: json['name'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

/*
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
}*/
