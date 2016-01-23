part of elastic_dart.warehouse;

class ElasticRepository<T> extends RepositoryBase<T> {
  final String index;
  final ElasticSession session;

  ElasticRepository(ElasticSession session, {String index})
      : this.index = index ?? findLabel(T).toLowerCase(),
        this.session = session,
        super(session);

  ElasticRepository.withType(ElasticSession session, Type type, {String index})
      : this.index = index ?? findLabel(type).toLowerCase(),
        this.session = session,
        super(session, types: [type]);

  @override
  Future<int> countAll({Map where, List<Type> types}) async {
    final response = await session.db.count(
        index: index,
        query: createQuery(session.lookingGlass, where)
    );

    return response['count'];
  }

  @override
  Future deleteAll({Map where}) async {
    // TODO: implement deleteAll
    if (where == null || where.isNotEmpty) {
      try {
        await session.db.deleteIndex('$index');
      } on IndexMissingException {}
    }
  }

  @override
  Future<List<T>> findAll({
      Map where,
      int skip: 0,
      int limit: 10,
      String sort,
      List<Type> types
  }) async {
    final query = createQuery(session.lookingGlass, where);

    if (skip != 0) {
      query['from'] = skip;
    }

    if (limit != 10) {
      query['size'] = limit;
    }

    if (sort != null) {
      query['sort'] = [sort];
    }

//    print(query);
    try {
      final response = await session.db.search(
          index: index,
          query: query
      );

//      print(response);
  //
      // print('\n\n\n');

      return response['hits']['hits'].map(_instantiate).toList();
    } on IndexMissingException {
      return [];
    }
  }

  @override
  Future<T> get(id) async {
    try {
      final document = await session.db.get(index, '_all', id);

      if (!document['found']) return null;

      return _instantiate(document);
    } on IndexMissingException {}
  }

  @override
  Future<List<T>> getAll(Iterable ids) async {
    try {
      final response = await session.db.multiGet(
          index: index,
          type: '_all',
          query: {
            'ids': ids.toList()
          }
      );

      return response['docs'].map(_instantiate).toList();
    } on IndexMissingException {
      return [];
    }
  }

  _instantiate(Map document) {
    final entity = session.lookingGlass.deserializeDocument(document['_source']);
    session.lookingGlass.setId(entity, document['_id']);
    session.attach(entity, document['_id']);

    return entity;
  }
}
