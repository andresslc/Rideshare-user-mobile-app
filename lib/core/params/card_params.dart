class AddCardParams {
  final String paymentMethodId;

  AddCardParams({required this.paymentMethodId});

  Map<String, dynamic> toMap() {
    return {'pmId': paymentMethodId};
  }
}

class TransactionParams {
  final String? type;
  final int page;

  const TransactionParams({this.type, required this.page});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (type != null && type!.isNotEmpty) {
      data['type'] = type;
    }
    data['page'] = page;
    return data;
  }
}

class AddFundParams {
  final double amount;
  final String paymentMethodId;

  AddFundParams({required this.amount, required this.paymentMethodId});

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'paymentMethodId': paymentMethodId};
  }
}
