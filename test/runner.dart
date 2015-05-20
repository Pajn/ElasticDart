import 'dart:async';
import 'package:unittest/unittest.dart' show unittestConfiguration;

import 'helpers/testdata.dart';
import 'specs/elasticsearch.dart' as elasticsearch;
import 'specs/warehouse/warehouse.dart' as warehouse;

main() async {
  await setUpTestData();
  // Wait for elastic to index the new documents
  await new Future.delayed(new Duration(seconds: 2));

  unittestConfiguration.timeout = const Duration(seconds: 5);

  elasticsearch.main();
  warehouse.main();
}
