part of elastic_dart;

class Index {
  final String name;
  final Elasticsearch es;

  Index(this.name, this.es);

  /// Retrieve information about one or more indices
  /// The available features are _settings, _mappings, _warmers and _aliases.
  ///
  /// Examples:
  /// ```dart
  ///   // Gets the movie index.
  ///   await es.index('movie-index').get();
  ///
  ///   // Gets all the indices.
  ///   await es.all.get();
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/indices-get-index.html)
  Future get({List<String> features: const []}) =>
      es.transport.get('$name/${features.join(',')}');

  /// Deletes an index by [name] or all indices if _all is passed.
  ///
  /// Examples:
  /// ```dart
  ///   // Deletes the movie index.
  ///   await es.index('movie-index').delete();
  ///
  ///   // Deletes all the indices. Be careful with this!
  ///   await es.all.delete();
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/indices-delete-index.html)
  Future delete() => es.transport.delete(name);

  /// Open a closed index to make it available for search
  ///
  /// Example:
  /// ```dart
  ///   // Open the movie index.
  ///   await es.index('movie-index').open();
  ///
  ///   // Open all the indices.
  ///   await es.all.open();
  /// ```
  Future open() => es.transport.post('$name/_open', '');

  /// Close an index to remove it's overhead from the cluster. Closed index
  /// is blocked for read/write operations.
  ///
  /// Example:
  /// ```dart
  ///   // Close the index.
  ///   await es.index('movie-index').close();
  ///
  ///   // Close all the indices.
  ///   await es.all.close();
  /// ```
  Future close() => es.transport.post('$name/_close', '');

  /// Searches the given [index] or all indices if _all is passed.
  ///
  /// Examples:
  /// ```dart
  ///   // Will search all indices and matches everything.
  ///   await es.all.search();
  ///
  ///   // Search the movie index that matches everything.
  ///   await es.index('movie-index').search();
  ///
  ///   // Search the movies index that matches the name with Fury.
  ///   await es.index('movie-index').search(query: {
  ///     "query": {
  ///       "match": {"name": "Fury"}
  ///     }
  ///   });
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/search-search.html)
  Future<Map<String, dynamic>> search({Map<String, dynamic> query: const {}}) =>
      es.transport.post('$name/_search', query);

  /// Retrieve mapping definitions for an [index] or index/type.
  /// Gets all the mappings if _all is passed.
  ///
  /// Examples:
  /// ```dart
  ///   // Get all the mappings on the specific index.
  ///   await es.index('movie-index').getMapping();
  ///
  ///   // Get mapping on the index and the specific type.
  ///   await es.index('movie-index').getMapping(type: 'movie-type');
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/indices-get-mapping.html)
  Future getMapping({String type: ''}) =>
      es.transport.get('$name/_mapping/$type');

  /// Register specific [mapping] definition for a specific [type].
  ///
  /// Examples:
  /// ```dart
  ///   await es.index('movie-index').putMapping(
  ///     {"test-type": {"properties": {"message": {"type": "string", "store": "yes"}}}},
  ///     type: 'movie-type'
  ///   );
  /// ```
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/indices-put-mapping.html)
  Future putMapping(Map<String, dynamic> mapping, {String type: ''}) =>
      es.transport.put('$name/_mapping/$type', mapping);
}
