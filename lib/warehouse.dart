library elastic_dart.warehouse;

import 'dart:async';
import 'package:elastic_dart/elastic_dart.dart';
import 'package:warehouse/adapters/base.dart';
import 'package:warehouse/warehouse.dart';

import 'src/warehouse/mirrors.dart';

export 'package:elastic_dart/elastic_dart.dart';

part 'src/warehouse/elasticsearch_companion.dart';
part 'src/warehouse/elasticsearch_mixin.dart';
part 'src/warehouse/query_response.dart';

typedef Map<String, dynamic> SearchSerializer(entity);

/// Configures and creates an ElasticsearchCompanion
///
/// [db] is the [Elasticsearch] endpoint that will be searched against
/// [indexDefinitions] is a [Map] that configures the indexes and how the entities should be
/// serialized for search, it can be in the formats:
///
/// - Single type per index with derived index name
///   {`Movie: (movie) => {'title': movie.title}`}
/// - Single type per index with custom index name
///   {`'movies': {Movie: (movie) => {'title': movie.title}}`}
/// - Multiple types per index with derived index name and same serialization
///   `[Movie, Actor]: fullDocument` (using the provided [fullDocument] serializer)
/// - Multiple types per index with derived index name
///   ```dart
///   {[Movie, Actor]: {
///     Movie: (movie) => {'title': movie.title},
///     Cinema: (cinema) => {'name': cinema.name, 'location': cinema.location},
///   }}
///   ```
/// - Multiple types per index with custom index name
///   ```dart
///   {'movies': {
///     Movie: (movie) => {'title': movie.title},
///     Cinema: (cinema) => {'name': cinema.name, 'location': cinema.location},
///   }}
///   ```
Companion elasticsearchCompanion(Elasticsearch db, Map indexDefinitions,
    {Duration bulkTime: const Duration(milliseconds: 250)}) {
  var companion = new _ElasticsearchCompanion(db, bulkTime);
  companion.setUpMappings(indexDefinitions);
  return companion.setSession;
}

/// Serializes the complete and all referenced objects
SearchSerializer fullDocument() =>
    (entity) => lookingGlass.serializeDocument(entity);

class _Index {
  String name;
  Map<Type, SearchSerializer> converters;
}
