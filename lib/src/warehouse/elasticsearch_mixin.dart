part of elastic_dart.warehouse;

/// Should be mixed in with a [Repository] to provide search functionality
abstract class ElasticsearchMixin {
  DbSession get session;
  List<Type> get types;

  /// The [Elasticsearch] endpoint it works with
  Elasticsearch get elasticsearch => session.companions[Elasticsearch];
  /// The index it searches, should be overridden if a custom index name is used
  String get esIndexName => types.map(findLabel).join('&').toLowerCase();

  /// Searches the corresponding index.
  ///
  /// For more information see:
  ///   [Elasticsearch documentation](http://elastic.co/guide/en/elasticsearch/reference/1.5/search-search.html)
  Future<QueryResponse> esQuery(Map query, {int skip: 0, int limit: 10}) =>
      QueryResponse.search(elasticsearch, esIndexName, query, skip, limit);
}
