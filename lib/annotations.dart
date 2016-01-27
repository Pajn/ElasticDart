library ElastiDart.annotations;

class Mapping {
  final Map<String, dynamic> mapping;

  const Mapping(this.mapping);
}

class MultiField {
  final Map<String, Map<String, String>> extraFields;

  const MultiField(this.extraFields);
}

const notAnalyzed = const Mapping(const {
  'type': 'string',
  'index': 'not_analyzed',
});

const sortable = const MultiField(const {
  'raw': const {
    'type': 'string',
    'index': 'not_analyzed',
  },
});
