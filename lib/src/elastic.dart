part of elasti_dart;

class ElasticSearch {
  final String host;

  ElasticSearch([this.host = 'http://127.0.0.1:9200']);

  Index getIndex(String index) {
    return new Index(this, index);
  }

  Future createIndex(String name, [Map settings = const {}]) {
    return this.put(name, settings);
  }

  Future deleteIndex(String name) {
    return this.delete(name);
  }

  Future<Map<String, dynamic>> search([Map<String, dynamic> query = const {}]) {
    var body = JSON.encode(query);
    return this.post('_search', body);
  }

  Future bulk(List<Map> mapList) {
    // Elasticsearch needs maps to be on new lines. Last line needs
    // to be a newline as well.
    var body = mapList.map(JSON.encode).join('\n') + '\n';

    return this.post('$host/_bulk', body);
  }

  Future post(String path, body) async {
    var response = await http.post('$host/$path', body: body);

    body = UTF8.decode(response.bodyBytes);
    response = JSON.decode(body);

    if (response.containsKey('error')) {
      throw response;
    }

    return response;
  }

  Future put(String path, body) async {
    var response = await http.put('$host/$path', body: body);

    body = UTF8.decode(response.bodyBytes);
    response = JSON.decode(body);

    if (response.containsKey('error')) {
      throw response;
    }

    return response;
  }

  Future get(String path) async {
    var response = await http.get('$host/$path');

    response = JSON.decode(response.body);

    if (response.containsKey('error')) {
      throw response;
    }
    return response;
  }

  Future delete(String path) async {
    var response = await http.delete('$host/$path');

    response = JSON.decode(response.body);

    if (response.containsKey('error')) {
      throw response;
    }
    return response;
  }
}

class Index {
  final String name;
  final ElasticSearch es;

  Index(this.es, this.name);

  Future<Map<String, dynamic>> search([Map<String, dynamic> query = const {}]) {
    var body = JSON.encode(query);
    var data = this.es.post('$name/_search/', body);
    return data;
  }

  Future putMapping(Map mapping) {
    return this.es.put('$name/_mapping/', mapping);
  }

  Future getMapping() {
    return this.es.get('$name/_mapping/');
  }

}