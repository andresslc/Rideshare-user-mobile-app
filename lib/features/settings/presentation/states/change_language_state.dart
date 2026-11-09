sealed class ChangeLanguageState {
  const ChangeLanguageState();
}

class ChangeLanguageInitial extends ChangeLanguageState {
  const ChangeLanguageInitial();
}

class ChangeLanguageLoading extends ChangeLanguageState {
  const ChangeLanguageLoading();
}

class ChangeLanguageError extends ChangeLanguageState {
  final String message;
  const ChangeLanguageError(this.message);
}

class LanguageChanged extends ChangeLanguageState {
  final String message;
  const LanguageChanged(this.message);
}