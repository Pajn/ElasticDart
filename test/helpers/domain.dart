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

class GenericRepository extends MockRepository with ElasticsearchMixin {
  GenericRepository(DbSession session, List<Type> types) : super.withTypes(session, types);

  Future<List> search(String query) async {
    QueryResponse response = await esQuery({"query": {"match": {"_all": query}}});
    return getAll(response.hitIds);
  }
}

class CinemaRepository extends GenericRepository {
  CinemaRepository(DbSession session) : super(session, const [Cinema]);

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
    QueryResponse response = await esQuery({"query": {"match": {"title": query}}});
    return getAll(response.hitIds);
  }
}

class CustomGenericIndex extends GenericRepository {
  @override
  final esIndexName = 'movies';

  CustomGenericIndex(DbSession session, List<Type> types) : super(session, types);
}

class CustomMovieIndex extends MovieRepository {
  @override
  final esIndexName = 'movies';

  CustomMovieIndex(DbSession session) : super(session);
}
