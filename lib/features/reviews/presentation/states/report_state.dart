sealed class ReportState {
  const ReportState();
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
}

class ReportSuccess extends ReportState {
  final String message;
  const ReportSuccess(this.message);
}
