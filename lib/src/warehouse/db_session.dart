part of elastic_dart.warehouse;

class ElasticDbSession extends DbSessionBase<Elasticsearch> {
  final Map<Type, String> indices;

  @override
  final Elasticsearch db;

  @override
  final LookingGlass lookingGlass = new LookingGlass();

  @override
  final supportsListsAsProperty = false;

  ElasticDbSession(this.db, {this.indices: const {}});

  Future mapTypes(List<Type> types) async {
    for (final type in types) {
      final mapping = findMapping(type);
      if (mapping.isEmpty) continue;

      await mapType(type, mapping);
    }
  }

  Future mapType(Type type, [Map mapping]) async {
    final label = findLabel(type);
    final index = indices[type] ?? label.toLowerCase();

    await db.putMapping(
        {label: {'properties': mapping}},
        index: index,
        type: label
    );
  }

  @override
  writeQueue() async {
    final operations = queue.expand((operation) {
      final type = findLabel(operation.entity.runtimeType);
      final index = indices[operation.entity.runtimeType] ?? type.toLowerCase();

      switch (operation.type) {
        case OperationType.create:
          return [
            {'create': {'_index': index, '_type': type}},
            lookingGlass.serializeDocument(operation.entity),
          ];

        case OperationType.update:
          return [
            {'index': {'_id': operation.id, '_index': index, '_type': type}},
            lookingGlass.serializeDocument(operation.entity),
          ];

        case OperationType.delete:
          return [
            {'delete': {'_id': operation.id, '_index': index, '_type': type}},
          ];
      }
    });

    if (operations.isEmpty) return;

    final response = await db.bulk(operations, refresh: true);
    final items = response['items'];

    for (var i = 0; i < items.length; i++) {
      if (queue[i].type == OperationType.create) {
        queue[i].id = items[i]['create']['_id'];
      }
    }
  }
}
