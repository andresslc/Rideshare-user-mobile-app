import 'package:ride_app/features/wallet/domain/entities/add_funds_result_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class AddFundsResultModel extends AddFundsResultEntity {
  const AddFundsResultModel({
    required super.message,
    required super.requiresAction,
    super.clientSecret,
  });

  factory AddFundsResultModel.fromApiResponse(ApiResponse apiResponse) {
    final Map<String, dynamic> data = apiResponse.data is Map
        ? Map<String, dynamic>.from(apiResponse.data as Map)
        : <String, dynamic>{};

    final String message =
        (data['message'] ?? apiResponse.message ?? '').toString();
    final bool requiresAction = data['requiresAction'] == true;
    final String? clientSecret = data['clientSecret']?.toString();

    return AddFundsResultModel(
      message: message,
      requiresAction: requiresAction,
      clientSecret: clientSecret,
    );
  }
}
