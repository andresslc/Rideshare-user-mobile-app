class AddFundsResultEntity {
  final String message;
  final bool requiresAction;
  final String? clientSecret;

  const AddFundsResultEntity({
    required this.message,
    required this.requiresAction,
    this.clientSecret,
  });
}
