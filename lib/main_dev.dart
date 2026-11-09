import 'package:ride_app/core/constants/constants_data.dart';

import 'core/config/app_config.dart';
import 'main_common.dart';

void main() => mainCommon(
  config: AppConfig(
    appName: 'Ride App Dev',
    baseUrl: remoteConfigModel.baseUrlDev,
    flavor: Flavor.dev,
  ),
);
  