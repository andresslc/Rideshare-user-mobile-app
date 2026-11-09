import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/features/notification/data/models/notification_model.dart';

void main() {
  group('NotificationModel.listFromResponse', () {
    test('parses notification array from data', () {
      final notifications = NotificationModel.listFromResponse({
        'success': true,
        'data': [
          {
            '_id': 'notif-1',
            'notificationContent': {
              '_id': 'content-1',
              'title': 'Ride accepted',
              'description': 'Your driver is on the way',
            },
            'user': 'user-1',
            'userType': 'user',
            'isRead': false,
            'createdAt': '2026-06-23T11:43:48.103Z',
          },
        ],
      });

      expect(notifications.single.id, 'notif-1');
      expect(notifications.single.notificationContent.title, 'Ride accepted');
    });

    test('returns empty list when data is an empty array', () {
      final notifications = NotificationModel.listFromResponse({
        'success': true,
        'message': 'Operation Successfully',
        'data': [],
        'pagination': {
          'skip': 0,
          'pagination': {
            'itemsPerPage': 15,
            'currentPage': 1,
            'totalItems': 0,
            'totalPages': 0,
          },
        },
      });

      expect(notifications, isEmpty);
    });
  });

  group('NotificationModel.toEntity', () {
    test('maps nested content to entity', () {
      final model = NotificationModel(
        id: 'notif-1',
        notificationContent: NotificationContentModel(
          id: 'content-1',
          title: 'Hello',
          description: 'World',
        ),
        user: 'user-1',
        userType: 'user',
        isRead: true,
        createdAt: DateTime.utc(2026, 6, 23),
      );

      final entity = model.toEntity();

      expect(entity.notificationContent.title, 'Hello');
      expect(entity.isRead, isTrue);
    });
  });
}
