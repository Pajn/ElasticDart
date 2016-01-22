part of elastic_dart.warehouse;

class ElasticSession extends DbSessionBase<Elasticsearch> {
  final Map<Type, String> indices;

  @override
  final Elasticsearch db;

  @override
  final LookingGlass lookingGlass = new LookingGlass();

  @override
  final supportsListsAsProperty = false;

  ElasticSession(this.db, {this.indices});

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
