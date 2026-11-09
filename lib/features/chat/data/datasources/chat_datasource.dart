import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';

abstract class ChatDatasource {
  Future<Either<Failure, List<ChatMessageModel>>> getHistory({
    required String rideId,
    required int page,
    required int limit,
  });

  Future<Either<Failure, ChatMessageModel?>> sendMessage({
    required String receiverId,
    required String message,
    required String contextId,
    String contextType = 'Ride',
  });
}

class ChatDatasourceImpl implements ChatDatasource {
  final ApiService _api = locator<ApiService>();

  @override
  Future<Either<Failure, List<ChatMessageModel>>> getHistory({
    required String rideId,
    required int page,
    required int limit,
  }) async {
    return handleNetworkError(() async {
      final res = await _api.get(
        ApiEndpoints.chatHistory(rideId),
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return <ChatMessageModel>[];
      final list = data['data'];
      if (list is! List) return <ChatMessageModel>[];
      return list
          .map((e) => ChatMessageModel.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();
    });
  }

  @override
  Future<Either<Failure, ChatMessageModel?>> sendMessage({
    required String receiverId,
    required String message,
    required String contextId,
    String contextType = 'Ride',
  }) async {
    return handleNetworkError(() async {
      final res = await _api.post(
        ApiEndpoints.chatSend,
        data: {
          'receiverId': receiverId,
          'message': message,
          'contextId': contextId,
          'contextType': contextType,
        },
      );
      final data = res.data;
      if (data is! Map) return null;
      final msg = (data)['data'];
      if (msg is Map) {
        return ChatMessageModel.fromJson(
            Map<String, dynamic>.from(Map<dynamic, dynamic>.from(msg)));
      }
      return null;
    });
  }
}

