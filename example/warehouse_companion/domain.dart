library elastic_dart.example.warehouse_companion.domain;

import 'dart:async';
import 'package:elastic_dart/warehouse.dart';
import 'package:warehouse/mocks.dart';
import 'package:warehouse/warehouse.dart';

class Movie {
  String title;
}

class Cinema {
  String name;
  GeoPoint location;
}

class CinemaRepository extends MockRepository<Cinema> with ElasticsearchMixin {
  CinemaRepository(DbSession session) : super(session);

  Future<List<Cinema>> near(GeoPoint location) async {
    QueryResponse response = await esQuery({
      "query": {
        "function_score": {
          "functions": [{
            "gauss": {
              "location": {
                "origin": {
                  "lat": location.latitude,
                  "lon": location.longitude
                },
                "offset": "5km",
                "scale": "30km"
              }
            }
          }],
        }
      }
    });
    return getAll(response.hitIds);
  }
}

class MovieRepository extends MockRepository<Movie> with ElasticsearchMixin {
  MovieRepository(DbSession session) : super(session);

  Future<List<Movie>> search(String query) async {
    QueryResponse response = await esQuery({
      "query": {
        "match": {
          "title": query
        }
      }
    });
    return getAll(response.hitIds);
  }
}
