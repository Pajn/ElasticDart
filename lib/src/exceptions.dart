part of elastic_dart;

final _indexMissing = new RegExp(r'IndexMissingException\[\[(\w+)\] missing\]');

class ElasticSearchException implements Exception {
  final String message;
  final int status;
  final Map response;

  ElasticSearchException(Map response, [String message]) :
    this.message = (message == null) ? response['error'] : message,
    this.status = response['status'],
    this.response = response;
}

class IndexAlreadyExistsException extends ElasticSearchException {
  final String index;

  IndexAlreadyExistsException(String index, Map response) :
    this.index = index,
    super(response, 'Index [$index] already exists');
}

class IndexMissingException extends ElasticSearchException {
  final String index;

  IndexMissingException(Map response) :
    this.index = _indexMissing.firstMatch(response['error']).group(1),
    super(response, 'Index [${_indexMissing.firstMatch(response['error']).group(1)}] does not exist');
}
