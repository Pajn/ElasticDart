import 'dart:async';
import 'package:unittest/unittest.dart' show unittestConfiguration;

import 'helpers/testdata.dart';
import 'specs/elasticsearch.dart' as elasticsearch;
import 'specs/warehouse/warehouse.dart' as warehouse;
import 'package:elastic_dart/elastic_dart.dart';
import 'specs/index.dart' as index;

main() async {
  await setUpTestData();
  // Wait for elastic to index the new documents
  await new Future.delayed(new Duration(seconds: 2));

  unittestConfiguration.timeout = const Duration(seconds: 5);

  elasticsearch.main(new Elasticsearch());
  index.main();
  warehouse.main();
}
