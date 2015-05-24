/// Example on how to use Warehouse for storing and querying, here
/// mock implementations is used but they should be interchangeable to any
/// adapter.
library elastic_dart.example.warehouse_companion;

import 'dart:async';
import 'package:elastic_dart/warehouse.dart';
import 'package:warehouse/mocks.dart';
import 'package:warehouse/warehouse.dart';
import 'domain.dart';

main() async {
  /// Instantiate a Db instance.
  var es = new Elasticsearch();
  /// Instantiate a DbSession.
  var session = new MockSession();
  /// Instantiate you repositories
  var movieRepository = new MovieRepository(session);
  var cinemaRepository = new CinemaRepository(session);
  /// Register you searchable entities
  await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
    Cinema: (Cinema cinema) => {
      'location': {
        'lat': cinema.location.latitude,
        'lon': cinema.location.longitude,
      }
    },
    Movie: fullDocument()
  }));

  /// Store entities to create and index them
  session.store(
      new Movie()
        ..title = 'The Hobbit: An Unexpected Journey'
  );
  session.store(
      new Movie()
        ..title = 'Kill Bill - Vol. 1'
  );
  session.store(
      new Cinema()
        ..name = 'Real Movies'
        ..location = new GeoPoint(14, 37)
  );
  session.store(
      new Cinema()
        ..name = 'The Cinema'
        ..location = new GeoPoint(10, 50)
  );

  /// store only queues the changes, persist them with saveChanges
  await session.saveChanges();
  /// wait for the changes to be persisted
  await new Future.delayed(new Duration(seconds: 2));

  /// Search for the data
  var movieResults = await movieRepository.search('An');
  /// Search for the data
  var cinemaResults = await cinemaRepository.near(new GeoPoint(11, 48));

  print(movieResults.map((movie) => movie.title));
  print(cinemaResults.map((cinema) => cinema.name));
}
