part of elastic_dart;

final _responseDecoder = const Utf8Decoder().fuse(const JsonDecoder());

class ElasticRequest {
  final String host;
  final http.Client client;

  ElasticRequest(this.host, {http.Client client})
    : this.client = (client == null) ? clientFactory() : client;

  Future get(String path) => _request('GET', path);
  Future post(String path, body) => _request('POST', path, body);
  Future put(String path, body) => _request('PUT', path, body);
  Future delete(String path) => _request('DELETE', path);

  Future _request(String method, String path, [body]) async {
    var request = new http.Request(method, Uri.parse('$host/$path'));
    if (body != null) {
      if (body is! String) {
        body = JSON.encode(body);
      }
      request.body = body;
    }

    var response = await client.send(request);
    var responseBody = _responseDecoder.convert(await response.stream.toBytes());

    if (response.statusCode >= 400) {
      var error = responseBody['error'];
      if ((error is String && error.startsWith('IndexMissingException'))
          || (error is Map && error['type'] == 'index_missing_exception')
          || (error is Map && error['type'] == 'index_not_found_exception')) {
        throw new IndexMissingException(responseBody);
      }
      throw new ElasticsearchException(responseBody);
    }

    return responseBody;
  }
}
