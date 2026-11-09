/// App environment configuration.
///
/// Switch environments by changing the static [current] field,
/// or use `--dart-define=ENV=staging` and read from `String.fromEnvironment`.
enum Env {
  dev(baseUrl: 'https://dev-api.example.com/api/v1', name: 'Development'),
  staging(baseUrl: 'https://staging-api.example.com/api/v1', name: 'Staging'),
  prod(baseUrl: 'https://api.example.com/api/v1', name: 'Production');

  const Env({required this.baseUrl, required this.name});

  final String baseUrl;
  final String name;

  /// Change this to switch environments.
  /// Or read from `const String.fromEnvironment('ENV')`.
  static Env current = _fromString(
    const String.fromEnvironment('ENV', defaultValue: 'dev'),
  );

  static Env _fromString(String value) => switch (value) {
    'prod' || 'production' => Env.prod,
    'staging' => Env.staging,
    _ => Env.dev,
  };

  bool get isDev => this == Env.dev;
  bool get isStaging => this == Env.staging;
  bool get isProd => this == Env.prod;
}
