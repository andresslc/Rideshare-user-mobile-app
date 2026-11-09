import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/data/datasources/saved_locations_remote_data_source.dart';
import 'package:ride_app/features/settings/data/models/saved_location_model.dart';
import 'package:ride_app/features/settings/data/repositories/saved_locations_repository_impl.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class _MockSavedLocationsRemoteDataSource extends Mock
    implements SavedLocationsRemoteDataSource {}

void main() {
  late SavedLocationsRemoteDataSource dataSource;
  late SavedLocationsRepositoryImpl repository;

  const model = SavedLocationModel(
    id: 'loc-1',
    name: 'Home',
    address: '123 Main Street',
    city: 'Austin',
    state: 'TX',
    country: 'USA',
    lat: 30.2672,
    lng: -97.7431,
    order: 1,
    isDeleted: false,
  );

  setUp(() {
    dataSource = _MockSavedLocationsRemoteDataSource();
    repository = SavedLocationsRepositoryImpl(dataSource);
  });

  test('maps saved location models to entities', () async {
    when(
      () => dataSource.getSavedLocations(page: 1, limit: 50),
    ).thenAnswer((_) async => const Right(([model], null)));

    final result = await repository.getSavedLocations();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected success'), (value) {
      final (locations, _) = value;
      expect(locations.single.name, 'Home');
      expect(locations.single.formattedAddress, '123 Main Street');
    });
  });

  test('maps saveLocation model to entity', () async {
    final params = SaveLocationParams(
      name: 'Home',
      address: '123 Main Street',
      country: 'USA',
      city: 'Austin',
      state: 'TX',
      lat: 30.2672,
      lng: -97.7431,
    );

    when(() => dataSource.saveLocation(params)).thenAnswer(
      (_) async => const Right(model),
    );

    final result = await repository.saveLocation(params);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected success'), (location) {
      expect(location.id, 'loc-1');
    });
  });

  test('forwards deleteLocation success', () async {
    final response = ApiResponse(success: true, message: 'deleted');
    when(() => dataSource.deleteLocation('loc-1')).thenAnswer(
      (_) async => Right(response),
    );

    final result = await repository.deleteLocation('loc-1');

    expect(result.isRight(), isTrue);
  });

  test('returns failure when datasource fails', () async {
    when(
      () => dataSource.getSavedLocations(page: 1, limit: 50),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'network error')),
    );

    final result = await repository.getSavedLocations();

    expect(result.isLeft(), isTrue);
  });
}
