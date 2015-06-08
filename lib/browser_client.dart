/// A warpper around the Elasticsearch REST API for indexing and querying
///
/// For use on the client / in the browser
library elastic_dart.client;

import 'package:http/browser_client.dart';
import 'package:elastic_dart/elastic_dart.dart' as vm;

export 'package:elastic_dart/elastic_dart.dart' hide Elasticsearch;

class Elasticsearch extends vm.Elasticsearch {
  Elasticsearch([String host = 'http://127.0.0.1:9200'])
    : super(host, new BrowserClient());
}
