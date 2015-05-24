/// A warpper around the Elasticsearch REST API for indexing and querying
library elastic_dart;

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

part 'src/elastic_request.dart';
part 'src/elasticsearch.dart';
part 'src/exceptions.dart';
