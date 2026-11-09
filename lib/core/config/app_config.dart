enum Flavor { dev, staging, prod }

class AppConfig {
  final String appName;
  final String baseUrl;
  final Flavor flavor;

  const AppConfig({
    required this.appName,
    required this.baseUrl,
    required this.flavor,
  });

  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;
  bool get isProd => flavor == Flavor.prod;

  bool get isDevOrStaging => isDev || isStaging;
}
