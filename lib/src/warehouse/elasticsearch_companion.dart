part of elastic_dart.warehouse;

class _ElasticsearchCompanion {
  final Elasticsearch db;
  final List<_Index> indexes = [];
  final List<Future> _allMappings = [];
  final StreamController bulkOperations = new StreamController();
  final Duration bulkTime;
  DbSession session;

  _ElasticsearchCompanion(this.db, this.bulkTime) {
    var bulk = [];
    bulkOperations.stream
      .timeout(bulkTime, onTimeout: (_) {
        if (bulk.isNotEmpty) {
          db.bulk(bulk);
          bulk.clear();
        }
      })
      .listen(bulk.add);
  }

  setSession(DbSession session) {
    if (this.session != null) throw new StateError('Can only set the session once');
    this.session = session;

    for (var index in indexes) {
      Stream<DbOperation> indexOperations = session.onOperation
        .where((op) => isAny(op.entity, index.converters.keys));

      indexOperations
        .where((op) => op.type == OperationType.create || op.type == OperationType.update)
        .listen((op) {
          var type = index.converters.keys.firstWhere((type) => isSubtype(op.entity, type));
          var converter = index.converters[type];
          bulkOperations.add({'index': {'_index': index.name, '_type': findLabel(type), '_id': op.id}});
          bulkOperations.add(converter(op.entity));
        });

      indexOperations
        .where((op) => op.type == OperationType.delete)
        .listen((op) {
          var type = index.converters.keys.firstWhere((type) => isSubtype(op.entity, type));
          bulkOperations.add({'delete': {'_index': index.name, '_type': findLabel(type), '_id': op.id}});
        });
    }

    return db;
  }

  setUpMappings(Map indexDefinitions) {
    indexDefinitions.forEach((index, converters) {
      var indexDefinition = new _Index();
      if (index is Type) {
        indexDefinition.name = findLabel(index).toLowerCase();
        if (converters is Map) {
          indexDefinition.converters = converters;
        } else {
          indexDefinition.converters = {index: converters};
        }
      } else if (index is List<Type>) {
        indexDefinition.name = index.map(findLabel).join('&').toLowerCase();
        if (converters is Map) {
          indexDefinition.converters = converters;
        } else {
          indexDefinition.converters = {};
          index.forEach((index) => indexDefinition.converters[index] = converters);
        }
      } else if (index is String) {
        indexDefinition.name = index;
        indexDefinition.converters = converters;
      } else {
        throw 'The key in indexDefinitions must either be a String, Type or List<Type>';
      }

      indexes.add(indexDefinition);

      _allMappings.add(() async {
        await db.createIndex(indexDefinition.name, throwIfExists: false);

        await new Stream.fromIterable(indexDefinition.converters.keys)
          .asyncMap((type) async {
            var mapping = findMapping(type);
            if (mapping.isEmpty) return;
            var label = findLabel(type);

            await db.putMapping(
                {label: {'properties': mapping}},
                index: indexDefinition.name,
                type: label
            );
          })
          .last;
      }());
    });
  }
}
