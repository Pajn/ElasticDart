part of elastic_dart;

/// A wrapper around the Elasticsearch REST API.
class Elasticsearch {
  final transport;

  Index get all => new Index('_all', this);

  Elasticsearch([String host = 'http://127.0.0.1:9200', http.Client client])
      : transport = new ElasticRequest(host, client: client);

  Index index(String name) => new Index(name, this);

  /// Creates an index with the given [name] with optional [features].
  ///
  /// Examples:
  /// ```dart
  ///   // Creates an index called "movie-index" without any features.
  ///   await elasticsearch.createIndex('movie-index');
  ///
  ///   // Creates an index called "movie-index" with 3 shards, each with 2 replicas.
  ///   await elasticsearch.createIndex('movie-index', features: {
  ///     "settings" : {
  ///       "number_of_shards" : 3,
  ///       "number_of_replicas" : 2
  ///       }
  ///    });
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/indices-create-index.html)
  Future<Index> createIndex(String name,
      {Map features: const {}, bool throwIfExists: true}) async {
    try {
      return await transport.put(name, features);
    } on ElasticsearchException catch (e) {
      if (e.message.startsWith('IndexAlreadyExistsException')) {
        if (throwIfExists) throw new IndexAlreadyExistsException(
            name, e.response);
        return new Index(name, this);
      }
      rethrow;
    }
  }

  /// Perform many index, delete, create, or update operations in a single call.
  ///
  /// Examples:
  /// ```dart
  /// await es.bulk([
  ///   {"index": {"_index": "movie-index", "_type": "movies", "_id": "1"} },
  ///   {"name": "Fury", "year": "2014" }
  /// ]);
  ///
  /// await es.bulk([
  ///   {"delete": {"_index": "movie-index", "_type": "movies", "_id": "2"} },
  /// ]);
  ///
  /// await es.bulk([
  ///   {"create": {"_index": "movie-index", "_type": "movies", "_id": "3"} },
  ///   {"name": "Fury", "year": "2014" }
  /// ]);
  ///
  /// await es.bulk([
  ///   {"index": {"_index": "movie-index", "_type": "movies", "_id": "1"} },
  ///   {"name": "Fury", "year": "2014" },
  ///   {"index": {"_index": "movie-index", "_type": "movies", "_id": "2"} },
  ///   {"name": "Titanic", "year": "1997" },
  ///   {"index": {"_index": "movie-index", "_type": "movies", "_id": "3"} },
  ///   {"name": "Annabelle", "year": "2014" }
  /// ]);
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/docs-bulk.html)
  Future bulk(List<Map> mapList, {String index: '_all', String type: ''}) {
    // Elasticsearch needs maps to be on new lines. Last line needs
    // to be a newline as well.
    var body = mapList.map(JSON.encode).join('\n') + '\n';
    return transport.post('$index/$type/_bulk', body);
  }
}
