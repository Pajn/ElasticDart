part of elastic_dart.warehouse;

class ElasticsearchDbSession extends DbSessionBase<Elasticsearch> {
  final String index;

  @override
  final Elasticsearch db;

  @override
  final LookingGlass lookingGlass = new LookingGlass();

  ElasticsearchDbSession(this.db, {this.index});

  @override
  writeQueue() async {
    final operations = queue.expand((operation) {
      final type = findLabel(operation.entity.runtimeType);
      final index = this.index ?? type;

      switch (operation.type) {
        case OperationType.create:
          return [
            {'create': {'_index': index, 'type': type}},
            lookingGlass.serializeDocument(operation.entity),
          ];

        case OperationType.update:
          return [
            {'index': {'_id': operation.id, '_index': index, 'type': type}},
            lookingGlass.serializeDocument(operation.entity),
          ];

        case OperationType.delete:
          return [
            {'delete': {'_id': operation.id, '_index': index, 'type': type}},
          ];
      }
    });

    final response = await db.bulk(operations);
    final items = response['items'];

    for (var i = 0; i < items.length; i++) {
      if (operations[i].type == OperationType.create) {
        operations[i].id = items[i]['create']['_id'];
      }
    }
  }
}
