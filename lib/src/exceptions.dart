part of elastic_dart;

final _indexMissing = new RegExp(r'IndexMissingException\[\[([^\]]+)\] missing\]');
String _missingIndex(error) {
  if (error is String) {
    return _indexMissing.firstMatch(error).group(1);
  } else if (error is Map) {
    return error['index'];
  } else {
    return 'Unknown Index';
  }
}

String _errorMessage(responseError) {
  if (responseError is String) return responseError;
  else if (responseError is Map) return responseError['reason'];
  else return null;
}


class ElasticsearchException implements Exception {
  final String message;
  final int status;
  final Map response;

  ElasticsearchException(Map response, [String message]) :
    this.message = (message == null)
        ? _errorMessage(response['error']) : message,
    this.status = response['status'],
    this.response = response;

  String toString() => message;
}

class IndexAlreadyExistsException extends ElasticsearchException {
  final String index;

  IndexAlreadyExistsException(String index, Map response) :
    this.index = index,
    super(response, 'Index [$index] already exists');
}

class IndexMissingException extends ElasticsearchException {
  final String index;

  IndexMissingException(Map response) :
    this.index = _missingIndex(response['error']),
    super(response, 'Index [${_missingIndex(response['error'])}] does not exist');
}
