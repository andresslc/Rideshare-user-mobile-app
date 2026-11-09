import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/features/settings/data/models/saved_location_model.dart';

void main() {
  group('SavedLocationModel.listFromResponse', () {
    test('parses dev API list payload', () {
      final (locations, pagination) = SavedLocationModel.listFromResponse({
        'success': true,
        'message': 'Operation Successfully',
        'data': {
          'locations': [
            {
              '_id': '6a3a717445b09fe97f1a34ba',
              'name': 'test',
              'address': '800 N Magnolia Ave, Orlando, FL 32803, USA',
              'city': 'Orlando',
              'state': 'Florida',
              'country': 'USA',
              'coordinates': {
                'type': 'Point',
                'coordinates': [-81.379234, 28.538335],
              },
              'isDeleted': false,
              'order': 2,
            },
            {
              '_id': '6a3a71b545b09fe97f1a3513',
              'name': 'test test',
              'address': '700 S Rosemary Ave, West Palm Beach, FL 33401, USA',
              'city': 'West Palm Beach',
              'state': 'Florida',
              'country': 'USA',
              'coordinates': {
                'type': 'Point',
                'coordinates': [-80.058324, 26.709723],
              },
              'isDeleted': false,
              'order': 1,
            },
          ],
        },
        'pagination': {
          'page': 50,
          'currentPage': 1,
          'total': 2,
          'totalPages': 1,
        },
      });

      expect(locations.map((item) => item.id).toList(), [
        '6a3a71b545b09fe97f1a3513',
        '6a3a717445b09fe97f1a34ba',
      ]);
      expect(locations.first.lat, closeTo(26.709723, 0.0001));
      expect(locations.first.lng, closeTo(-80.058324, 0.0001));
      expect(pagination?.currentPage, 1);
      expect(pagination?.itemsPerPage, 50);
      expect(pagination?.totalItems, 2);
      expect(pagination?.totalPages, 1);
    });

    test('excludes soft-deleted rows', () {
      final (locations, _) = SavedLocationModel.listFromResponse({
        'success': true,
        'data': {
          'locations': [
            {
              '_id': 'deleted',
              'name': 'Old',
              'address': '1',
              'city': 'Orlando',
              'state': 'Florida',
              'country': 'USA',
              'coordinates': {'coordinates': [-81.3, 28.5]},
              'isDeleted': true,
              'order': 1,
            },
            {
              '_id': 'active',
              'name': 'Home',
              'address': '2',
              'city': 'Orlando',
              'state': 'Florida',
              'country': 'USA',
              'coordinates': {'coordinates': [-81.4, 28.6]},
              'isDeleted': false,
              'order': 2,
            },
          ],
        },
      });

      expect(locations.single.id, 'active');
    });
  });

  group('SavedLocationModel.mutationFromResponse', () {
    test('reads nested data.location', () {
      final location = SavedLocationModel.mutationFromResponse({
        'success': true,
        'data': {
          'location': {
            '_id': '6a3a717445b09fe97f1a34ba',
            'name': 'test',
            'address': '800 N Magnolia Ave, Orlando, FL 32803, USA',
            'city': 'Orlando',
            'state': 'Florida',
            'country': 'USA',
            'coordinates': {
              'type': 'Point',
              'coordinates': [-81.379234, 28.538335],
            },
            'isDeleted': false,
            'order': 1,
          },
        },
      });

      expect(location.id, '6a3a717445b09fe97f1a34ba');
    });

    test('reads flat location document in data', () {
      final location = SavedLocationModel.mutationFromResponse({
        'success': true,
        'data': {
          '_id': '6a3a717445b09fe97f1a34ba',
          'name': 'test',
          'address': '800 N Magnolia Ave, Orlando, FL 32803, USA',
          'city': 'Orlando',
          'state': 'Florida',
          'country': 'USA',
          'coordinates': {
            'type': 'Point',
            'coordinates': [-81.379234, 28.538335],
          },
          'isDeleted': false,
          'order': 1,
        },
      });

      expect(location.name, 'test');
    });
  });
}
