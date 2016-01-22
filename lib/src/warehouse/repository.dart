part of elastic_dart.warehouse;

class ElasticsearchRepository<T> extends RepositoryBase<T> {
  final String index;
  final String type;
  final ElasticsearchDbSession session;

  ElasticsearchRepository(ElasticsearchDbSession session, {String index})
      : type = findLabel(T),
        this.index = index ?? session.index ?? findLabel(T),
        this.session = session,
        super(session);

  @override
  Future<int> countAll({Map where, List<Type> types}) async {
    final response = await session.db.count(
        index: index,
        type: type,
        query: createQuery(where, type)
    );

    return response['count'];
  }

  @override
  Future deleteAll({Map where}) {
    // TODO: implement deleteAll
  }

  @override
  Future<List<T>> findAll({
      Map where,
      int skip: 0,
      int limit: 10,
      String sort,
      List<Type> types
  }) async {
    final query = createQuery(where, type);

    if (skip != 0) {
      query['from'] = skip;
    }

    if (limit != 10) {
      query['size'] = limit;
    }

    if (sort != null) {
      query['sort'] = [sort];
    }

    final response = await session.db.search(
        index: index,
        type: type,
        query: query
    );

    return response['hits'].map(_instantiate).toList();
  }

  @override
  Future<T> get(id) async {
    final document = await session.db.get(index, type, id);

    if (!document['found']) return null;

    return _instantiate(document);
  }

  @override
  Future<List<T>> getAll(Iterable ids) async {
    final response = await session.db.search(
        index: index,
        type: type,
        query: {
          'ids' : {
            'type' : type,
            'values' : ids.toList(),
          }
        }
    );

    return response['hits'].map(_instantiate).toList();
  }

  _instantiate(Map document) {
    final entity = session.lookingGlass.deserializeDocument(document['_source']);
    session.lookingGlass.setId(entity, document['_id']);
    session.attach(entity, document['_id']);

    return entity;
  }
}
