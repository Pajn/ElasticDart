part of elastic_dart.warehouse;

class QueryResponse {
  final String index;
  final Map query;

  final int took;
  final bool timedOut;
  final int shardsTotal;
  final int shardsSuccessful;
  final int shardsFailed;

  final int totalHits;
  final num maxScore;
  final List<Map> hits;

  final int skip;
  final int limit;

  final Elasticsearch _es;

  bool get hasNextPage => skip >= totalHits;
  Iterable get hitIds => hits.map((hit) => hit['_id']);

  QueryResponse(this._es, this.index, this.query, Map response, this.skip, this.limit)
    : took = response['took'],
      timedOut = response['timed_out'],
      shardsTotal = response['_shards']['total'],
      shardsSuccessful = response['_shards']['successful'],
      shardsFailed = response['_shards']['failed'],
      totalHits = response['hits']['total'],
      maxScore = response['hits']['max_score'],
      hits = response['hits']['hits'];

  static Future<QueryResponse> search(
      Elasticsearch es,
      String index,
      Map query,
      int skip,
      int limit
  ) async {
    var response = await es.search(query: query..addAll({
      'from': skip,
      'size': limit,
    }), index: index);

    return new QueryResponse(es, index, query, response, skip, limit);
  }

  Future<QueryResponse> nextPage() async {
    if (!hasNextPage) throw new StateError('Already on last page');

    return search(_es, index, query, skip + limit, limit);
  }
}
