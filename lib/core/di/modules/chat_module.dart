import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/features/chat/data/datasources/chat_datasource.dart';

void registerChatModule() {
  locator.registerLazySingleton<ChatDatasource>(() => ChatDatasourceImpl());
}
