// staff_chat_repository.dart
import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';

class StaffChatRepository {
  final NetworkApiService _apiService;
  StaffChatRepository(this._apiService);

  /// GET: /api/v1/staff/chat/list?page=1&limit=12
  /// (CHANGE endpoint if your backend is different)
  Future<Map<String, dynamic>> getStaffChatList({
    required int page,
    required int limit,
  }) async {
    final url =
        "staff/chat/list?page=$page&limit=$limit";
    final response = await _apiService.getResponseV2(url);
    return Map<String, dynamic>.from(response);
  }
}
